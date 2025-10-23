import ballerina/io;
import ballerina/log;

// Import from sanitizor module for command execution functions
import connector_automator.sanitizor;

public function main(string... args) returns error? {
    if args.length() < 2 {
        printUsage();
        return;
    }

    string inputSpecPath = args[0]; // Path to OpenAPI spec (aligned)
    string outputDir = args[1]; // Output directory for client

    // Check for auto flag for automated mode and quiet mode for log control
    boolean autoYes = false;
    boolean quietMode = false;
    foreach string arg in args {
        if arg == "yes" {
            autoYes = true;
        } else if arg == "quiet" {
            quietMode = true;
        }
    }

    if autoYes {
        if !quietMode {
            io:println("Running in automated mode - all prompts will be auto-confirmed");
        }
    }

    if quietMode {
        if !autoYes {
            io:println("Running in quiet mode - reduced logging output");
        }
        io:println("Quiet mode enabled - minimal logging output");
    }

    if !quietMode {
        log:printInfo("Starting Ballerina client generation", inputSpec = inputSpecPath, outputDir = outputDir);
    }

    return generateBallerinaClient(inputSpecPath, outputDir, autoYes, quietMode);
}

# Generate Ballerina client from OpenAPI specification
#
# + specPath - Path to the OpenAPI specification file
# + outputDir - Output directory for generated client
# + autoYes - Auto-confirm all prompts
# + quietMode - Reduce logging output
# + return - Error if generation fails, () if successful
public function generateBallerinaClient(string specPath, string outputDir, boolean autoYes = false, boolean quietMode = false) returns error? {
    io:println("\n=== Ballerina Client Generation ===");
    io:println(string `Input OpenAPI spec: ${specPath}`);
    io:println(string `Output directory: ${outputDir}`);
    io:println("\nOperations to be performed:");
    io:println("• Generate Ballerina client code from OpenAPI specification");
    io:println("• Create project structure with proper dependencies");
    io:println("• Validate generated code structure");
    io:println("");

    if !getUserConfirmation("Proceed with Ballerina client generation?", autoYes) {
        io:println("⚠ Skipping client generation.");
        return;
    }

    io:println("Generating Ballerina client code...");
    
    CommandResult generateResult = executeBalClientGenerate(specPath, outputDir);
    
    if !isCommandSuccessfull(generateResult) {
        if !quietMode {
            log:printError("Client generation failed", result = generateResult);
        }
        io:println("Client generation failed:");
        io:println(generateResult.stderr);
        
        if generateResult.compilationErrors.length() > 0 {
            io:println("\nCompilation errors found:");
            foreach CompilationError err in generateResult.compilationErrors {
                io:println(string `  • ${err.fileName}:${err.line}:${err.column} - ${err.message}`);
            }
        }

        return error("Client generation failed: " + generateResult.stderr);
    } else {
        if !quietMode {
            log:printInfo("Ballerina client generated successfully", outputPath = outputDir);
        }
        io:println("Ballerina client generated successfully");
        
              
        io:println(string `Generated files are available in: ${outputDir}`);
        
        // Show next steps
        io:println("\nNext Steps:");
        io:println("• Review the generated client code");
        io:println("• Run 'bal build' to check for compilation errors");
        io:println("• Use the code fixer if there are any compilation issues");
        io:println("• Generate examples to test the client functionality");
    }

    return ();
}

// Helper function to get user confirmation
function getUserConfirmation(string message, boolean autoYes = false) returns boolean {
    if autoYes {
        io:println(string `${message} (y/n): y [auto-confirmed]`);
        return true;
    }

    io:print(string `${message} (y/n): `);
    string|io:Error userInput = io:readln();
    if userInput is io:Error {
        log:printError("Failed to read user input", 'error = userInput);
        return false;
    }
    string trimmedInput = userInput.trim().toLowerAscii();
    return trimmedInput == "y" || trimmedInput == "Y" || trimmedInput == "yes";
}

function printUsage() {
    io:println("Ballerina Client Generator");
    io:println("");
    io:println("Usage: bal run client_generator -- <openapi-spec> <output-directory> [options]");
    io:println("  <openapi-spec>: Path to the OpenAPI specification file");
    io:println("  <output-directory>: Directory where generated client will be stored");
    io:println("  yes: Automatically answer 'yes' to all prompts (for CI/CD)");
    io:println("  quiet: Reduce logging output (minimal logs for CI/CD)");
    io:println("");
    io:println("Examples:");
    io:println("  bal run client_generator -- ./aligned_openapi.json ./client");
    io:println("  bal run client_generator -- ./spec.yaml ./output/ballerina yes");
    io:println("  bal run client_generator -- ./spec.json ./client yes quiet");
    io:println("");
    io:println("Features:");
    io:println("  • Generates complete Ballerina client from OpenAPI specification");
    io:println("  • Creates proper project structure with dependencies");
    io:println("  • Provides detailed error reporting and next steps");
    io:println("  • Supports both interactive and automated execution modes");
}