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

    return processErrorCategories(categorizedErrors, flattenedSpecPath, outputDir);
}

function reprocessAfterFixes(string flattenedSpecPath, string outputDir) returns error? {
    io:println("Re-aligning spec after fixes...");

    // Step 1: Re-align the fixed flattened spec
    string alignedSpecPath = outputDir + "/docs/spec";
    command_executor:CommandResult alignResult = command_executor:executeBalAlign(flattenedSpecPath, alignedSpecPath);
    if !command_executor:isCommandSuccessfull(alignResult) {
        log:printError("Re-align failed", result = alignResult);
        return error("Re-align operation failed: " + alignResult.stderr);
    }
    log:printInfo("OpenAPI spec re-aligned successfully", outputPath = alignedSpecPath);

    // Step 2: Re-generate Ballerina client
    io:println("Re-generating client after fixes...");
    string clientOutputPath = outputDir + "/ballerina";
    alignedSpecPath = alignedSpecPath + "/aligned_ballerina_openapi.json";
    command_executor:CommandResult generateResult = command_executor:executeBalClientGenerate(alignedSpecPath, clientOutputPath);
    if !command_executor:isCommandSuccessfull(generateResult) {
        log:printError("Client re-generation failed", result = generateResult);
        return error("Client re-generation failed: " + generateResult.stderr);
    }
    log:printInfo("Ballerina client re-generated successfully", outputPath = clientOutputPath);

    // Step 3: Re-build and check for more errors
    io:println("Re-building client to check for remaining errors...");
    command_executor:CommandResult buildResult = command_executor:executeBalBuild(clientOutputPath);

    if buildResult.compilationErrors.length() == 0 {
        io:println("All issues resolved! Build completed successfully.");
        log:printInfo("All errors resolved - build successful");
        return;
    }

    io:println(string `Found ${buildResult.compilationErrors.length()} remaining compilation issues.`);
    log:printInfo("Found remaining compilation errors", errorCount = buildResult.compilationErrors.length());

    // Step 4: Check if there are still redeclared symbol errors to fix
    map<command_executor:CompilationError[]> categorizedErrors = error_registry:routeErrorsByStrategy(buildResult.compilationErrors);
    command_executor:CompilationError[]? redeclaredErrors = categorizedErrors["PROGRAMMATIC_SPEC_FIX"];
   // command_executor:CompilationError[]? userPromptRequiredErrors = categorizedErrors["USER_PROMPT_REQUIRED"];
    // command_executor:CompilationError[]? unsupportedErrors = categorizedErrors["UNSUPPORTED"];

    if redeclaredErrors is command_executor:CompilationError[] && redeclaredErrors.length() > 0 {
        io:println(string `Found ${redeclaredErrors.length()} more redeclared symbol errors. Continuing fixes...`);
        // Recursively continue fixing
        return processErrorCategories(categorizedErrors, flattenedSpecPath, outputDir);
    } //else if unsupportedErrors is command_executor:CompilationError[] && unsupportedErrors.length() > 0 {
    //     io:println(string `Found ${unsupportedErrors.length()} unsupported compilation errors.`);
    //     io:println("These errors cannot be fixed by modifying the OpenAPI specification.");
    //     io:print("Would you like to attempt fixing these errors in the generated Ballerina code using AI? (y/n): ");

    //     string? userInput = io:readln();
    //     if userInput is string && userInput.trim().toLowerAscii() == "y" {
    //         return processUnsupportedErrorsWithLLM(unsupportedErrors, outputDir);
    //     } else {
    //         io:println("Skipping LLM-based Ballerina code fixes.");
    //         io:println(string `Summary: ${unsupportedErrors.length()} unsupported errors remain:`);
    //         foreach int i in 0 ..< (unsupportedErrors.length() > 5 ? 5 : unsupportedErrors.length()) {
    //             command_executor:CompilationError err = unsupportedErrors[i];
    //             io:println(string `  • ${err.fileName}:${err.line}:${err.column} [${err.errorType}] ${err.message}`);
    //         }
    //         if unsupportedErrors.length() > 5 {
    //             io:println(string `  ... and ${unsupportedErrors.length() - 5} more errors`);
    //         }
    //     }
    // } else if userPromptRequiredErrors is command_executor:CompilationError[] && userPromptRequiredErrors.length() > 0 {
    //     io:println(string `Found ${userPromptRequiredErrors.length()} errors requiring user intervention:`);
    //     foreach int i in 0 ..< (userPromptRequiredErrors.length() > 5 ? 5 : userPromptRequiredErrors.length()) {
    //         command_executor:CompilationError err = userPromptRequiredErrors[i];
    //         io:println(string `  • ${err.fileName}:${err.line}:${err.column} [${err.errorType}] ${err.message}`);
    //     }
    //     if userPromptRequiredErrors.length() > 5 {
    //         io:println(string `  ... and ${userPromptRequiredErrors.length() - 5} more errors`);
    //     }
    // }
    else {
        io:println("No more redeclared symbol errors found.");
        io:println("All ERROR-level issues have been resolved!");

        // Show summary of remaining issues (likely warnings)
        if buildResult.compilationErrors.length() > 0 {
            io:println(string `${buildResult.compilationErrors.length()} remaining errors:`);
            int samplesToShow = buildResult.compilationErrors.length() > 5 ? 5 : buildResult.compilationErrors.length();
            foreach int i in 0 ..< samplesToShow {
                command_executor:CompilationError err = buildResult.compilationErrors[i];
                io:println(string `  • ${err.fileName}:${err.line}:${err.column} [${err.errorType}] ${err.message}`);
            }
            if buildResult.compilationErrors.length() > 5 {
                io:println(string `  ... and ${buildResult.compilationErrors.length() - 5} more issues`);
            }
        }

        log:printInfo("Redeclared symbol error fixing completed", remainingIssues = buildResult.compilationErrors.length());
    }
}

