import sanitizor.command_executor;

import ballerina/ai;
import ballerina/file;
import ballerina/io;
import ballerina/lang.regexp;
import ballerina/log;
import ballerinax/ai.anthropic;

configurable string apiKey = ?;

// Parse compilation errors from build output
public function parseCompilationErrors(string stderr) returns CompilationError[] {
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

// Group errors by file path
public function groupErrorsByFile(CompilationError[] errors) returns map<CompilationError[]> {
    map<CompilationError[]> grouped = {};

    foreach CompilationError err in errors {
        if !grouped.hasKey(err.filePath) {
            grouped[err.filePath] = [];
        }
        grouped.get(err.filePath).push(err);
    }
    return grouped;
}

// Create fix prompt for LLM
public function createFixPrompt(string code, CompilationError[] errors, string filePath) returns string {
    string errorContext = prepareErrorContext(errors);

    return string `You are an expert Ballerina developer. Fix the following Ballerina code to resolve the compilation errors.

File: ${filePath}

Compilation Errors:
${errorContext}


// Instructions:
// - Return the full updated copy of the source ballerina file that needed changes.
// - Do not include explanations, markdown formatting, or code fences
// - Preserve the original structure, comments, and imports where possible
// - Fix all compilation errors
// - Ensure the code follows Ballerina best practices

Current Code:
${code}
`;
}

// Prepare error context string
function prepareErrorContext(CompilationError[] errors) returns string {
    string[] errorStrings = errors.'map(function(CompilationError err) returns string {
        return string `Line ${err.line}, Column ${err.column}: ${err.severity} - ${err.message}`;
    });
    return string:'join("\n", ...errorStrings);
}

