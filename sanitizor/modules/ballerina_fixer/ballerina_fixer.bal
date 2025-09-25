import sanitizor.command_executor;
import ballerina/os;
import ballerina/io;
import ballerina/ai;
import ballerina/file;
import ballerina/lang.regexp;
import ballerina/log;
import ballerinax/ai.anthropic;


configurable string apiKey = ?;
configurable int maxIterations = ?;

const int MAX_CODE_LENGTH = 1000;


public type BallerinaFixResult record {|
    boolean success;
    int errorsFixed;
    int errorsRemaining;
    string[] appliedFixes;
    string[] remainingFixes;
|};

type CompilationError record {|
    string filePath;
    int line;
    int column;
    string message;
    string severity;
    string code?;
|};

type FixResponse record {|
    string fixedCode;
    string explanation;
    string confidence;
|};

public type BallerinaFixerError error;

function applyPatch(string filePath, string diffContent, CompilationError[] originalErrors, string projectPath) returns boolean|error {
    string fileName = extractFileName(filePath);
    string patchFile = check file:joinPath(projectPath, fileName + ".patch");
    check io:fileWriteString(patchFile, diffContent, io:OVERWRITE);
    
    // Use bash to handle the patch command with redirection in the project directory
    string patchFileName = fileName + ".patch";
    string patchCommand = string `cd '${projectPath}' && patch '${fileName}' < '${patchFileName}'`;
    log:printInfo("Executing patch command: " + patchCommand);
    os:Process|error result = os:exec({
        value: "bash",
        arguments: ["-c", patchCommand]
    });

    // Temporarily disable cleanup for debugging
    // error? cleanupResult = file:remove(patchFile);
    // if cleanupResult is error {
    //     // Ignore cleanup errors
    // }

    if result is error {
        log:printError("Failed to execute patch command", 'error = result);
        return result;
    }

    // Check if patch command was successful
    os:Process process = result;
    int exitCode = check process.waitForExit();
    log:printInfo("Patch command exit code: " + exitCode.toString());
    
    // Exit code 0 = success, exit code 1 = success with offsets/fuzz, exit code 2+ = failure
    if exitCode > 1 {
        return error("Patch command failed with exit code: " + exitCode.toString());
    }
    
    // Verify the patch was actually applied by checking if the original errors are resolved
    boolean isVerified = check verifyPatchApplication(filePath, originalErrors, projectPath);
    if !isVerified {
        return error("Patch applied but original errors still exist in the file");
    }
    
    return true;
}

function verifyPatchApplication(string filePath, CompilationError[] originalErrors, string projectPath) returns boolean|error {
    // Build just this file to check if the specific errors are resolved
    command_executor:CommandResult buildResult = command_executor:executeBalBuild(projectPath);
    
    if command_executor:isCommandSuccessfull(buildResult) {
        // If build is successful, all errors are resolved
        return true;
    }
    
    // Parse current errors
    CompilationError[] currentErrors = parseCompilationErrors(buildResult.stderr);
    
    // Filter errors for this specific file
    CompilationError[] currentFileErrors = currentErrors.filter(function(CompilationError err) returns boolean {
        return err.filePath == extractFileName(filePath);
    });
    
    // Check if any of the original errors still exist
    foreach CompilationError originalError in originalErrors {
        foreach CompilationError currentError in currentFileErrors {
            // Check if this is the same error (same line, column, and message)
            if originalError.line == currentError.line && 
               originalError.column == currentError.column &&
               originalError.message == currentError.message {
                // Original error still exists, patch didn't work
                log:printWarn("Original error still exists after patch", 
                    line = originalError.line, 
                    column = originalError.column, 
                    message = originalError.message);
                return false;
            }
        }
    }
    
    // All original errors are resolved (though there might be new errors)
    return true;
}

function extractFileName(string fullPath) returns string {
    int? lastSlashOpt = fullPath.lastIndexOf("/");
    if lastSlashOpt is int && lastSlashOpt >= 0 {
        return fullPath.substring(lastSlashOpt + 1);
    }
    return fullPath;
}

function extractDiffBlock(string content) returns string {
    // Extracts the first diff block between ```diff ... ```
    int? startOpt = content.indexOf("```diff");
    if startOpt is () {
        return "";
    }
    int 'start = <int>startOpt;
    int? endOpt = content.indexOf("```", 'start + 7);
    if endOpt is () {
        return "";
    }
    int end = <int>endOpt;
    // Extract the diff block
    int diffStart = 'start + 7;
    string diffBlock = content.substring(diffStart, end);
    return normalizeDiff(diffBlock.trim());
}

function normalizeDiff(string diff) returns string {
    string[] lines = regexp:split(re `\n`, diff);
    string[] normalizedLines = [];
    
    foreach string line in lines {
        if line.startsWith("--- ") {
            // Extract just the filename from the path
            string path = line.substring(4);
            // Remove the a/ prefix and any absolute path, keep just the filename
            if path.startsWith("a//") || path.startsWith("a/") {
                int? slashIndexOpt = path.lastIndexOf("/");
                if slashIndexOpt is int && slashIndexOpt >= 0 {
                    int slashIndex = slashIndexOpt;
                    string filename = path.substring(slashIndex + 1);
                    normalizedLines.push("--- " + filename);
                } else {
                    normalizedLines.push("--- " + path.substring(2)); // Remove "a/"
                }
            } else {
                normalizedLines.push(line);
            }
        } else if line.startsWith("+++ ") {
            // Extract just the filename from the path
            string path = line.substring(4);
            // Remove the b/ prefix and any absolute path, keep just the filename
            if path.startsWith("b//") || path.startsWith("b/") {
                int? slashIndexOpt = path.lastIndexOf("/");
                if slashIndexOpt is int && slashIndexOpt >= 0 {
                    int slashIndex = slashIndexOpt;
                    string filename = path.substring(slashIndex + 1);
                    normalizedLines.push("+++ " + filename);
                } else {
                    normalizedLines.push("+++ " + path.substring(2)); // Remove "b/"
                }
            } else {
                normalizedLines.push(line);
            }
        } else {
            normalizedLines.push(line);
        }
    }
    
    return string:'join("\n", ...normalizedLines);
}

public function fixAllBallerinaErrors(string projectPath) returns BallerinaFixerError|BallerinaFixResult {
    log:printInfo("Starting ballerina error fixing process", projectPath = projectPath);

    BallerinaFixResult result = {
        success: false,
        errorsFixed: 0,
        errorsRemaining: 0,
        appliedFixes: [],
        remainingFixes: []
    };

    ai:ModelProvider anthropicModel = check new anthropic:ModelProvider(apiKey, anthropic:CLAUDE_SONNET_4_20250514);

    int iteration = 0;

    while iteration < maxIterations {
        iteration += 1;
        log:printInfo("Starting iteration: ", iteration = iteration);

        // build the project and get diagnostics

        command_executor:CommandResult buildResult = command_executor:executeBalBuild(projectPath);

        if command_executor:isCommandSuccessfull(buildResult) {
            log:printInfo("Build successfull!. All errors fiexed.");
            result.success = true;
            return result;
        }

        // Parse errors from build output
        CompilationError[] errors = parseCompilationErrors(buildResult.stderr);
        result.errorsRemaining = errors.length();

        if errors.length() == 0 {
            log:printInfo("No compilation errors found, but build failed", stderr = buildResult.stderr);
            break;
        }
        log:printInfo("Found compilation errors", count = errors.length());

        //group errors by file 
        map<CompilationError[]> errosByFile = groupErrorsByFile(errors);

        boolean anyErrorFixed = false;
        foreach string filePath in errosByFile.keys() {
            CompilationError[] fileErrors = errosByFile.get(filePath);

            //try to fix errors in this file
            boolean|error fixResult = fixErrorsInFile(anthropicModel, projectPath, filePath, fileErrors);
            if fixResult is boolean && fixResult {
                anyErrorFixed = true;
                result.errorsFixed += fileErrors.length();
                result.appliedFixes.push(string `Fixed ${fileErrors.length()} in ${filePath}`);
            } else if fixResult is error {
                log:printError("Failed to fix errors in file: ", filePath = filePath, 'error = fixResult);
            }
        }
        if !anyErrorFixed {
            log:printWarn("No errors were fixed in this ieteration :(");
            break;
        }

    }
    // final check 
    command_executor:CommandResult finalBuildResult = command_executor:executeBalBuild(projectPath);
    if command_executor:isCommandSuccessfull(finalBuildResult) {
        result.success = true;
        result.errorsRemaining = 0;
    } else {
        CompilationError[] remainingErrors = parseCompilationErrors(finalBuildResult.stderr);
        result.errorsRemaining = remainingErrors.length();
    }

    return result;
}

function groupErrorsByFile(CompilationError[] errors) returns map<CompilationError[]> {
    map<CompilationError[]> grouped = {};

    foreach CompilationError err in errors {
        if !grouped.hasKey(err.filePath) {
            grouped[err.filePath] = [];
        }
        grouped.get(err.filePath).push(err);
    }
    return grouped;
}

function parseCompilationErrors(string stderr) returns CompilationError[] {
    CompilationError[] errors = [];
    string[] lines = regexp:split(re `\n`, stderr);

    foreach string line in lines {
        // Handle both ERROR and WARNING messages
        if (line.includes("ERROR [") || line.includes("WARNING [")) && line.includes(")]") {
            string severity = line.includes("ERROR [") ? "ERROR" : "WARNING";
            string prefix = severity + " [";

            int? startBracket = line.indexOf(prefix);
            int? endBracket = line.indexOf(")]", startBracket ?: 0);

            if startBracket is int && endBracket is int {
                // Extract the part between prefix and ")]"
                string errorPart = line.substring(startBracket + prefix.length(), endBracket);

                // Find the last occurrence of ":(" to split filename from coordinates
                int? coordStart = errorPart.lastIndexOf(":(");

                if coordStart is int {
                    string filePath = errorPart.substring(0, coordStart);
                    string coordinates = errorPart.substring(coordStart + 2); // Skip ":("

                    // Parse coordinates - format can be (line:col) or (line:col,endLine:endCol)
                    string[] coordParts = regexp:split(re `,`, coordinates);
                    if coordParts.length() > 0 {
                        // Get the first coordinate pair (line:col)
                        string[] lineCol = regexp:split(re `:`, coordParts[0]);
                        if lineCol.length() >= 2 {
                            int|error lineNum = int:fromString(lineCol[0]);
                            int|error col = int:fromString(lineCol[1]);

                            // Extract message - everything after ")]" plus 2 for ") "
                            string message = line.substring(endBracket + 2).trim();

                            if lineNum is int && col is int {
                                CompilationError compilationError = {
                                    filePath: filePath,
                                    line: lineNum,
                                    severity: severity,
                                    column: col,
                                    message: message
                                };
                                errors.push(compilationError);
                            }
                        }
                    }
                }
            }
        }
    }
    return errors;
}

function fixErrorsInFile(ai:ModelProvider model, string projectPath, string filePath, CompilationError[] errors) returns boolean|error {
    log:printInfo("Attempting to fix errors in file: ", filePath = filePath, errorCount = errors.length());

    // Construct full file path using proper path joining
    string fullFilePath = check file:joinPath(projectPath, filePath);

    // Validate file exists before reading
    boolean exists = check file:test(fullFilePath, file:EXISTS);
    if !exists {
        return error(string `File does not exist: ${fullFilePath}`);
    }

    // Read file with proper error handling
    string|io:Error fileContent = io:fileReadString(fullFilePath);
    if fileContent is io:Error {
        log:printError("Failed to read file", filePath = fullFilePath, 'error = fileContent);
        return fileContent;
    }

    // if file is too large extract relevant sections
    string codeToFix = extractRelevantCode(fileContent, errors);
    io:println("----CODE TO FIX------");
    io:println(codeToFix);

    // prepare error context
    string errorContext = prepareErrorContext(errors);
    io:println("----ERROR CONTEXT------");

        // Debug: Print file length and first few errors for verification
    log:printInfo("DEBUG - File content length: " + fileContent.length().toString());
    log:printInfo("DEBUG - Number of errors: " + errors.length().toString());
    if errors.length() > 0 {
        log:printInfo("DEBUG - First error line: " + errors[0].line.toString() + ", column: " + errors[0].column.toString());
    }


    io:println(errorContext);

    //Get fix from LLM
    string promptText = createFixPrompt(codeToFix, errorContext, fullFilePath);

    ai:ChatMessage[] messages = [
        {role: "user", content: promptText}
    ];

    ai:ChatAssistantMessage|error response = model->chat(messages);
    if response is error {
        log:printError("LLM failed to generate a fix", 'error = response);
        return response;
    }
    io:println("----RESPONSE------");
    io:println(response);

    // Parse the diff from the LLM response
    string? content = response.content;
    if content is () {
        return error("Empty response from LLM");
    }

    // Extract the diff block from the response (between ```diff ... ```)
    string diffBlock = extractDiffBlock(content);
    if diffBlock == "" {
        log:printError("No diff block found in LLM response", response = content);
        return error("No diff block found in LLM response");
    }

    // Backup the file before patching
    string backupPath = fullFilePath + ".backup";
    io:Error? backupResult = io:fileWriteString(backupPath, fileContent, io:OVERWRITE);
    if backupResult is io:Error {
        log:printError("Failed to create backup", filePath = backupPath, 'error = backupResult);
        return backupResult;
    }

    // Debug: print the normalized diff
    io:println("----NORMALIZED DIFF------");
    io:println(diffBlock);
    
    // Apply the patch with verification
    boolean|error patchResult = applyPatch(fullFilePath, diffBlock, errors, projectPath);
    io:println("--------PATCH RESULT STATUS-------");
    io:println(patchResult);
    if patchResult is error {
        log:printError("Failed to apply patch", filePath = fullFilePath, 'error = patchResult);
        // Attempt to restore from backup
        io:Error? restoreResult = io:fileWriteString(fullFilePath, fileContent, io:OVERWRITE);
        if restoreResult is io:Error {
            log:printError("Failed to restore original content", filePath = fullFilePath, 'error = restoreResult);
        }
        return patchResult;
    }

    // Clean up backup file after successful patch
    file:Error? deleteResult = file:remove(backupPath);
    if deleteResult is file:Error {
        log:printWarn("Failed to delete backup file", backupPath = backupPath, 'error = deleteResult);
    }

    log:printInfo("Applied patch to file", filePath = fullFilePath);
    return true;
}

function applyFix(string filePath, FixResponse fix, string originalContent) returns boolean|error {
    if fix.confidence == "low" {
        log:printWarn("LLM has low confidence in fix, skipping", filePath = filePath);
        return false;
    }

    // Validate file path and permissions
    boolean exists = check file:test(filePath, file:EXISTS);
    if !exists {
        return error(string `Target file does not exist: ${filePath}`);
    }

    boolean writable = check file:test(filePath, file:WRITABLE);
    if !writable {
        return error(string `File is not writable: ${filePath}`);
    }

    // Create a backup with proper file operations
    string backupPath = filePath + ".backup";
    io:Error? backupResult = io:fileWriteString(backupPath, originalContent, io:OVERWRITE);
    if backupResult is io:Error {
        log:printError("Failed to create backup", filePath = backupPath, 'error = backupResult);
        return backupResult;
    }

    // Apply the fix with proper write options
    io:Error? writeResult = io:fileWriteString(filePath, fix.fixedCode, io:OVERWRITE);
    if writeResult is io:Error {
        log:printError("Failed to write fixed code", filePath = filePath, 'error = writeResult);
        
        // Attempt to restore from backup
        io:Error? restoreResult = io:fileWriteString(filePath, originalContent, io:OVERWRITE);
        if restoreResult is io:Error {
            log:printError("Failed to restore original content", filePath = filePath, 'error = restoreResult);
        }
        return writeResult;
    }

    // Clean up backup file after successful write
    file:Error? deleteResult = file:remove(backupPath);
    if deleteResult is file:Error {
        log:printWarn("Failed to delete backup file", backupPath = backupPath, 'error = deleteResult);
    }

    log:printInfo("Applied fix to file", filePath = filePath, explanation = fix.explanation);
    return true;
}

function createFixPrompt(string code, string errorContext, string filePath) returns string {
    string tripleBacktick = "```";

    return string `You are an expert Ballerina programmer. I need you to fix compilation errors in the following Ballerina code.

File: ${filePath}

Compilation Errors: 
${errorContext}

Code to fix:
${code}

Please provide the fix as a unified diff (git diff) patch, using the original file as the base.

Important instructions:
1. Only include the minimal changes needed to fix the errors.
2. Include **at least 3 context lines before and after each change**.
3. Preserve all other lines of the file exactly as they are.
4. Use proper unified diff format with @@ -start,count +start,count @@ headers.
5. If you are not confident, add a comment at the top of the diff.
6. Ensure the patch can be applied cleanly using 'git apply'.

Your response must be in this format:

${tripleBacktick}diff
--- a/${filePath}
+++ b/${filePath}
@@ ...
<diff here>
${tripleBacktick}`;
}

function prepareErrorContext(CompilationError[] errors) returns string {
    string[] errorStrings = errors.'map(function(CompilationError err) returns string {
        return string `Line ${err.line}, Column ${err.column}: ${err.message}`;
    });
    return string:'join("\n", ...errorStrings);
}

function extractRelevantCode(string fullCode, CompilationError[] errors) returns string {
    if fullCode.length() <= MAX_CODE_LENGTH {
        return fullCode;
    }

    // find the range of lines that contain 
    int minLine = errors.reduce(function(int acc, CompilationError err) returns int {
        return int:min(acc, err.line);
    }, int:MAX_VALUE);

    int maxLine = errors.reduce(function(int acc, CompilationError err) returns int {
        return int:max(acc, err.line);
    }, 0);

    // add some context around the error lines
    int contextLines = 10;
    string[] lines = regexp:split(re `\n`, fullCode);

    int startLine = int:max(0, minLine - contextLines - 1);
    int endLine = int:min(lines.length() - 1, maxLine + contextLines - 1);

    string[] relevantLines = lines.slice(startLine, endLine + 1);

    return string:'join("\n", ...relevantLines);

}



function parseFixResponse(string content) returns FixResponse|error {
    // Try to parse as JSON
    json|error jsonResult = content.fromJsonString();
    if jsonResult is error {
        // If JSON parsing fails, treat the entire content as fixed code with low confidence
        return {
            fixedCode: content,
            explanation: "LLM provided direct code fix",
            confidence: "low"
        };
    }

    json jsonData = jsonResult;
    if jsonData is map<json> {
        string? fixedCode = jsonData["fixedCode"] is string ? <string>jsonData["fixedCode"] : ();
        string? explanation = jsonData["explanation"] is string ? <string>jsonData["explanation"] : ();
        string? confidence = jsonData["confidence"] is string ? <string>jsonData["confidence"] : ();

        if fixedCode is () {
            return error("Missing 'fixedCode' field in LLM response");
        }

        return {
            fixedCode: fixedCode,
            explanation: explanation ?: "No explanation provided",
            confidence: confidence ?: "low"
        };
    }

    return error("Invalid JSON structure in LLM response");
}

//function errorToString(CompilationError err) returns string {
//    return string `${err.severity} at ${err.filePath}:${err.line}:${err.column} - ${err.message}`;
//}
