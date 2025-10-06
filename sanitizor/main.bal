import sanitizor.command_executor;
// import sanitizor.fixer;
// import sanitizor.spec_sanitizor;

import ballerina/io;
import ballerina/log;
import ballerina/regex;
import sanitizor.fixer;

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

    // Human acknowledgment: Show operation plan
    io:println("=== OpenAPI Sanitization Plan ===");
    io:println(string `Input OpenAPI spec: ${inputSpecPath}`);
    io:println(string `Output directory: ${outputDir}`);
    io:println("\nOperations to be performed:");
    io:println("1. Flatten OpenAPI specification");
    io:println("2. Align OpenAPI specification with Ballerina conventions");
    io:println("3. Rename inline response schemas using AI");
    io:println("4. Add missing field descriptions using AI");
    io:println("5. Generate Ballerina client code");
    io:println("6. Fix compilation errors using AI (if needed)");

    if !getUserConfirmation("\nProceed with sanitization?") {
        io:println("Operation cancelled by user.");
        return;
    }

    // // Initialize LLM service
    // spec_sanitizor:LLMServiceError? llmInitResult = spec_sanitizor:initLLMService();
    // if llmInitResult is spec_sanitizor:LLMServiceError {
    //     log:printError("Failed to initialize LLM service", 'error = llmInitResult);
    //     io:println("⚠ Warning: LLM service not available. Only programmatic fixes will be applied.");

    //     if !getUserConfirmation("Continue without AI-powered features?") {
    //         io:println("Operation cancelled. Please check your ANTHROPIC_API_KEY configuration.");
    //         return;
    //     }
    // } else {
    //     log:printInfo("LLM service initialized successfully");
    //     io:println("✓ LLM service initialized successfully");
    // }

    // // Step 1: Execute OpenAPI flatten
    // io:println("\n=== Step 1: Flattening OpenAPI Specification ===");
    // string flattenedSpecPath = outputDir + "/docs/spec";
    // command_executor:CommandResult flattenResult = command_executor:executeBalFlatten(inputSpecPath, flattenedSpecPath);
    // if !command_executor:isCommandSuccessfull(flattenResult) {
    //     log:printError("OpenAPI flatten failed", result = flattenResult);
    //     io:println("❌ Flatten operation failed:");
    //     io:println(flattenResult.stderr);

    //     if !getUserConfirmation("Continue despite flatten failure?") {
    //         return error("Flatten operation failed: " + flattenResult.stderr);
    //     }
    // } else {
    //     log:printInfo("OpenAPI spec flattened successfully", outputPath = flattenedSpecPath);
    //     io:println("✓ OpenAPI spec flattened successfully");
    //     showOperationSummary("Flatten", flattenResult);
    // }

    // // Step 2: Execute OpenAPI align on flattened spec
    // io:println("\n=== Step 2: Aligning OpenAPI Specification ===");
    // string alignedSpecPath = outputDir + "/docs/spec";
    // string flattenedSpec = flattenedSpecPath + "/flattened_openapi.json";
    // command_executor:CommandResult alignResult = command_executor:executeBalAlign(flattenedSpec, alignedSpecPath);
    // if !command_executor:isCommandSuccessfull(alignResult) {
    //     log:printError("OpenAPI align failed", result = alignResult);
    //     io:println("❌ Align operation failed:");
    //     io:println(alignResult.stderr);

    //     if !getUserConfirmation("Continue despite align failure?") {
    //         return error("Align operation failed: " + alignResult.stderr);
    //     }
    // } else {
    //     log:printInfo("OpenAPI spec aligned successfully");
    //     io:println("✓ OpenAPI spec aligned successfully");
    //     showOperationSummary("Align", alignResult);
    // }

    // // Step 3: Apply schema renaming fix on aligned spec (BATCH VERSION)
    // string alignedSpec = alignedSpecPath + "/aligned_ballerina_openapi.json";

    // io:println("\n=== Step 3: AI-Powered Schema Renaming ===");
    // io:println("This step will rename generic 'InlineResponse' schemas to meaningful names using AI.");
    // io:println("The AI will analyze the schema structure and usage context to suggest better names.");

    // if !getUserConfirmation("Proceed with AI-powered schema renaming?") {
    //     io:println("⚠ Skipping schema renaming. Generic schema names will be preserved.");
    // } else {
    //     io:println("🤖 Processing schema renaming with AI...");
    //     int|spec_sanitizor:LLMServiceError schemaRenameResult = spec_sanitizor:renameInlineResponseSchemasBatchWithRetry(
    //             alignedSpec,
    //             batchSize = 8 // Process 8 schemas per batch
    //     );
    //     if schemaRenameResult is spec_sanitizor:LLMServiceError {
    //         log:printError("Failed to rename InlineResponse schemas (batch)", 'error = schemaRenameResult);
    //         io:println("❌ Schema renaming failed:");
    //         io:println(schemaRenameResult.message());

    //         if !getUserConfirmation("Continue despite schema renaming failure?") {
    //             return error("Schema renaming failed: " + schemaRenameResult.message());
    //         }
    //     } else {
    //         log:printInfo("Batch schema renaming completed", schemasRenamed = schemaRenameResult);
    //         io:println(string `✓ Renamed ${schemaRenameResult} InlineResponse schemas to meaningful names`);

    //         if schemaRenameResult > 0 {
    //             if getUserConfirmation("Review the renamed schemas in the spec file?") {
    //                 io:println(string `You can check the updated schema names in: ${alignedSpec}`);
    //                 io:println("Press Enter to continue...");
    //                 _ = io:readln();
    //             }
    //         }
    //     }
    // }

    // // Step 4: Apply documentation fix on the same spec (BATCH VERSION)
    // io:println("\n=== Step 4: AI-Powered Documentation Enhancement ===");
    // io:println("This step will add meaningful descriptions to fields that are missing documentation.");
    // io:println("The AI will analyze field names, types, and context to generate appropriate descriptions.");

    // if !getUserConfirmation("Proceed with AI-powered documentation enhancement?") {
    //     io:println("⚠ Skipping documentation enhancement. Missing descriptions will remain.");
    // } else {
    //     io:println("🤖 Processing documentation enhancement with AI...");
    //     int|spec_sanitizor:LLMServiceError descriptionsResult = spec_sanitizor:addMissingDescriptionsBatchWithRetry(
    //             alignedSpec,
    //             batchSize = 15 // Process 15 items per batch
    //     );
    //     if descriptionsResult is spec_sanitizor:LLMServiceError {
    //         log:printError("Failed to add missing descriptions (batch)", 'error = descriptionsResult);
    //         io:println("❌ Documentation enhancement failed:");
    //         io:println(descriptionsResult.message());

    //         if !getUserConfirmation("Continue despite documentation enhancement failure?") {
    //             return error("Documentation fix failed: " + descriptionsResult.message());
    //         }
    //     } else {
    //         log:printInfo("Batch documentation fix completed", descriptionsAdded = descriptionsResult);
    //         io:println(string `✓ Added ${descriptionsResult} missing field descriptions`);

    //         if descriptionsResult > 0 {
    //             if getUserConfirmation("Review the enhanced documentation in the spec file?") {
    //                 io:println(string `You can check the updated descriptions in: ${alignedSpec}`);
    //                 io:println("Press Enter to continue...");
    //                 _ = io:readln();
    //             }
    //         }
    //     }
    // }

    // // Step 5: Generate Ballerina client from the final sanitized spec
    // io:println("\n=== Step 5: Generating Ballerina Client ===");
    string clientOutputPath = outputDir + "/ballerina";
    // io:println(string `Generating Ballerina client code to: ${clientOutputPath}`);

    // if !getUserConfirmation("Proceed with Ballerina client generation?") {
    //     io:println("⚠ Skipping client generation.");
    //     io:println("✓ OpenAPI sanitization completed successfully (without client generation)");
    //     return;
    // }

    // command_executor:CommandResult generateResult = command_executor:executeBalClientGenerate(alignedSpec, clientOutputPath);
    // if !command_executor:isCommandSuccessfull(generateResult) {
    //     log:printError("Client generation failed", result = generateResult);
    //     io:println("❌ Client generation failed:");
    //     io:println(generateResult.stderr);

    //     if !getUserConfirmation("Continue to error fixing despite client generation failure?") {
    //         return error("Client generation failed: " + generateResult.stderr);
    //     }
    // } else {
    //     log:printInfo("Ballerina client generated successfully", outputPath = clientOutputPath);
    //     io:println("✓ Ballerina client generated successfully");
    //     showOperationSummary("Client Generation", generateResult);
    // }

    io:println("\n=== Step 6: AI-Powered Error Fixing (Optional) ===");
    io:println("This step will attempt to automatically fix any compilation errors in the generated Ballerina code.");

    if getUserConfirmation("Run AI-powered error fixing on the generated client?") {
        io:println("🤖 Checking and fixing Ballerina compilation errors...");

       
        fixer:FixResult|fixer:BallerinaFixerError fixResult = fixer:fixAllErrors(clientOutputPath);

        if fixResult is fixer:FixResult {
            if fixResult.success {
                io:println(string `✓ AI successfully fixed ${fixResult.errorsFixed} compilation errors!`);
                io:println("✓ All Ballerina files compile without errors!");
            } else {
                io:println(string `⚠ AI fixed ${fixResult.errorsFixed} errors, but ${fixResult.errorsRemaining} errors remain`);
                io:println("⚠ Some errors may require manual intervention");
                log:printWarn("Some compilation errors could not be automatically fixed",
                        remainingErrors = fixResult.errorsRemaining);
            }
            if fixResult.appliedFixes.length() > 0 {
                io:println("Applied AI fixes:");
                foreach string fix in fixResult.appliedFixes {
                    io:println(string `  - ${fix}`);
                }
            }
        } else {
            log:printError("Failed to fix Ballerina compilation errors", 'error = fixResult);
            io:println("⚠ Warning: AI-powered error fixing failed. Manual intervention may be required.");
        }

        io:println("⚠ Error fixing module is currently disabled. Please manually check for compilation errors.");
    } else {
        io:println("⚠ Skipping error fixing. Please manually check the generated Ballerina code for compilation errors.");
    }

    // Sanitization completed successfully
    log:printInfo("Batch processing sanitization completed successfully");
    io:println("\n🎉 OpenAPI Sanitization completed successfully!");
    return;
}