// Fix errors in a single file
public function fixFileWithLLM(string projectPath, string filePath, CompilationError[] errors) returns FixResponse|error {
    log:printInfo("Attempting to fix file with LLM", filePath = filePath, errorCount = errors.length());

    // Construct full file path
    string fullFilePath = check file:joinPath(projectPath, filePath);

    // Validate file exists
    boolean exists = check file:test(fullFilePath, file:EXISTS);
    if !exists {
        return error(string `File does not exist: ${fullFilePath}`);
    }

    // Read file content
    string|io:Error fileContent = io:fileReadString(fullFilePath);
    if fileContent is io:Error {
        log:printError("Failed to read file", filePath = fullFilePath, 'error = fileContent);
        return fileContent;
    }

    // Create fix prompt
    string prompt = createFixPrompt(fileContent, errors, filePath);
    io:println("----PROMPT--------");
    io:println(prompt);

    log:printInfo("Sending fix request to LLM");

    // Get fix from LLM
    string|error llmResponse = fixBallerinaCode(prompt);
    if llmResponse is error {
        log:printError("LLM failed to generate fix", 'error = llmResponse);
        return error(string `LLM failed to generate fix: ${llmResponse.message()}`);
    }

io:println("----LLM RESONSE-------");
    io:println(llmResponse);

    // Return the response
    return {
        success: true,
        fixedCode: llmResponse,
        explanation: "Fixed using LLM"
    };
}

public function fixBallerinaCode(string prompt) returns string|error {
    ai:ModelProvider anthropicModel = check new anthropic:ModelProvider(apiKey, anthropic:CLAUDE_SONNET_4_20250514, maxTokens = 50000, temperature = 0.1);

    ai:ChatMessage[] messages = [
        {role: "user", content: prompt}
    ];

    ai:ChatAssistantMessage|error response = anthropicModel->chat(messages);
    if (response is error) {
        return error("Failed to generate code fixes", response);
    }

    string? fixedCode = response.content;
    if (fixedCode is ()) {
        return error("Empty response from LLM");
    }

    return fixedCode;
}

// Apply fix to file
public function applyFix(string projectPath, string filePath, string fixedCode) returns boolean|error {
    string fullFilePath = check file:joinPath(projectPath, filePath);

    // Create backup
    string|io:Error originalContent = io:fileReadString(fullFilePath);
    if originalContent is io:Error {
        return originalContent;
    }

    string backupPath = fullFilePath + ".backup";
    io:Error? backupResult = io:fileWriteString(backupPath, originalContent, io:OVERWRITE);
    if backupResult is io:Error {
        log:printError("Failed to create backup", filePath = backupPath, 'error = backupResult);
        return backupResult;
    }

    // Apply fix
    io:Error? writeResult = io:fileWriteString(fullFilePath, fixedCode, io:OVERWRITE);
    if writeResult is io:Error {
        log:printError("Failed to write fixed code", filePath = fullFilePath, 'error = writeResult);

        // Attempt to restore from backup
        io:Error? restoreResult = io:fileWriteString(fullFilePath, originalContent, io:OVERWRITE);
        if restoreResult is io:Error {
            log:printError("Failed to restore original content", filePath = fullFilePath, 'error = restoreResult);
        }
        return writeResult;
    }

    log:printInfo("Applied fix to file", filePath = fullFilePath);
    return true;
}

// Verify fix by checking if errors are resolved
public function verifyFix(string projectPath, CompilationError[] originalErrors) returns boolean|error {
    // Build the project
    command_executor:CommandResult buildResult = command_executor:executeBalBuild(projectPath);

    if command_executor:isCommandSuccessfull(buildResult) {
        // If build is successful, all errors are resolved
        return true;
    }

    // Parse current errors
    CompilationError[] currentErrors = parseCompilationErrors(buildResult.stderr);

    // Check if any of the original errors still exist
    foreach CompilationError originalError in originalErrors {
        foreach CompilationError currentError in currentErrors {
            // Check if this is the same error (same line, column, and message)
            if originalError.filePath == currentError.filePath &&
                originalError.line == currentError.line &&
                originalError.column == currentError.column &&
                originalError.message == currentError.message {
                // Original error still exists
                log:printWarn("Original error still exists after fix",
                        filePath = originalError.filePath,
                        line = originalError.line,
                        column = originalError.column,
                        message = originalError.message);
                return false;
            }
        }
    }

    // All original errors are resolved
    return true;
}

// Main function to fix all errors in a project
public function fixAllErrors(string projectPath) returns FixResult|error {
    log:printInfo("Starting error fixing process", projectPath = projectPath);

    FixResult result = {
        success: false,
        errorsFixed: 0,
        errorsRemaining: 0,
        appliedFixes: [],
        remainingFixes: []
    };

    // Build the project and get diagnostics
    command_executor:CommandResult buildResult = command_executor:executeBalBuild(projectPath);

    if command_executor:isCommandSuccessfull(buildResult) {
        log:printInfo("Build successful! No errors to fix.");
        result.success = true;
        return result;
    }

    // Parse errors from build output
    CompilationError[] errors = parseCompilationErrors(buildResult.stderr);
    result.errorsRemaining = errors.length();

    if errors.length() == 0 {
        log:printInfo("No compilation errors found, but build failed", stderr = buildResult.stderr);
        return result;
    }

    log:printInfo("Found compilation errors", count = errors.length());

    // Group errors by file
    map<CompilationError[]> errorsByFile = groupErrorsByFile(errors);

    // Process each file
    foreach string filePath in errorsByFile.keys() {
        CompilationError[] fileErrors = errorsByFile.get(filePath);

        log:printInfo("Processing file", filePath = filePath, errorCount = fileErrors.length());

        // Get fix from LLM
        FixResponse|error fixResponse = fixFileWithLLM(projectPath, filePath, fileErrors);
        if fixResponse is error {
            log:printError("Failed to get fix from LLM", filePath = filePath, 'error = fixResponse);
            result.remainingFixes.push(string `Failed to fix ${filePath}: ${fixResponse.message()}`);
            continue;
        }

        // Ask user for confirmation
        io:println(string `\n=== Fix for ${filePath} ===`);
        io:println("Errors to fix:");
        foreach CompilationError err in fileErrors {
            io:println(string `  Line ${err.line}: ${err.message}`);
        }
        io:println("\nProposed fix:");
        io:println("```ballerina");
        io:println(fixResponse.fixedCode);
        io:println("```");

        io:print("\nApply this fix? (y/n): ");
        string|io:Error userInput = io:readln();
        if userInput is io:Error {
            log:printError("Failed to read user input", 'error = userInput);
            continue;
        }

        if userInput.trim().toLowerAscii() == "y" {
            // Apply the fix
            boolean|error applyResult = applyFix(projectPath, filePath, fixResponse.fixedCode);
            if applyResult is error {
                log:printError("Failed to apply fix", filePath = filePath, 'error = applyResult);
                result.remainingFixes.push(string `Failed to apply fix to ${filePath}: ${applyResult.message()}`);
                continue;
            }

            // Verify the fix
            boolean|error verifyResult = verifyFix(projectPath, fileErrors);
            if verifyResult is error {
                log:printError("Failed to verify fix", filePath = filePath, 'error = verifyResult);
                result.remainingFixes.push(string `Failed to verify fix for ${filePath}: ${verifyResult.message()}`);
                continue;
            }

            if verifyResult {
                result.errorsFixed += fileErrors.length();
                result.appliedFixes.push(string `Fixed ${fileErrors.length()} errors in ${filePath}`);
                log:printInfo("Successfully fixed and verified file", filePath = filePath);
            } else {
                result.remainingFixes.push(string `Fix for ${filePath} did not resolve all errors`);
                log:printWarn("Fix did not resolve all errors", filePath = filePath);
            }
        } else {
            result.remainingFixes.push(string `User declined fix for ${filePath}`);
            log:printInfo("User declined fix", filePath = filePath);
        }
    }

    // Final check
    command_executor:CommandResult finalBuildResult = command_executor:executeBalBuild(projectPath);
    if command_executor:isCommandSuccessfull(finalBuildResult) {
        result.success = true;
        result.errorsRemaining = 0;
        log:printInfo("All errors fixed successfully!");
    } else {
        CompilationError[] remainingErrors = parseCompilationErrors(finalBuildResult.stderr);
        result.errorsRemaining = remainingErrors.length();
        log:printInfo("Some errors remain", count = remainingErrors.length());
    }

    return result;
}
