import fixer.fixer;

import ballerina/io;
import ballerina/log;

public function main(string... args) returns error? {
    if args.length() < 1 {
        printCodeFixerUsage();
        return;
    }

    string projectPath = args[0];

    log:printInfo("Starting Ballerina code fixer", projectPath = projectPath);
    io:println("=== AI-Powered Ballerina Code Fixer ===");
    io:println(string `Project path: ${projectPath}`);
    io:println("\nOperations to be performed:");
    io:println("1. Analyze Ballerina compilation errors");
    io:println("2. Generate AI-powered fixes for detected issues");
    io:println("3. Apply fixes with user confirmation");
    io:println("4. Iterate until all errors are resolved");

    if !getUserConfirmation("\nProceed with error fixing?") {
        io:println("Operation cancelled by user.");
        return;
    }

    io:println("Starting AI-powered Ballerina code fixer...");

    fixer:FixResult|fixer:BallerinaFixerError result = fixer:fixAllErrors(projectPath);

    if result is fixer:FixResult {
        if result.success {
            io:println("\nAll compilation errors fixed successfully!");
            io:println(string `✓ Fixed ${result.errorsFixed} errors`);
            io:println("✓ All Ballerina files compile without errors!");
        } else {
            io:println("\n⚠ Partial success:");
            io:println(string `✓ Fixed ${result.errorsFixed} errors`);
            io:println(string `${result.errorsRemaining} errors remain`);
            io:println("⚠ Some errors may require manual intervention");
        }

        if result.appliedFixes.length() > 0 {
            io:println("\nApplied fixes:");
            foreach string fix in result.appliedFixes {
                io:println(string `  • ${fix}`);
            }
        }

    } else {
        log:printError("Code fixer failed", 'error = result);
        io:println("Code fixing failed. Please check logs for details.");
        return result;
    }
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

function printCodeFixerUsage() {
    io:println("Ballerina AI Code Fixer");
    io:println("Usage: bal run -- <project-path>");
    io:println("  <project-path>: Path to the Ballerina project directory");
    io:println("");
    io:println("Environment Variables:");
    io:println("  ANTHROPIC_API_KEY: Required for AI-powered fixes");
    io:println("");
    io:println("Example:");
    io:println("  bal run -- ./my-ballerina-project");
    io:println("");
    io:println("Interactive Features:");
    io:println("  • Step-by-step confirmation for each fix");
    io:println("  • Review AI-generated changes before applying");
    io:println("  • Automatic backup creation before modifications");
    io:println("  • Progress feedback and iteration summaries");
}
