import sanitizor.command_executor;
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
    string outputDir = args[1]; // /home/hansika/dev/sanitizor/temp-workspace

    log:printInfo("Processing OpenAPI spec", inputSpec = inputSpecPath, outputDir = outputDir);

    // Initialize LLM service
    llm_service:LLMServiceError? llmInitResult = llm_service:initLLMService();
    if llmInitResult is llm_service:LLMServiceError {
        log:printError("Failed to initialize LLM service", 'error = llmInitResult);
        io:println("Warning: LLM service not available. Only programmatic fixes will be applied.");
    } else {
        log:printInfo("LLM service initialized successfully");
    }

    // Step 1: Execute OpenAPI flatten
    string flattenedSpecPath = outputDir + "/docs/spec";
    command_executor:CommandResult flattenResult = command_executor:executeBalFlatten(inputSpecPath, flattenedSpecPath);
    if !command_executor:isCommandSuccessfull(flattenResult) {
        log:printError("OpenAPI flatten failed", result = flattenResult);
        return error("Flatten operation failed: " + flattenResult.stderr);
    }
    log:printInfo("OpenAPI spec flattened successfully", outputPath = flattenedSpecPath);

    // Step 2: Execute OpenAPI align on flattened spec
    string alignedSpecPath = outputDir + "/docs/spec";
    string flattenedSpec = flattenedSpecPath + "/flattened_openapi.json";
    command_executor:CommandResult alignResult = command_executor:executeBalAlign(flattenedSpec, alignedSpecPath);
    if !command_executor:isCommandSuccessfull(alignResult) {
        log:printError("OpenAPI align failed", result = alignResult);
        return error("Align operation failed: " + alignResult.stderr);
    }
    log:printInfo("OpenAPI spec aligned successfully", outputPath = alignedSpecPath);

    // Step 3: Apply schema renaming fix on aligned spec
    string alignedSpec = alignedSpecPath + "/aligned_ballerina_openapi.json";
    int|llm_service:LLMServiceError schemaRenameResult = llm_service:renameInlineResponseSchemas(alignedSpec);
    if schemaRenameResult is llm_service:LLMServiceError {
        log:printError("Failed to rename InlineResponse schemas", 'error = schemaRenameResult);
        return error("Schema renaming failed: " + schemaRenameResult.message());
    }
    log:printInfo("Schema renaming completed", schemasRenamed = schemaRenameResult);
    io:println(string `✓ Renamed ${schemaRenameResult} InlineResponse schemas to meaningful names`);

    // Step 4: Apply documentation fix on the same spec (now with schema renaming applied)
    int|llm_service:LLMServiceError descriptionsResult = llm_service:addMissingDescriptions(alignedSpec);
    if descriptionsResult is llm_service:LLMServiceError {
        log:printError("Failed to add missing descriptions", 'error = descriptionsResult);
        return error("Documentation fix failed: " + descriptionsResult.message());
    }
    log:printInfo("Documentation fix completed", descriptionsAdded = descriptionsResult);
    io:println(string `✓ Added ${descriptionsResult} missing field descriptions`);

    // Step 5: Align the final spec again after applying LLM fixes
    command_executor:CommandResult finalAlignResult = command_executor:executeBalAlign(alignedSpec, alignedSpecPath);
    if !command_executor:isCommandSuccessfull(finalAlignResult) {
        log:printError("Failed to align final spec", alignResult = finalAlignResult);
        return error("Final OpenAPI align command failed: " + finalAlignResult.stderr);
    }
    log:printInfo("Final spec alignment completed successfully", outputPath = alignedSpecPath);

    // Step 6: Generate Ballerina client from the final sanitized spec
    string clientOutputPath = outputDir + "/ballerina";
    command_executor:CommandResult generateResult = command_executor:executeBalClientGenerate(alignedSpec, clientOutputPath);
    if !command_executor:isCommandSuccessfull(generateResult) {
        log:printError("Client generation failed", result = generateResult);
        return error("Client generation failed: " + generateResult.stderr);
    }
    log:printInfo("Ballerina client generated successfully", outputPath = clientOutputPath);

    // io:println("✓ Checking and fixing Ballerina compilation errors...");

    // // step 7

    // ballerina_fixer:BallerinaFixResult|ballerina_fixer:BallerinaFixerError fixResult =
    // ballerina_fixer:fixAllBallerinaErrors(clientOutputPath);

    // if fixResult is ballerina_fixer:BallerinaFixResult {
    //     if fixResult.success {
    //         io:println(string `✓ AI successfully fixed ${fixResult.errorsFixed} compilation errors!`);
    //         io:println("✓ All Ballerina files compile without errors!");
    //     } else {
    //         io:println(string `⚠ AI fixed ${fixResult.errorsFixed} errors, but ${fixResult.errorsRemaining} errors remain`);
    //         io:println("⚠ Some errors may require manual intervention");
    //         log:printWarn("Some compilation errors could not be automatically fixed",
    //                 remainingErrors = fixResult.errorsRemaining);
    //     }

    //     if fixResult.appliedFixes.length() > 0 {
    //         io:println("Applied AI fixes:");
    //         foreach string fix in fixResult.appliedFixes {
    //             io:println(string `  - ${fix}`);
    //         }
    //     }
    // } else {
    //     log:printError("Failed to fix Ballerina compilation errors", 'error = fixResult);
    //     io:println("⚠ Warning: AI-powered error fixing failed. Manual intervention may be required.");
    // }

    // Sanitization completed successfully
    io:println("✓ All processing completed successfully!");
    io:println("✓ OpenAPI spec has been sanitized and Ballerina client generated!");
    log:printInfo("Sanitization completed successfully");
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
