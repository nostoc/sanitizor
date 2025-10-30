import connector_automator.client_generator;
import connector_automator.code_fixer;
import connector_automator.doc_generator;
import connector_automator.example_generator;
import connector_automator.sanitizor;
import connector_automator.test_generator;

import ballerina/io;
import ballerina/os;

public function main(string... args) returns error? {
    // Check for API key
    string|error apiKey = os:getEnv("ANTHROPIC_API_KEY");
    if apiKey is error {
        io:println("⚠ Warning: ANTHROPIC_API_KEY environment variable not set.");
        io:println("AI-powered features will not work.");
        io:println("");
    }

    // If arguments are provided, use command-line mode
    if args.length() > 0 {
        return handleCommandLineMode(args);
    }

    // Interactive mode
    return handleInteractiveMode();
}

function handleCommandLineMode(string[] args) returns error? {
    string command = args[0];
    string[] remainingArgs = args.slice(1);

    match command {
        "sanitize" => {
            return sanitizor:main(...remainingArgs);
        }
        "generate-client" => {
            return client_generator:main(...remainingArgs);
        }
        "generate-examples" => {
            return example_generator:main(...remainingArgs);
        }
        "generate-tests" => {
            return example_generator:main(...remainingArgs);
        }
        "generate-docs" => {
            return doc_generator:main(...remainingArgs);
        }
        "fix-code" => {
            return code_fixer:main(...remainingArgs);
        }
        "pipeline" => {
            return runFullPipeline(...remainingArgs);
        }
        "help"|"--help"|"-h" => {
            printUsage();
        }
        _ => {
            io:println("Error: Unknown command '" + command + "'");
            printUsage();
            return error("Invalid command: " + command);
        }
    }
}

function handleInteractiveMode() returns error? {
    while true {
        showMainMenu();

        string|io:Error userChoice = getUserInput("\nSelect an option (1-7): ");
        if userChoice is io:Error {
            io:println("Error reading input. Please try again.");
            continue;
        }

        string choice = userChoice.trim();

        match choice {
            "1" => {
                error? result = handleSanitizeOperation();
                if result is error {
                    io:println("Operation failed: " + result.message());
                }
            }
            "2" => {
                error? result = handleClientGeneration();
                if result is error {
                    io:println("Operation failed: " + result.message());
                }
            }
            "3" => {
                error? result = handleExampleGeneration();
                if result is error {
                    io:println("Operation failed: " + result.message());
                }
            }
            "4" => {
                error? result = handleTestGeneration();
                if result is error {
                    io:println("Operation failed: " + result.message());
                }
            }
            "5" => {
                error? result = handleDocGeneration();
                if result is error {
                    io:println("Operation failed: " + result.message());
                }
            }
            "6" => {
                error? result = handleCodeFixer();
                if result is error {
                    io:println("Operation failed: " + result.message());
                }
            }
            "7" => {
                error? result = handleFullPipeline();
                if result is error {
                    io:println("Operation failed: " + result.message());
                }
            }
            "8" => {
                printUsage();
            }
            "9" => {
                io:println("Thank you for using Connector Automation CLI!");
                return;
            }
            _ => {
                io:println("Invalid choice. Please select a number between 1-7.");
            }
        }

        if !getUserConfirmation("\nWould you like to perform another operation?") {
            io:println("Thank you for using Connector Automation CLI!");
            break;
        }
    }
}

function showMainMenu() {
    // Build a separator line of 50 '=' characters since string has no .repeat method
    string sep = "";
    int i = 0;
    while i < 50 {
        sep += "=";
        i += 1;
    }

    io:println("\n" + sep);
    io:println("    CONNECTOR AUTOMATION CLI");
    io:println(sep);
    io:println("1. Sanitize OpenAPI Specification");
    io:println("   • Flatten and align OpenAPI spec");
    io:println("   • Add missing operationIds and descriptions");
    io:println("   • AI-powered schema improvements");
    io:println("");
    io:println("2. Generate Ballerina Client");
    io:println("   • Generate client from sanitized OpenAPI spec");
    io:println("   • Create proper project structure");
    io:println("   • Validate generated code");
    io:println("");
    io:println("3. Generate Examples");
    io:println("   • Create usage examples for connector");
    io:println("   • AI-powered example generation");
    io:println("   • Fix compilation errors automatically");
    io:println("");
    io:println("4. Generate test cases");
    io:println("   • AI-powered test generation");
    io:println("   • Ensure high test coverage");
    io:println("");
    io:println("5. Generate Documentation");
    io:println("   • Create README files");
    io:println("   • Documentation for modules and examples");
    io:println("   • AI-powered content generation");
    io:println("");
    io:println("6. Fix Code Errors");
    io:println("   • Analyze compilation errors");
    io:println("   • AI-powered error fixing");
    io:println("   • Iterative error resolution");
    io:println("");
    io:println("7. Full Pipeline");
    io:println("   • Complete automation workflow");
    io:println("   • All operations in sequence");
    io:println("   • End-to-end processing");
    io:println("");
    io:println("8. Help & Usage Information");
    io:println("");
    io:println("9. Exit");
    io:println(sep);
}

