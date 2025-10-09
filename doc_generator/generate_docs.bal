import ballerina/io;
import ballerina/log;
import ballerina/os;
import doc_generator.doc_analyzer;
import doc_generator.ai_generator;

// Simple CLI for AI-powered documentation generation
public function main(string... args) returns error? {
    // Default configuration
    string connectorPath = "/home/hansika/dev/sanitizor/temp-workspace/module-ballerinax-smartsheet";
    string outputDir = "/home/hansika/dev/sanitizor/doc_generator/output";
    boolean useAI = true;
    boolean verbose = true;
    
    // Parse command line arguments
    int i = 0;
    while i < args.length() {
        match args[i] {
            "--path" | "-p" => {
                if i + 1 < args.length() {
                    connectorPath = args[i + 1];
                    i += 2;
                } else {
                    i += 1;
                }
            }
            "--output" | "-o" => {
                if i + 1 < args.length() {
                    outputDir = args[i + 1];
                    i += 2;
                } else {
                    i += 1;
                }
            }
            "--no-ai" => {
                useAI = false;
                i += 1;
            }
            "--quiet" | "-q" => {
                verbose = false;
                i += 1;
            }
            "--help" | "-h" => {
                printUsage();
                return;
            }
            _ => {
                i += 1;
            }
        }
    }
    
    if verbose {
        log:printInfo("🚀 AI-Powered Ballerina Connector Documentation Generator");
        log:printInfo(string `📁 Connector Path: ${connectorPath}`);
        log:printInfo(string `📝 Output Directory: ${outputDir}`);
        log:printInfo(string `🤖 AI Mode: ${useAI ? "Enabled" : "Template-only"}`);
    }
    
    // Initialize AI service if enabled
    if useAI {
        error? aiInit = ai_generator:initAIService();
        if aiInit is error {
            log:printError("Failed to initialize AI service. Falling back to templates.", aiInit);
            useAI = false;
        }
    }
    
    // Analyze the connector
    doc_analyzer:ConnectorAnalysis|doc_analyzer:AnalysisError analysis = doc_analyzer:analyzeConnector(connectorPath);
    if analysis is doc_analyzer:AnalysisError {
        log:printError("Connector analysis failed", analysis);
        return analysis;
    }
    
    if verbose {
        log:printInfo("✅ Connector analysis completed");
        log:printInfo(string `📊 Found ${analysis.operations.length()} operations, ${analysis.examples.length()} examples`);
    }
    
    // Generate all 5 README types
    [doc_analyzer:DocumentationType, string, string][] documents = [
        [doc_analyzer:MAIN_README, "README.md", "Main repository README"],
        [doc_analyzer:BALLERINA_README, "ballerina/README.md", "Ballerina module README"],
        [doc_analyzer:EXAMPLES_README, "examples/README.md", "Examples README"],
        [doc_analyzer:TESTS_README, "ballerina/tests/README.md", "Tests README"]
    ];
    
    int successCount = 0;
    int totalDocuments = documents.length();
    
    foreach [doc_analyzer:DocumentationType, string, string] doc in documents {
        doc_analyzer:DocumentationType docType = doc[0];
        string relativePath = doc[1];
        string description = doc[2];
        string outputPath = outputDir + "/" + relativePath;
        
        if verbose {
            log:printInfo(string `📝 Generating ${description}...`);
        }
        
        error? result = generateDocument(analysis, docType, outputPath, useAI, verbose);
        if result is error {
            log:printError(string `❌ Failed to generate ${description}`, result);
        } else {
            successCount += 1;
            if verbose {
                log:printInfo(string `✅ Generated ${description}: ${outputPath}`);
            }
        }
    }
    
    // Generate individual example READMEs
    if analysis.examples.length() > 0 {
        if verbose {
            log:printInfo(string `📚 Generating ${analysis.examples.length()} individual example README files...`);
        }
        
        foreach doc_analyzer:ExampleProject example in analysis.examples {
            string examplePath = string `${outputDir}/examples/${example.name}/README.md`;
            error? result = generateExampleReadme(example, analysis, examplePath, verbose);
            if result is error {
                log:printError(string `❌ Failed to generate example README for ${example.name}`, result);
            } else {
                successCount += 1;
                if verbose {
                    log:printInfo(string `✅ Generated example README: ${examplePath}`);
                }
            }
        }
        totalDocuments += analysis.examples.length();
    }
    
    // Summary
    log:printInfo(string `🎉 Documentation generation completed!`);
    log:printInfo(string `📊 Success: ${successCount}/${totalDocuments} documents generated`);
    log:printInfo(string `📁 Output directory: ${outputDir}`);
    
    return;
}

