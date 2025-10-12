import doc_generator.ai_generator;

import ballerina/io;
import ballerina/os;

public function main(string... args) {
    if args.length() == 0 {
        printUsage();
        return;
    }

    string command = args[0];

    match command {
        "generate-all" => {
            if args.length() < 2 {
                io:println("Error: Missing connector path");
                printUsage();
                return;
            }
            string connectorPath = args[1];
            generateAllReadmes(connectorPath);
        }
        "generate-ballerina" => {
            if args.length() < 2 {
                io:println("Error: Missing connector path");
                printUsage();
                return;
            }
            string connectorPath = args[1];
            generateBallerinaReadme(connectorPath);
        }
        "generate-tests" => {
            if args.length() < 2 {
                io:println("Error: Missing connector path");
                printUsage();
                return;
            }
            string connectorPath = args[1];
            generateTestsReadme(connectorPath);
        }
        "generate-examples" => {
            if args.length() < 2 {
                io:println("Error: Missing connector path");
                printUsage();
                return;
            }
            string connectorPath = args[1];
            generateExamplesReadme(connectorPath);
        }
        "generate-main" => {
            if args.length() < 2 {
                io:println("Error: Missing connector path");
                printUsage();
                return;
            }
            string connectorPath = args[1];
            generateMainReadme(connectorPath);
        }
        _ => {
            io:println("Error: Unknown command '" + command + "'");
            printUsage();
        }
    }
}

function printUsage() {
    io:println("Ballerina Connector Documentation Generator");
    io:println("");
    io:println("Usage: bal run doc_generator -- <command> <connector-path> [options]");
    io:println("");
    io:println("Commands:");
    io:println("  generate-all      Generate all README files");
    io:println("  generate-ballerina Generate core module README");
    io:println("  generate-tests    Generate tests README");
    io:println("  generate-examples Generate examples README");
    io:println("  generate-main     Generate root README");
    io:println("");
    io:println("Examples:");
    io:println("  bal run doc_generator -- generate-all /path/to/connector");
    io:println("  bal run doc_generator -- generate-ballerina /path/to/connector");
}

function generateAllReadmes(string connectorPath) {
    io:println("Generating all READMEs for connector at: " + connectorPath);

    string|error apiKey = os:getEnv("ANTHROPIC_API_KEY");
    if apiKey is error {
        io:println("Error: ANTHROPIC_API_KEY environment variable is not set");
        return;
    }

    error? initResult = ai_generator:initDocumentationGenerator();
    if initResult is error {
        io:println("Error initializing AI generator: " + initResult.message());
        return;
    }

    error? result = ai_generator:generateAllDocumentation(connectorPath);
    if result is error {
        io:println("Error generating documentation: " + result.message());
        return;
    }

    io:println("✓ All READMEs generated successfully!");
}

function generateBallerinaReadme(string connectorPath) {
    io:println("Generating Ballerina module README for: " + connectorPath);

    string|error apiKey = os:getEnv("ANTHROPIC_API_KEY");
    if apiKey is error {
        io:println("Error: ANTHROPIC_API_KEY environment variable is not set");
        return;
    }

    error? initResult = ai_generator:initDocumentationGenerator();
    if initResult is error {
        io:println("Error initializing AI generator: " + initResult.message());
        return;
    }

    error? result = ai_generator:generateBallerinaReadme(connectorPath);
    if result is error {
        io:println("Error generating Ballerina README: " + result.message());
        return;
    }

    io:println("✓ Ballerina README generated successfully!");
}

function generateTestsReadme(string connectorPath) {
    io:println("Generating Tests README for: " + connectorPath);

    string|error apiKey = os:getEnv("ANTHROPIC_API_KEY");
    if apiKey is error {
        io:println("Error: ANTHROPIC_API_KEY environment variable is not set");
        return;
    }

    error? initResult = ai_generator:initDocumentationGenerator();
    if initResult is error {
        io:println("Error initializing AI generator: " + initResult.message());
        return;
    }

    error? result = ai_generator:generateTestsReadme(connectorPath);
    if result is error {
        io:println("Error generating Tests README: " + result.message());
        return;
    }

    io:println("✓ Tests README generated successfully!");
}

function generateExamplesReadme(string connectorPath) {
    io:println("Generating Examples README for: " + connectorPath);

    string|error apiKey = os:getEnv("ANTHROPIC_API_KEY");
    if apiKey is error {
        io:println("Error: ANTHROPIC_API_KEY environment variable is not set");
        return;
    }

    error? initResult = ai_generator:initDocumentationGenerator();
    if initResult is error {
        io:println("Error initializing AI generator: " + initResult.message());
        return;
    }

    error? result = ai_generator:generateExamplesReadme(connectorPath);
    if result is error {
        io:println("Error generating Examples README: " + result.message());
        return;
    }

    io:println("✓ Examples README generated successfully!");
}

function generateMainReadme(string connectorPath) {
    io:println("Generating Main README for: " + connectorPath);

    string|error apiKey = os:getEnv("ANTHROPIC_API_KEY");
    if apiKey is error {
        io:println("Error: ANTHROPIC_API_KEY environment variable is not set");
        return;
    }

    error? initResult = ai_generator:initDocumentationGenerator();
    if initResult is error {
        io:println("Error initializing AI generator: " + initResult.message());
        return;
    }

    error? result = ai_generator:generateMainReadme(connectorPath);
    if result is error {
        io:println("Error generating Main README: " + result.message());
        return;
    }

    io:println("✓ Main README generated successfully!");
}
