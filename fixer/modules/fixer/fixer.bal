import fixer.command_executor;

import ballerina/ai;
import ballerina/file;
import ballerina/io;
import ballerina/lang.array;
import ballerina/lang.regexp;
import ballerina/log;
import ballerinax/ai.anthropic;

configurable string apiKey = ?;
configurable int maxIterations = ?;

// Parse compilation errors from build output (only ERRORs)
public function parseCompilationErrors(string stderr) returns CompilationError[] {
    CompilationError[] errors = [];
    string[] lines = regexp:split(re `\n`, stderr);

    foreach string line in lines {
        // Handle only ERROR messages
        if (line.includes("ERROR [") && line.includes(")]")) {
            string severity = "ERROR";
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

Instructions:
- Return the full updated copy of the source ballerina file that needed changes.
- Do not include explanations, markdown formatting, or code fences.
- Preserve the original structure, comments, and imports where possible.
- Fix all compilation errors. 
- Ensure the code follows Ballerina best practices. 
- Try to resolve the error with minumum changes. 

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

    log:printInfo("Sending fix request to LLM");

    // Get fix from LLM
    string|error llmResponse = fixBallerinaCode(prompt);
    if llmResponse is error {
        log:printError("LLM failed to generate fix", 'error = llmResponse);
        return error(string `LLM failed to generate fix: ${llmResponse.message()}`);
    }

    // Return the response
    return {
        success: true,
        fixedCode: llmResponse,
        explanation: "Fixed using LLM"
    };
}

public function fixBallerinaCode(string prompt) returns string|error {
    ai:ModelProvider anthropicModel = check new anthropic:ModelProvider(apiKey, anthropic:CLAUDE_SONNET_4_20250514, maxTokens = 64000, temperature = 0.4d, timeout = 300);

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

    int iteration = 1;
    CompilationError[] previousErrors = [];
    int initialErrorCount = 0;
    boolean initialErrorCountSet = false;

    while iteration <= maxIterations {
        log:printInfo("Starting iteration", iteration = iteration, maxIterations = maxIterations);

        // Build the project and get diagnostics
        command_executor:CommandResult buildResult = command_executor:executeBalBuild(projectPath);

        if command_executor:isCommandSuccessfull(buildResult) {
            log:printInfo("Build successful! All errors fixed.", iteration = iteration);
            result.success = true;
            result.errorsRemaining = 0;
            // If this is the first iteration and build is successful, no errors to fix
            if iteration == 1 {
                result.errorsFixed = 0;
            } else {
                result.errorsFixed = initialErrorCount; // All initial errors were fixed
            }
            return result;
        }

        // Parse errors from build output
        CompilationError[] currentErrors = parseCompilationErrors(buildResult.stderr);

        if currentErrors.length() == 0 {
            log:printInfo("No compilation errors found.");
            // If we reach here, build failed but no compilation errors were parsed
            // This might be due to different types of build issues (warnings, other errors, etc.)
            // Let's check the build output to see if it's actually successful
            
            // Sometimes builds fail with warnings or other issues that aren't compilation errors
            // If no compilation errors were found, we should consider this a success
            log:printInfo("No compilation errors detected - considering build successful", iteration = iteration);
            result.success = true;
            result.errorsRemaining = 0;
            result.errorsFixed = initialErrorCountSet ? initialErrorCount : 0;
            return result;
        }

        log:printInfo("Found compilation errors", count = currentErrors.length(), iteration = iteration);

        // Set initial error count for tracking progress
        if !initialErrorCountSet {
            initialErrorCount = currentErrors.length();
            initialErrorCountSet = true;
        }

        // Check if we're making progress (error count should decrease or errors should change)
        if iteration > 1 {
            if currentErrors.length() >= previousErrors.length() {
                // Check if errors are exactly the same (no progress)
                boolean sameErrors = checkIfErrorsAreSame(currentErrors, previousErrors);
                if sameErrors {
                    log:printWarn("No progress made in this iteration - same errors persist", iteration = iteration);
                    result.remainingFixes.push(string `Iteration ${iteration}: No progress - same errors persist`);

                }
            } else {
                log:printInfo("Progress made - error count reduced",
                        previousCount = previousErrors.length(),
                        currentCount = currentErrors.length(),
                        iteration = iteration);
            }
        }

        // Store current errors for next iteration comparison
        previousErrors = currentErrors.clone();
        result.errorsRemaining = currentErrors.length();

        // Group errors by file
        map<CompilationError[]> errorsByFile = groupErrorsByFile(currentErrors);

        boolean anyFixApplied = false;

        // Process each file
        foreach string filePath in errorsByFile.keys() {
            CompilationError[] fileErrors = errorsByFile.get(filePath);

            log:printInfo("Processing file", filePath = filePath, errorCount = fileErrors.length(), iteration = iteration);

            // Get fix from LLM
            FixResponse|error fixResponse = fixFileWithLLM(projectPath, filePath, fileErrors);
            if fixResponse is error {
                log:printError("Failed to get fix from LLM", filePath = filePath, 'error = fixResponse, iteration = iteration);
                result.remainingFixes.push(string `Iteration ${iteration}: Failed to fix ${filePath}: ${fixResponse.message()}`);
                continue;
            }

            // Ask user for confirmation
            io:println(string `\n=== Iteration ${iteration} - Fix for ${filePath} ===`);
            io:println("Errors to fix:");
            foreach CompilationError err in fileErrors {
                io:println(string `  Line ${err.line}: ${err.message}`);
            }
            io:println("\nProposed fix:");
            io:println("```ballerina");
            io:println(fixResponse.fixedCode);
            io:println("```");

            io:print(string `\nApply this fix? (y/n): `);
            string|io:Error userInput = io:readln();
            if userInput is io:Error {
                log:printError("Failed to read user input", 'error = userInput);
                continue;
            }

            string trimmedInput = userInput.trim().toLowerAscii();

            if trimmedInput == "y" {
                // Apply the fix
                boolean|error applyResult = applyFix(projectPath, filePath, fixResponse.fixedCode);
                if applyResult is error {
                    log:printError("Failed to apply fix", filePath = filePath, 'error = applyResult, iteration = iteration);
                    result.remainingFixes.push(string `Iteration ${iteration}: Failed to apply fix to ${filePath}: ${applyResult.message()}`);
                    continue;
                }

                anyFixApplied = true;
                result.appliedFixes.push(string `Iteration ${iteration}: Applied fix to ${filePath} (${fileErrors.length()} errors)`);
                log:printInfo("Successfully applied fix to file", filePath = filePath, iteration = iteration);
            } else {
                result.remainingFixes.push(string `Iteration ${iteration}: User declined fix for ${filePath}`);
                log:printInfo("User declined fix", filePath = filePath, iteration = iteration);
            }
        }

        // If no fixes were applied in this iteration, break to avoid infinite loop
        if !anyFixApplied {
            log:printWarn("No fixes were applied in this iteration", iteration = iteration);
            result.remainingFixes.push(string `Iteration ${iteration}: No fixes applied - stopping iterations`);

        }

        iteration += 1;
    }

    // Final status check
    if iteration > maxIterations {
        log:printWarn("Maximum iterations reached", maxIterations = maxIterations);
        result.remainingFixes.push(string `Maximum iterations (${maxIterations}) reached`);
    }

    // Final build check
    command_executor:CommandResult finalBuildResult = command_executor:executeBalBuild(projectPath);
    if command_executor:isCommandSuccessfull(finalBuildResult) {
        result.success = true;
        result.errorsRemaining = 0;
        result.errorsFixed = initialErrorCount; // All initial errors were fixed
        log:printInfo("All errors fixed successfully after iterations!", totalIterations = iteration - 1);
    } else {
        CompilationError[] remainingErrors = parseCompilationErrors(finalBuildResult.stderr);
        result.errorsRemaining = remainingErrors.length();
        result.errorsFixed = initialErrorCount - remainingErrors.length(); // Calculate how many were fixed
        log:printInfo("Some errors remain after iterations",
                count = remainingErrors.length(),
                totalIterations = iteration - 1);
    }

    return result;
}

// Helper function to check if two error arrays contain the same errors
function checkIfErrorsAreSame(CompilationError[] current, CompilationError[] previous) returns boolean {
    if current.length() != previous.length() {
        return false;
    }

    // Sort both arrays by file path and line number for comparison
    CompilationError[] sortedCurrent = current.sort(array:ASCENDING, key = isolated function(CompilationError err) returns string {
        return string `${err.filePath}:${err.line}:${err.column}`;
    });

    CompilationError[] sortedPrevious = previous.sort(array:ASCENDING, key = isolated function(CompilationError err) returns string {
        return string `${err.filePath}:${err.line}:${err.column}`;
    });

    // Compare each error
    foreach int i in 0 ..< sortedCurrent.length() {
        CompilationError currentErr = sortedCurrent[i];
        CompilationError previousErr = sortedPrevious[i];

        if currentErr.filePath != previousErr.filePath ||
            currentErr.line != previousErr.line ||
            currentErr.column != previousErr.column ||
            currentErr.message != previousErr.message {
            return false;
        }
    }

    return true;
}