function handleSanitizeOperation() returns error? {
    io:println("\n=== OpenAPI Sanitization ===");
    io:println("This operation will:");
    io:println("• Flatten your OpenAPI specification");
    io:println("• Align it with Ballerina conventions");
    io:println("• Add missing operationIds using AI");
    io:println("");

    string|io:Error inputSpec = getUserInput("Enter path to OpenAPI specification file: ");
    if inputSpec is io:Error {
        return error("Failed to read input specification path");
    }

    string|io:Error outputDir = getUserInput("Enter output directory path: ");
    if outputDir is io:Error {
        return error("Failed to read output directory path");
    }

    boolean autoYes = getUserConfirmation("Auto-confirm all prompts during execution?");
    boolean quietMode = getUserConfirmation("Enable quiet mode (reduced logging)?");

    string[] args = [inputSpec.trim(), outputDir.trim()];
    if autoYes {
        args.push("yes");
    }
    if quietMode {
        args.push("quiet");
    }

    return sanitizor:main(...args);
}

function handleClientGeneration() returns error? {
    io:println("\n=== Ballerina Client Generation ===");
    io:println("This operation will:");
    io:println("• Generate Ballerina client from OpenAPI specification");
    io:println("• Create proper project structure with dependencies");
    io:println("• Validate generated code structure");
    io:println("");

    string|io:Error specPath = getUserInput("Enter path to OpenAPI specification file: ");
    if specPath is io:Error {
        return error("Failed to read specification path");
    }

    string|io:Error outputDir = getUserInput("Enter output directory path: ");
    if outputDir is io:Error {
        return error("Failed to read output directory path");
    }

    // Ask for optional configurations
    boolean autoYes = getUserConfirmation("Auto-confirm all prompts during execution?");
    boolean quietMode = getUserConfirmation("Enable quiet mode (reduced logging)?");

    // Ask for client method type
    io:println("\nClient Method Type:");
    io:println("1. Resource methods (default, recommended)");
    io:println("2. Remote methods");
    string|io:Error methodChoice = getUserInput("Select client method type (1-2, default=1): ");
    string clientMethodArg = "resource-methods";
    if methodChoice is string && methodChoice.trim() == "2" {
        clientMethodArg = "remote-methods";
    }

    // Ask for optional configurations
    boolean wantAdvanced = getUserConfirmation("Configure advanced options (license, tags, operations)?");

    string[] args = [specPath.trim(), outputDir.trim()];
    if autoYes {
        args.push("yes");
    }
    if quietMode {
        args.push("quiet");
    }
    args.push(clientMethodArg);

    if wantAdvanced {
        // License file
        string|io:Error licenseInput = getUserInput("Enter license file path (press Enter to skip): ");
        if licenseInput is string && licenseInput.trim().length() > 0 {
            args.push(string `license=${licenseInput.trim()}`);
        }

        // Tags
        string|io:Error tagsInput = getUserInput("Enter tags to filter (comma-separated, press Enter to skip): ");
        if tagsInput is string && tagsInput.trim().length() > 0 {
            args.push(string `tags=${tagsInput.trim()}`);
        }

        // Operations
        string|io:Error operationsInput = getUserInput("Enter specific operations (comma-separated, press Enter to skip): ");
        if operationsInput is string && operationsInput.trim().length() > 0 {
            args.push(string `operations=${operationsInput.trim()}`);
        }
    }

    return client_generator:main(...args);
}

function handleExampleGeneration() returns error? {
    io:println("\n=== Example Generation ===");
    io:println("This operation will:");
    io:println("• Analyze your connector structure");
    io:println("• Generate realistic usage examples");
    io:println("• Fix compilation errors automatically");
    io:println("");

    string|io:Error connectorPath = getUserInput("Enter path to connector directory: ");
    if connectorPath is io:Error {
        return error("Failed to read connector path");
    }

    return example_generator:main(connectorPath.trim());
}