function processErrorCategories(map<command_executor:CompilationError[]> categorizedErrors, string flattenedSpecPath, string outputDir) returns error? {
    // Step 1: Process redeclared symbol errors programmatically first
    command_executor:CompilationError[]? redeclaredErrors = categorizedErrors["PROGRAMMATIC_SPEC_FIX"];
    if redeclaredErrors is command_executor:CompilationError[] && redeclaredErrors.length() > 0 {
        io:println(string `Fixing ${redeclaredErrors.length()} redeclared symbol errors programmatically...`);
        error_registry:BatchFixResult|error_registry:ErrorRegistryError batchResult = error_registry:applyBatchFixes(redeclaredErrors, flattenedSpecPath);
        if batchResult is error_registry:BatchFixResult {
            io:println(string `Fixed ${batchResult.fixedErrors}/${batchResult.totalErrors} redeclared symbol errors`);
            log:printInfo("Programmatic fixes applied", fixedCount = batchResult.fixedErrors);

            // After fixing errors in flattened spec, need to re-align, re-generate, and re-build
            return reprocessAfterFixes(flattenedSpecPath, outputDir);
        } else {
            log:printError("Failed to apply programmatic fixes", 'error = batchResult);
            return batchResult;
        }
    }

    // // Step 3: Handle unsupported errors that require LLM Ballerina code fixes
    // command_executor:CompilationError[]? unsupportedErrors = categorizedErrors["UNSUPPORTED"];
    // if unsupportedErrors is command_executor:CompilationError[] && unsupportedErrors.length() > 0 {
    //     io:println(string `Found ${unsupportedErrors.length()} unsupported compilation errors.`);
    //     io:println("These errors cannot be fixed by modifying the OpenAPI specification.");
    //     io:print("Would you like to attempt fixing these errors in the generated Ballerina code using AI? (y/n): ");

    //     string? userInput = io:readln();
    //     if userInput is string && userInput.trim().toLowerAscii() == "y" {
    //         return processUnsupportedErrorsWithLLM(unsupportedErrors, outputDir);
    //     } else {
    //         io:println("Skipping LLM-based Ballerina code fixes.");
    //         io:println(string `Summary: ${unsupportedErrors.length()} unsupported errors remain:`);
    //         foreach int i in 0 ..< (unsupportedErrors.length() > 5 ? 5 : unsupportedErrors.length()) {
    //             command_executor:CompilationError err = unsupportedErrors[i];
    //             io:println(string `  • ${err.fileName}:${err.line}:${err.column} [${err.errorType}] ${err.message}`);
    //         }
    //         if unsupportedErrors.length() > 5 {
    //             io:println(string `  ... and ${unsupportedErrors.length() - 5} more errors`);
    //         }
    //     }
    // }

    // Step 2: Process undocumented field warnings with LLM
    // command_executor:CompilationError[]? undocumentedFieldErrors = categorizedErrors["LLM_SPEC_FIX"];
    // if undocumentedFieldErrors is command_executor:CompilationError[] && undocumentedFieldErrors.length() > 0 {
    //     io:println(string `Found ${undocumentedFieldErrors.length()} undocumented field warnings. Processing with LLM...`);
    //     // Apply LLM-based spec fixes for undocumented fields
    //     error_registry:BatchFixResult|error_registry:ErrorRegistryError llmSpecResult = error_registry:applyBatchFixes(undocumentedFieldErrors, flattenedSpecPath);
    //     if llmSpecResult is error_registry:BatchFixResult {
    //         io:println(string `Fixed ${llmSpecResult.fixedErrors}/${llmSpecResult.totalErrors} undocumented field warnings`);
    //         log:printInfo("LLM spec fixes applied", fixedCount = llmSpecResult.fixedErrors);

    //         // Re-process after LLM spec fixes
    //         return reprocessAfterFixes(flattenedSpecPath, outputDir);
    //     } else {
    //         log:printError("Failed to apply LLM spec fixes", 'error = llmSpecResult);
    //         io:println("Failed to apply LLM spec fixes");
    //     }
    // }

    // If we reach here, no programmatic fixes were needed
    log:printInfo("No programmatic fixes needed");
    return;
}

// function processUnsupportedErrorsWithLLM(command_executor:CompilationError[] unsupportedErrors, string outputDir) returns error? {
//     io:println("Attempting to fix unsupported errors with LLM...");

//     string clientOutputPath = outputDir + "/ballerina";
//     string[] ballerinaFiles = ["types.bal", "client.bal", "utils.bal"];

//     // Collect error messages for LLM
//     string[] errorMessages = [];
//     foreach command_executor:CompilationError err in unsupportedErrors {
//         string errorMsg = string `${err.fileName}:${err.line}:${err.column} [${err.errorType}] ${err.message}`;
//         errorMessages.push(errorMsg);
//     }

//     // Try to fix each Ballerina file that has errors
//     foreach string fileName in ballerinaFiles {
//         string filePath = clientOutputPath + "/" + fileName;

//         // Check if this file has errors
//         command_executor:CompilationError[] fileErrors = [];
//         foreach command_executor:CompilationError err in unsupportedErrors {
//             if err.fileName.endsWith(fileName) {
//                 fileErrors.push(err);
//             }
//         }

//         if fileErrors.length() > 0 {
//             io:println(string `Fixing ${fileErrors.length()} errors in ${fileName}...`);

//             // Extract error messages for this file
//             string[] fileErrorMessages = [];
//             foreach command_executor:CompilationError err in fileErrors {
//                 string errorMsg = string `Line ${err.line}: ${err.message}`;
//                 fileErrorMessages.push(errorMsg);
//             }

//             // Apply LLM fixes
//             [boolean, string]|llm_service:LLMServiceError fixResult = llm_service:fixBallerinaCodeErrors(fileErrorMessages, filePath);
//             if fixResult is [boolean, string] {
//                 io:println(string `✓ ${fixResult[1]}`);
//                 log:printInfo("LLM Ballerina code fix applied", file = fileName, fixDescription = fixResult[1]);
//             } else {
//                 io:println(string `✗ Failed to fix ${fileName}: ${fixResult.message()}`);
//                 log:printError("LLM Ballerina code fix failed", file = fileName, 'error = fixResult);
//             }
//         }
//     }

//     // After applying LLM fixes, rebuild and check for remaining errors
//     io:println("Re-building project after LLM fixes...");
//     command_executor:CommandResult buildResult = command_executor:executeBalBuild(clientOutputPath);

//     if buildResult.compilationErrors.length() == 0 {
//         io:println("All compilation errors have been resolved with LLM fixes!");
//         log:printInfo("All errors resolved with LLM fixes");
//         return;
//     }

//     io:println(string `Found ${buildResult.compilationErrors.length()} remaining compilation errors after LLM fixes.`);
//     log:printInfo("Remaining errors after LLM fixes", errorCount = buildResult.compilationErrors.length());

//     // Check if we should iterate and try fixing again
//     map<command_executor:CompilationError[]> newCategorizedErrors = error_registry:routeErrorsByStrategy(buildResult.compilationErrors);
//     command_executor:CompilationError[]? newUnsupportedErrors = newCategorizedErrors["UNSUPPORTED"];

//     if newUnsupportedErrors is command_executor:CompilationError[] && newUnsupportedErrors.length() > 0 && newUnsupportedErrors.length() < unsupportedErrors.length() {
//         io:println("Some errors were fixed. Attempting another round of LLM fixes...");
//         return processUnsupportedErrorsWithLLM(newUnsupportedErrors, outputDir);
//     } else {
//         io:println("No further improvements possible with LLM fixes.");
//         io:println(string `Final summary: ${buildResult.compilationErrors.length()} errors remain:`);
//         foreach int i in 0 ..< (buildResult.compilationErrors.length() > 5 ? 5 : buildResult.compilationErrors.length()) {
//             command_executor:CompilationError err = buildResult.compilationErrors[i];
//             io:println(string `  • ${err.fileName}:${err.line}:${err.column} [${err.errorType}] ${err.message}`);
//         }
//         if buildResult.compilationErrors.length() > 5 {
//             io:println(string `  ... and ${buildResult.compilationErrors.length() - 5} more errors`);
//         }
//     }

//     return;
// }

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
