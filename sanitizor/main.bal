import sanitizor.command_executor;
import sanitizor.error_registry;
import sanitizor.file_management;
import sanitizor.llm_service;

import ballerina/io;
import ballerina/log;

public function main(string... args) returns error? {
    log:printInfo("Starting OpenAPI Sanitizor...");

    // Check command line arguments
    if args.length() < 2 {
        printUsage();
        return;
    }

    string inputSpecPath = args[0]; // /home/hansika/dev/sanitizor/temp-workspace/docs/spec/openapi.json
    string outputDir = args[1]; ///home/hansika/dev/sanitizor/temp-workspace

    log:printInfo("Processing OpenAPI spec", inputSpec = inputSpecPath, outputDir = outputDir);

    // Initialize LLM service
    llm_service:LLMServiceError? llmInitResult = llm_service:initLLMService();
    if llmInitResult is llm_service:LLMServiceError {
        log:printError("Failed to initialize LLM service", 'error = llmInitResult);
        io:println("Warning: LLM service not available. Only programmatic fixes will be applied.");
    } else {
        log:printInfo("LLM service initialized successfully");
    }

    // Step 1: Backup original spec
    string|file_management:FileManagementError backupResult = file_management:backupSpec(inputSpecPath);
    if backupResult is file_management:FileManagementError {
        log:printError("Failed to backup original spec", 'error = backupResult);
        return backupResult;
    }
    log:printInfo("Original spec backed up", backupPath = backupResult);

    // Step 2: Execute OpenAPI flatten
    string flattenedSpecPath = outputDir + "/docs/spec";
    command_executor:CommandResult flattenResult = command_executor:executeBalFlatten(inputSpecPath, flattenedSpecPath);
    if !command_executor:isCommandSuccessfull(flattenResult) {
        log:printError("OpenAPI flatten failed", result = flattenResult);
        return error("Flatten operation failed: " + flattenResult.stderr);
    }
    log:printInfo("OpenAPI spec flattened successfully", outputPath = flattenedSpecPath);

    // Step 3: Execute OpenAPI align
    flattenedSpecPath = flattenedSpecPath + "/flattened_openapi.json";
    string alignedSpecPath = outputDir + "/docs/spec";
    command_executor:CommandResult alignResult = command_executor:executeBalAlign(flattenedSpecPath, alignedSpecPath);
    if !command_executor:isCommandSuccessfull(alignResult) {
        log:printError("OpenAPI align failed", result = alignResult);
        return error("Align operation failed: " + alignResult.stderr);
    }
    log:printInfo("OpenAPI spec aligned successfully", outputPath = alignedSpecPath);

    // Step 4: Generate Ballerina client
    string clientOutputPath = outputDir + "/ballerina";
    alignedSpecPath = alignedSpecPath + "/aligned_ballerina_openapi.json";
    command_executor:CommandResult generateResult = command_executor:executeBalClientGenerate(alignedSpecPath, clientOutputPath);
    if !command_executor:isCommandSuccessfull(generateResult) {
        log:printError("Client generation failed", result = generateResult);
        return error("Client generation failed: " + generateResult.stderr);
    }
    log:printInfo("Ballerina client generated successfully", outputPath = clientOutputPath);

    // Step 5: Build generated client and analyze errors
    command_executor:CommandResult buildResult = command_executor:executeBalBuild(clientOutputPath);

    if buildResult.compilationErrors.length() == 0 {
        io:println("Success! No compilation errors found.");
        log:printInfo("Build completed successfully with no errors");
        return;
    }

    io:println(string `Found ${buildResult.compilationErrors.length()} compilation issues. Analyzing...`);
    log:printInfo("Found compilation errors", errorCount = buildResult.compilationErrors.length());

    // Step 6: Categorize and route errors
    map<command_executor:CompilationError[]> categorizedErrors = error_registry:routeErrorsByStrategy(buildResult.compilationErrors);

    return processErrorCategories(categorizedErrors, alignedSpecPath, clientOutputPath);
}

function processErrorCategories(map<command_executor:CompilationError[]> categorizedErrors, string alignedSpecPath, string clientOutputPath) returns error? {
    // Process redeclared symbol errors programmatically
    command_executor:CompilationError[]? redeclaredErrors = categorizedErrors["PROGRAMMATIC_SPEC_FIX"];
    if redeclaredErrors is command_executor:CompilationError[] && redeclaredErrors.length() > 0 {
        io:println(string `🔧 Fixing ${redeclaredErrors.length()} redeclared symbol errors programmatically...`);
        error_registry:BatchFixResult|error_registry:ErrorRegistryError batchResult = error_registry:applyBatchFixes(redeclaredErrors, alignedSpecPath);
        if batchResult is error_registry:BatchFixResult {
            io:println(string `Fixed ${batchResult.fixedErrors}/${batchResult.totalErrors} redeclared symbol errors`);
            log:printInfo("Programmatic fixes applied", fixedCount = batchResult.fixedErrors);
        } else {
            log:printError("Failed to apply programmatic fixes", 'error = batchResult);
            io:println("Failed to apply programmatic fixes");
        }
    }

    // Process undocumented field warnings using LLM
    command_executor:CompilationError[]? undocumentedErrors = categorizedErrors["LLM_SPEC_FIX"];
    if undocumentedErrors is command_executor:CompilationError[] && undocumentedErrors.length() > 0 {
        io:println(string `Fixing ${undocumentedErrors.length()} undocumented field warnings using LLM...`);
        error_registry:BatchFixResult|error_registry:ErrorRegistryError llmBatchResult = error_registry:applyBatchFixes(undocumentedErrors, alignedSpecPath);
        if llmBatchResult is error_registry:BatchFixResult {
            io:println(string `Fixed ${llmBatchResult.fixedErrors}/${llmBatchResult.totalErrors} undocumented field warnings`);
            log:printInfo("LLM spec fixes applied", fixedCount = llmBatchResult.fixedErrors);
        } else {
            log:printError("Failed to apply LLM spec fixes", 'error = llmBatchResult);
            io:println("Failed to apply LLM spec fixes");
        }
    }

    // Handle other errors - prompt user
    command_executor:CompilationError[]? otherErrors = categorizedErrors["USER_PROMPT_REQUIRED"];
    if otherErrors is command_executor:CompilationError[] && otherErrors.length() > 0 {
        return handleOtherErrors(otherErrors, clientOutputPath);
    }

    // Rebuild after fixes
    io:println("🔨 Rebuilding after applying fixes...");
    command_executor:CommandResult finalBuildResult = command_executor:executeBalBuild(clientOutputPath);

    if finalBuildResult.compilationErrors.length() == 0 {
        io:println("All issues resolved! Build completed successfully.");
        log:printInfo("Final build successful - all errors resolved");
    } else {
        io:println(string `${finalBuildResult.compilationErrors.length()} issues remain after fixes.`);
        log:printWarn("Some errors remain after fixes", remainingErrors = finalBuildResult.compilationErrors.length());
    }
}

function handleOtherErrors(command_executor:CompilationError[] otherErrors, string clientOutputPath) returns error? {
    io:println(string `Found ${otherErrors.length()} other compilation errors that cannot be fixed in the OpenAPI spec.`);
    io:println("These errors need to be fixed in the generated Ballerina code.");

    // Show a few sample errors
    int samplesToShow = otherErrors.length() > 3 ? 3 : otherErrors.length();
    io:println("\nSample errors:");
    foreach int i in 0 ..< samplesToShow {
        command_executor:CompilationError err = otherErrors[i];
        io:println(string `  • ${err.fileName}:${err.line}:${err.column} - ${err.message}`);
    }

    if otherErrors.length() > 3 {
        io:println(string `  ... and ${otherErrors.length() - 3} more errors`);
    }

    // Prompt user for confirmation
    io:println("\nWould you like to attempt automatic fixes to the Ballerina code using LLM? (y/n):");
    string? userInput = io:readln();

    if userInput is string && (userInput.trim().toLowerAscii() == "y" || userInput.trim().toLowerAscii() == "yes") {
        io:println("🤖 Attempting to fix Ballerina code errors using LLM...");
        return attemptLLMBallerintFixes(otherErrors, clientOutputPath);
    } else {
        io:println("Skipping automatic fixes. Please review and fix the errors manually.");
        log:printInfo("User declined automatic Ballerina fixes");
    }
}

function attemptLLMBallerintFixes(command_executor:CompilationError[] errors, string clientOutputPath) returns error? {
    // Group errors by file for more efficient processing
    map<command_executor:CompilationError[]> errorsByFile = {};

    foreach command_executor:CompilationError err in errors {
        command_executor:CompilationError[]? existingErrors = errorsByFile[err.fileName];
        if existingErrors is () {
            errorsByFile[err.fileName] = [err];
        } else {
            existingErrors.push(err);
        }
    }

    io:println(string `Processing errors in ${errorsByFile.keys().length()} files...`);

    foreach string fileName in errorsByFile.keys() {
        command_executor:CompilationError[]? fileErrors = errorsByFile[fileName];
        if fileErrors is command_executor:CompilationError[] {
            io:println(string `Fixing ${fileErrors.length()} errors in ${fileName}...`);

            // Read the file content for context
            string filePath = clientOutputPath + "/" + fileName;
            string|error fileContent = io:fileReadString(filePath);
            if fileContent is error {
                log:printError("Failed to read file for LLM fixes", fileName = fileName, 'error = fileContent);
                continue;
            }

            // Extract error messages
            string[] errorMessages = [];
            foreach command_executor:CompilationError err in fileErrors {
                errorMessages.push(string `Line ${err.line}: ${err.message}`);
            }

            // Use LLM to generate fixes
            string[]|llm_service:LLMServiceError llmSuggestions = llm_service:generateBallerinaFixSuggestions(errorMessages, fileContent);
            if llmSuggestions is llm_service:LLMServiceError {
                log:printError("LLM failed to generate fix suggestions", fileName = fileName, 'error = llmSuggestions);
                io:println(string `Failed to generate fixes for ${fileName}`);
            } else {
                io:println(string `Generated ${llmSuggestions.length()} fix suggestions for ${fileName}`);
                // In a full implementation, you would apply these suggestions
                // For now, just log them
                foreach string suggestion in llmSuggestions {
                    log:printInfo("LLM fix suggestion", fileName = fileName, suggestion = suggestion);
                }
            }
        }
    }

    io:println("LLM fix suggestions generated. Manual review and application required.");
    log:printInfo("LLM Ballerina fixes completed");
}

function printUsage() {
    io:println("Usage: bal run -- <input-openapi-spec> <output-directory>");
    io:println("  <input-openapi-spec>: Path to the OpenAPI specification file");
    io:println("  <output-directory>: Directory where processed files will be stored");
    io:println("");
    io:println("Example:");
    io:println("  bal run -- /path/to/openapi.yaml ./output");
    io:println("");
    io:println("Environment Variables:");
    io:println("  ANTHROPIC_API_KEY: Required for LLM-based fixes");
}