function handleTestGeneration() returns error? {
    io:println("\n=== Test Generation ===");
    io:println("This operation will:");
    io:println("• Set up mock server module");
    io:println("• Generate mock server implementation");
    io:println("• Create comprehensive tests for the connector");
    io:println("");

    string|io:Error connectorPath = getUserInput("Enter path to connector directory: ");
    if connectorPath is io:Error {
        return error("Failed to read connector path");
    }

    string|io:Error specPath = getUserInput("Enter path to openAPI spec: ");
    if specPath is io:Error {
        return error("Failed to read openAPI spec path");
    }

    string[] args = [connectorPath.trim(), specPath.trim()];

    return test_generator:main(...args);
}

function handleDocGeneration() returns error? {
    io:println("\n=== Documentation Generation ===");
    io:println("Select documentation type to generate:");
    io:println("1. Generate all README files");
    io:println("2. Generate Ballerina module README");
    io:println("3. Generate Tests README");
    io:println("4. Generate Examples README");
    io:println("5. Generate Individual Example READMEs");
    io:println("6. Generate Main/Root README");
    io:println("");

    string|io:Error docChoice = getUserInput("Select documentation type (1-6): ");
    if docChoice is io:Error {
        return error("Failed to read documentation choice");
    }

    string command = "";
    match docChoice.trim() {
        "1" => {
            command = "generate-all";
        }
        "2" => {
            command = "generate-ballerina";
        }
        "3" => {
            command = "generate-tests";
        }
        "4" => {
            command = "generate-examples";
        }
        "5" => {
            command = "generate-individual-examples";
        }
        "6" => {
            command = "generate-main";
        }
        _ => {
            return error("Invalid documentation type selection");
        }
    }

    string|io:Error connectorPath = getUserInput("Enter path to connector directory: ");
    if connectorPath is io:Error {
        return error("Failed to read connector path");
    }

    boolean autoYes = getUserConfirmation("Auto-confirm all prompts during execution?");
    boolean quietMode = getUserConfirmation("Enable quiet mode (reduced logging)?");

    string[] args = [command, connectorPath.trim()];
    if autoYes {
        args.push("yes");
    }
    if quietMode {
        args.push("quiet");
    }

    return doc_generator:main(...args);
}

function handleCodeFixer() returns error? {
    io:println("\n=== Code Error Fixing ===");
    io:println("This operation will:");
    io:println("• Analyze Ballerina compilation errors");
    io:println("• Generate AI-powered fixes");
    io:println("• Apply fixes with confirmation");
    io:println("");

    string|io:Error projectPath = getUserInput("Enter path to Ballerina project directory: ");
    if projectPath is io:Error {
        return error("Failed to read project path");
    }

    boolean autoYes = getUserConfirmation("Auto-confirm all fixes during execution?");
    boolean quietMode = getUserConfirmation("Enable quiet mode (reduced logging)?");

    string[] args = [projectPath.trim()];
    if autoYes {
        args.push("yes");
    }
    if quietMode {
        args.push("quiet");
    }

    return code_fixer:main(...args);
}

function handleFullPipeline() returns error? {
    io:println("\n=== Full Automation Pipeline ===");
    io:println("This will execute the complete workflow:");
    io:println("1. Sanitize OpenAPI specification");
    io:println("2. Generate Ballerina client");
    io:println("3. Fix compilation errors");
    io:println("4. Generate examples");
    io:println("5. Generate documentation");
    io:println("");

    string|io:Error openApiSpec = getUserInput("Enter path to OpenAPI specification file: ");
    if openApiSpec is io:Error {
        return error("Failed to read OpenAPI specification path");
    }

    string|io:Error outputDir = getUserInput("Enter output directory path: ");
    if outputDir is io:Error {
        return error("Failed to read output directory path");
    }

    boolean autoYes = getUserConfirmation("Auto-confirm all prompts during pipeline execution?");

    string[] args = [openApiSpec.trim(), outputDir.trim()];
    if autoYes {
        args.push("yes");
    }

    return runFullPipeline(...args);
}

function getUserInput(string prompt) returns string|io:Error {
    io:print(prompt);
    return io:readln();
}

function getUserConfirmation(string message) returns boolean {
    io:print(string `${message} (y/n): `);
    string|io:Error userInput = io:readln();
    if userInput is io:Error {
        return false;
    }
    string trimmedInput = userInput.trim().toLowerAscii();
    return trimmedInput == "y" || trimmedInput == "yes";
}

