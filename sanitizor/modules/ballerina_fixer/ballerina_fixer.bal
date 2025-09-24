import sanitizor.command_executor;

import ballerina/ai;
import ballerina/file;
import ballerina/io;
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

    // Parse the JSON response
    string? content = response.content;
    if content is () {
        return error("Empty response from LLM");
    }

    FixResponse|error llmResponse = parseFixResponse(content);
    if llmResponse is error {
        log:printError("Failed to parse LLM response", 'error = llmResponse);
        return llmResponse;
    }

    // Apply the fix
    boolean applied = check applyFix(fullFilePath, llmResponse, fileContent);
    return applied;

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
    return string `You are an expert ballerina programmer. I need you to fix compilation errors in the following ballerina code.
    FIle: ${filePath}

    Compilation Errors: 
    ${errorContext}
    
    Code to fix:
    ${code}
    
    Please provide the corrected code. Your response must be in the follwoing JSON format:

    {
    "fixedCode": "the complete corrected code",
    "explanation": "brief explanation of what was fixed",
    "confidence": "high|medium|low"
    }

    Important guidelines:
    1. Only fix the specific compilation errors mentioned
    2. Preserve the original code structure and logic as much as possible
    3. Ensure the fixed code follows Ballerina best practices
    4. If you're not confident about a fix, indicate low confidence
    5. Return the complete code section, not just the changed parts`;
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