// Helper function to get user confirmation
function getUserConfirmation(string message) returns boolean {
    io:print(string `${message} (y/n): `);
    string|io:Error userInput = io:readln();
    if userInput is io:Error {
        log:printError("Failed to read user input", 'error = userInput);
        return false;
    }
    string trimmedInput = userInput.trim().toLowerAscii();
    return trimmedInput == "y" || trimmedInput == "yes";
}

// Helper function to show operation summary
function showOperationSummary(string operationName, command_executor:CommandResult result) {
    io:println(string `  ⏱ Execution time: ${result.executionTime} seconds`);
    if result.stdout.length() > 0 {
        io:println("  📝 Output summary:");
        string[] lines = regex:split(result.stdout, "\n");
        int maxLines = lines.length() > 3 ? 3 : lines.length();
        foreach int i in 0 ..< maxLines {
            io:println(string `     ${lines[i]}`);
        }
        if lines.length() > 3 {
            io:println(string `     ... (${lines.length() - 3} more lines)`);
        }
    }
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
    io:println("");
    io:println("Interactive Features:");
    io:println("  • Step-by-step confirmation for each operation");
    io:println("  • Review AI-generated changes before applying");
    io:println("  • Continue/skip options for failed operations");
    io:println("  • Progress feedback and operation summaries");
}

// import sanitizor.fixer;

// import ballerina/io;
// import ballerina/log;

// public function main(string... args) returns error? {
//     if args.length() < 1 {
//         printCodeFixerUsage();
//         return;
//     }

//     string projectPath = args[0];

//     log:printInfo("Starting Ballerina code fixer", projectPath = projectPath);
//     io:println("Starting AI-powered Ballerina code fixer...");

//     fixer:FixResult|fixer:BallerinaFixerError result =
//         fixer:fixAllErrors(projectPath);

//     if result is fixer:FixResult {
//         if result.success {
//             io:println("All compilation errors fixed successfully!");
//             io:println(string `Fixed ${result.errorsFixed} errors`);
//         } else {
//             io:println("Partial success:");
//             io:println(string `Fixed ${result.errorsFixed} errors`);
//             io:println(string `${result.errorsRemaining} errors remain`);
//             // io:println("\nRemaining errors that need manual fixing:");
//             // foreach string err in result.errorsRemaining {
//             //     io:println(string `   • ${err}`);
//             // }
//         }

//         if result.appliedFixes.length() > 0 {
//             io:println("\n Applied fixes:");
//             foreach string fix in result.appliedFixes {
//                 io:println(string `   • ${fix}`);
//             }
//         }
//     } else {
//         log:printError("Code fixer failed", 'error = result);
//         io:println("Code fixing failed. Please check logs for details.");
//         return result;
//     }
// }

// function printCodeFixerUsage() {
//     io:println("Ballerina AI Code Fixer");
//     io:println("Usage: bal run code_fixer_cli.bal -- <project-path>");
//     io:println("");
//     io:println("Environment Variables:");
//     io:println("  ANTHROPIC_API_KEY: Required for AI-powered fixes");
//     io:println("");
//     io:println("Example:");
//     io:println("  bal run code_fixer_cli.bal -- ./my-ballerina-project");
// }