function runFullPipeline(string... args) returns error? {
    if args.length() < 2 {
        io:println("Error: Full pipeline requires OpenAPI spec path and output directory");
        io:println("Usage: bal run -- pipeline <openapi-spec> <output-dir> [options]");
        return;
    }

    string openApiSpec = args[0];
    string outputDir = args[1];
    string[] pipelineOptions = args.slice(2);

    io:println("=== Connector Automation Pipeline ===");
    io:println(string `OpenAPI Spec: ${openApiSpec}`);
    io:println(string `Output Directory: ${outputDir}`);
    io:println("\nPipeline Steps:");
    io:println("1. Sanitize OpenAPI specification");
    io:println("2. Generate Ballerina client");
    io:println("3. Fix compilation errors");
    io:println("4. Generate examples");
    io:println("5. Generate documentation");

    if !getUserConfirmation("\nProceed with full pipeline?") {
        io:println("Operation cancelled by user.");
        return;
    }

    // Step 1: Sanitize OpenAPI spec
    io:println("\n=== Step 1: Sanitizing OpenAPI Specification ===");
    string[] sanitizeArgs = [openApiSpec, outputDir];
    sanitizeArgs.push(...pipelineOptions);
    error? sanitizeResult = sanitizor:main(...sanitizeArgs);
    if sanitizeResult is error {
        io:println("Pipeline failed at sanitization step: " + sanitizeResult.message());
        return sanitizeResult;
    }

    // Step 2: Generate Ballerina client
    io:println("\n=== Step 2: Generating Ballerina Client ===");
    string sanitizedSpec = outputDir + "/docs/spec/aligned_ballerina_openapi.json";
    string clientPath = outputDir + "/ballerina";
    string[] clientArgs = [sanitizedSpec, clientPath];
    clientArgs.push(...pipelineOptions);
    error? clientResult = client_generator:main(...clientArgs);
    if clientResult is error {
        io:println("Warning: Client generation failed: " + clientResult.message());
        io:println("Continuing with pipeline...");
    }

    // Step 3: Fix any compilation errors in generated client
    io:println("\n=== Step 3: Fixing Compilation Errors ===");
    string[] fixArgs = [clientPath];
    fixArgs.push(...pipelineOptions);
    error? fixResult = code_fixer:main(...fixArgs);
    if fixResult is error {
        io:println("Warning: Code fixing failed: " + fixResult.message());
        io:println("Continuing with pipeline...");
    }

    // Step 4: Generate examples
    io:println("\n=== Step 4: Generating Examples ===");
    string[] exampleArgs = [clientPath];
    error? exampleResult = example_generator:main(...exampleArgs);
    if exampleResult is error {
        io:println("Warning: Example generation failed: " + exampleResult.message());
        io:println("Continuing with pipeline...");
    }

    // Step 5: Generate documentation
    io:println("\n=== Step 5: Generating Documentation ===");
    string[] docArgs = ["generate-all", clientPath];
    docArgs.push(...pipelineOptions);
    error? docResult = doc_generator:main(...docArgs);
    if docResult is error {
        io:println("Warning: Documentation generation failed: " + docResult.message());
    }

    io:println("\n=== Pipeline Completed Successfully! ===");
    io:println("Generated files are available in: " + outputDir);
    return;
}

function printUsage() {
    io:println("Connector Automation CLI");
    io:println("");
    io:println("Usage: bal run -- <command> [arguments...]");
    io:println("");
    io:println("Commands:");
    io:println("  sanitize <openapi-spec> <output-dir> [options]");
    io:println("    Sanitize OpenAPI specification with AI enhancements");
    io:println("");
    io:println("  generate-client <openapi-spec> <output-dir> [options]");
    io:println("    Generate Ballerina client from OpenAPI specification");
    io:println("");
    io:println("  generate-examples <connector-path>");
    io:println("    Generate example code for the connector");
    io:println("");
    io:println("  generate-docs <command> <connector-path> [options]");
    io:println("    Generate documentation (README files)");
    io:println("    Commands: generate-all, generate-ballerina, generate-tests, etc.");
    io:println("");
    io:println("  fix-code <project-path> [options]");
    io:println("    Fix compilation errors using AI");
    io:println("");
    io:println("  pipeline <openapi-spec> <output-dir> [options]");
    io:println("    Run the complete automation pipeline");
    io:println("");
    io:println("  help");
    io:println("    Show this help message");
    io:println("");
    io:println("Options:");
    io:println("  yes      Auto-confirm all prompts");
    io:println("  quiet    Reduce logging output");
    io:println("");
    io:println("Examples:");
    io:println("  bal run -- sanitize ./openapi.yaml ./output");
    io:println("  bal run -- generate-client ./aligned_spec.json ./client");
    io:println("  bal run -- generate-examples ./output/ballerina");
    io:println("  bal run -- generate-docs generate-all ./output/ballerina");
    io:println("  bal run -- fix-code ./output/ballerina");
    io:println("  bal run -- pipeline ./openapi.yaml ./output yes");
    io:println("");
    io:println("Environment Variables:");
    io:println("  ANTHROPIC_API_KEY    Required for AI-powered features");
}