// Generate a single document
function generateDocument(doc_analyzer:ConnectorAnalysis analysis, 
                         doc_analyzer:DocumentationType docType,
                         string outputPath, boolean useAI, boolean verbose) returns error? {
    
    // Generate document content
    string documentContent = "";
    
    if useAI {
        // Use AI generation
        string|error aiResult = ai_generator:generateSpecificDocument(analysis, docType);
        if aiResult is error {
            if verbose {
                log:printWarn("AI generation failed, using template fallback", aiResult);
            }
            documentContent = generateTemplateContent(analysis, docType);
        } else {
            documentContent = aiResult;
        }
    } else {
        // Use template generation
        documentContent = generateTemplateContent(analysis, docType);
    }
    
    // Ensure output directory exists
    error? dirResult = ensureDirectoryExists(outputPath);
    if dirResult is error {
        return dirResult;
    }
    
    // Write the content
    check io:fileWriteString(outputPath, documentContent);
    
    return;
}

// Generate content using templates (simplified fallback)
function generateTemplateContent(doc_analyzer:ConnectorAnalysis analysis, doc_analyzer:DocumentationType docType) returns string {
    match docType {
        doc_analyzer:MAIN_README => {
            return createSimpleMainReadme(analysis);
        }
        doc_analyzer:BALLERINA_README => {
            return createSimpleBallerinaReadme(analysis);
        }
        doc_analyzer:EXAMPLES_README => {
            return createSimpleExamplesReadme(analysis);
        }
        doc_analyzer:TESTS_README => {
            return createSimpleTestsReadme(analysis);
        }
        _ => {
            return createSimpleMainReadme(analysis);
        }
    }
}

// Simple template fallbacks
function createSimpleMainReadme(doc_analyzer:ConnectorAnalysis analysis) returns string {
    return string `# Ballerina ${analysis.connectorName} connector

## Overview

${analysis.description}

The \`ballerinax/${analysis.connectorName.toLowerAscii()}\` package offers APIs to connect and interact with ${analysis.connectorName} services.

## Features

- ${analysis.operations.length()} API operations available
- Comprehensive ${analysis.connectorName} integration
- Easy-to-use Ballerina connector interface

## Setup guide

1. Create a ${analysis.connectorName} account
2. Generate API credentials
3. Configure your Ballerina application

## Quickstart

\`\`\`ballerina
import ballerinax/${analysis.connectorName.toLowerAscii()};

configurable string token = ?;

public function main() returns error? {
    ${analysis.connectorName.toLowerAscii()}:Client client = check new({
        auth: { token }
    });
    
    // Use the client for operations
}
\`\`\`

## Examples

${analysis.examples.length()} example(s) are available in the examples directory.

## Build from the source

1. Download and install Java SE Development Kit (JDK) version 17.
2. Download and install [Ballerina Swan Lake](https://ballerina.io/).
3. Execute: \`./gradlew clean build\`
`;
}

