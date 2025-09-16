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

    if redeclaredErrors is command_executor:CompilationError[] && redeclaredErrors.length() > 0 {
        io:println(string `Found ${redeclaredErrors.length()} more redeclared symbol errors. Continuing fixes...`);
        // Recursively continue fixing
        return processErrorCategories(categorizedErrors, flattenedSpecPath, outputDir);
    } else {
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
    // Process redeclared symbol errors programmatically in a loop
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
            io:println("Failed to apply programmatic fixes");
            return batchResult;
        }
    }

    io:println("No redeclared symbol errors found to fix.");
    log:printInfo("No programmatic fixes needed");
    return;
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