function createSimpleBallerinaReadme(doc_analyzer:ConnectorAnalysis analysis) returns string {
    return string `## Overview

${analysis.description}

The \`ballerinax/${analysis.connectorName.toLowerAscii()}\` package offers APIs to connect and interact with ${analysis.connectorName} services.

## Setup guide

Configure your ${analysis.connectorName} credentials and initialize the client.

## Usage

\`\`\`ballerina
import ballerinax/${analysis.connectorName.toLowerAscii()};

${analysis.connectorName.toLowerAscii()}:Client client = check new({
    auth: { token: "your-token" }
});
\`\`\`

## Examples

See the examples directory for practical usage demonstrations.

## Compatibility

- Ballerina Swan Lake 2201.x and later
- ${analysis.connectorName} API ${analysis.version}
`;
}

function createSimpleExamplesReadme(doc_analyzer:ConnectorAnalysis analysis) returns string {
    string examplesList = "";
    int index = 1;
    foreach doc_analyzer:ExampleProject example in analysis.examples {
        examplesList += string `${index}. [${example.name}] - ${example.description}\n`;
        index += 1;
    }
    
    return string `# Examples

The \`ballerinax/${analysis.connectorName.toLowerAscii()}\` connector provides practical examples illustrating usage in various scenarios.

## Available Examples

${examplesList}

## Prerequisites

1. Generate ${analysis.connectorName} credentials
2. Create a Config.toml file with your credentials

## Running Examples

1. Navigate to an example directory
2. Run: \`bal run\`
`;
}

function createSimpleTestsReadme(doc_analyzer:ConnectorAnalysis analysis) returns string {
    return string `# Running Tests

This guide explains how to run tests for the ${analysis.connectorName} connector.

## Prerequisites

Configure your ${analysis.connectorName} credentials in Config.toml:

\`\`\`toml
${analysis.connectorName.toLowerAscii()}Token = "your-token"
\`\`\`

## Running Tests

Execute the tests using:

\`\`\`bash
bal test
\`\`\`

## Test Coverage

The test suite covers ${analysis.operations.length()} API operations and various scenarios.
`;
}

// Generate individual example README
function generateExampleReadme(doc_analyzer:ExampleProject example, doc_analyzer:ConnectorAnalysis analysis, 
                              string outputPath, boolean verbose) returns error? {
    
    string content = string `# ${example.name} Example

${example.description}

## Prerequisites

1. Generate ${analysis.connectorName} credentials
2. Create a Config.toml file:

\`\`\`toml
${analysis.connectorName.toLowerAscii()}Token = "your-token"
\`\`\`

## Running

\`\`\`bash
bal run
\`\`\`

## Expected Output

This example demonstrates ${example.description.toLowerAscii()}.
`;
    
    error? dirResult = ensureDirectoryExists(outputPath);
    if dirResult is error {
        return dirResult;
    }
    
    check io:fileWriteString(outputPath, content);
    return;
}

// Ensure directory exists
function ensureDirectoryExists(string filePath) returns error? {
    int? lastSlash = filePath.lastIndexOf("/");
    if lastSlash is () {
        return;
    }
    
    string dirPath = filePath.substring(0, lastSlash);
    
    if !file:test(dirPath, file:EXISTS) {
        check file:createDir(dirPath, file:RECURSIVE);
    }
    
    return;
}

// Print usage information
function printUsage() {
    io:println("AI-Powered Ballerina Connector Documentation Generator");
    io:println("");
    io:println("Usage: bal run generate_docs.bal [OPTIONS]");
    io:println("");
    io:println("Options:");
    io:println("  -p, --path <path>     Path to connector directory");
    io:println("  -o, --output <dir>    Output directory");
    io:println("  --no-ai               Disable AI generation, use templates only");
    io:println("  -q, --quiet           Quiet mode (less verbose output)");
    io:println("  -h, --help            Show this help message");
    io:println("");
    io:println("Examples:");
    io:println("  bal run generate_docs.bal");
    io:println("  bal run generate_docs.bal --path /path/to/connector");
    io:println("  bal run generate_docs.bal --output ./custom-docs --no-ai");
}