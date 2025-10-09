import ballerina/io;
import ballerina/log;
import ballerina/os;
import doc_generator.doc_analyzer;
import doc_generator.ai_generator;
import doc_generator.template_manager;

// CLI commands for documentation generation
public enum GenerationMode {
    ALL,
    MAIN_README,
    BALLERINA_README,
    EXAMPLES_README,
    TESTS_README,
    INDIVIDUAL_EXAMPLES
}

// CLI configuration
public type CLIConfig record {
    string connectorPath;
    GenerationMode mode;
    string outputDir;
    boolean useAI;
    boolean verbose;
};

// Main CLI entry point
public function main(string... args) returns error? {
    CLIConfig config = parseCliArgs(args);
    
    if config.verbose {
        log:printInfo("🚀 AI-Powered Ballerina Connector Documentation Generator");
        log:printInfo(string `📁 Connector Path: ${config.connectorPath}`);
        log:printInfo(string `🤖 AI Mode: ${config.useAI ? "Enabled" : "Disabled"}`);
        log:printInfo(string `📝 Generation Mode: ${config.mode}`);
    }
    
    // Initialize AI service if enabled
    if config.useAI {
        error? aiInit = ai_generator:initAIService();
        if aiInit is error {
            log:printError("Failed to initialize AI service", aiInit);
            return aiInit;
        }
    }
    
    // Analyze the connector
    doc_analyzer:ConnectorAnalysis|doc_analyzer:AnalysisError analysis = doc_analyzer:analyzeConnector(config.connectorPath);
    if analysis is doc_analyzer:AnalysisError {
        log:printError("Connector analysis failed", analysis);
        return analysis;
    }
    
    // Generate documentation based on mode
    error? generateResult = generateDocumentation(analysis, config);
    if generateResult is error {
        log:printError("Documentation generation failed", generateResult);
        return generateResult;
    }
    
    log:printInfo("✅ Documentation generation completed successfully!");
    return;
}

// Generate documentation based on configuration
function generateDocumentation(doc_analyzer:ConnectorAnalysis analysis, CLIConfig config) returns error? {
    match config.mode {
        ALL => {
            return generateAllDocumentation(analysis, config);
        }
        MAIN_README => {
            return generateSingleDocument(analysis, config, doc_analyzer:MAIN_README, "README.md");
        }
        BALLERINA_README => {
            return generateSingleDocument(analysis, config, doc_analyzer:BALLERINA_README, "ballerina/README.md");
        }
        EXAMPLES_README => {
            return generateSingleDocument(analysis, config, doc_analyzer:EXAMPLES_README, "examples/README.md");
        }
        TESTS_README => {
            return generateSingleDocument(analysis, config, doc_analyzer:TESTS_README, "ballerina/tests/README.md");
        }
        INDIVIDUAL_EXAMPLES => {
            return generateExampleDocumentation(analysis, config);
        }
    }
    
    return;
}

// Generate all documentation types
function generateAllDocumentation(doc_analyzer:ConnectorAnalysis analysis, CLIConfig config) returns error? {
    log:printInfo("📚 Generating all documentation files...");
    
    // Define all document types to generate
    [doc_analyzer:DocumentationType, string][] documents = [
        [doc_analyzer:MAIN_README, "README.md"],
        [doc_analyzer:BALLERINA_README, "ballerina/README.md"],
        [doc_analyzer:EXAMPLES_README, "examples/README.md"],
        [doc_analyzer:TESTS_README, "ballerina/tests/README.md"]
    ];
    
    int successCount = 0;
    
    foreach [doc_analyzer:DocumentationType, string] doc in documents {
        error? result = generateSingleDocument(analysis, config, doc[0], doc[1]);
        if result is error {
            log:printWarn(string `Failed to generate ${doc[1]}`, result);
        } else {
            successCount += 1;
        }
    }
    
    // Generate individual example documentation
    error? exampleResult = generateExampleDocumentation(analysis, config);
    if exampleResult is error {
        log:printWarn("Failed to generate example documentation", exampleResult);
    } else {
        successCount += 1;
    }
    
    log:printInfo(string `✅ Generated ${successCount} documentation files`);
    return;
}

// Generate a single document with AI or templates
function generateSingleDocument(doc_analyzer:ConnectorAnalysis analysis, CLIConfig config, 
                               doc_analyzer:DocumentationType docType, string relativePath) returns error? {
    
    string outputPath = config.outputDir + "/" + relativePath;
    
    if config.useAI {
        return generateAIDocument(analysis, docType, outputPath, config.verbose);
    } else {
        return generateTemplateDocument(analysis, docType, outputPath, config.verbose);
    }
}

// Generate document using AI
function generateAIDocument(doc_analyzer:ConnectorAnalysis analysis, 
                          doc_analyzer:DocumentationType docType, 
                          string outputPath, boolean verbose) returns error? {
    
    if verbose {
        log:printInfo(string `🤖 Generating AI-powered documentation: ${outputPath}`);
    }
    
    // Generate document content using specialized prompts
    string|error documentContent = ai_generator:generateSpecificDocument(analysis, docType);
    if documentContent is error {
        log:printWarn("AI generation failed, falling back to template", documentContent);
        return generateTemplateDocument(analysis, docType, outputPath, verbose);
    }
    
    // Ensure output directory exists
    error? dirResult = ensureDirectoryExists(outputPath);
    if dirResult is error {
        return dirResult;
    }
    
    // Write the generated content
    check io:fileWriteString(outputPath, documentContent);
    
    if verbose {
        log:printInfo(string `✅ AI-generated document saved: ${outputPath}`);
    }
    
    return;
}

// Generate document using templates
function generateTemplateDocument(doc_analyzer:ConnectorAnalysis analysis, 
                                doc_analyzer:DocumentationType docType, 
                                string outputPath, boolean verbose) returns error? {
    
    if verbose {
        log:printInfo(string `📝 Generating template-based documentation: ${outputPath}`);
    }
    
    // Load template
    doc_analyzer:TemplateContent|doc_analyzer:AnalysisError template = template_manager:loadTemplate(docType);
    if template is doc_analyzer:AnalysisError {
        return template;
    }
    
    // Generate placeholder values
    doc_analyzer:PlaceholderValue[] placeholders = template_manager:generatePlaceholderValues(analysis);
    
    // Replace placeholders
    string content = template_manager:replacePlaceholders(template.content, placeholders);
    
    // Ensure output directory exists
    error? dirResult = ensureDirectoryExists(outputPath);
    if dirResult is error {
        return dirResult;
    }
    
    // Write content
    check io:fileWriteString(outputPath, content);
    
    if verbose {
        log:printInfo(string `✅ Template-based document saved: ${outputPath}`);
    }
    
    return;
}

// Create document content from AI response based on document type
function createDocumentFromAI(ai_generator:AIEnhancedContent aiContent, 
                             doc_analyzer:ConnectorAnalysis analysis,
                             doc_analyzer:DocumentationType docType) returns string {
    
    match docType {
        doc_analyzer:MAIN_README => {
            return createMainReadmeFromAI(aiContent, analysis);
        }
        doc_analyzer:BALLERINA_README => {
            return createBallerinaReadmeFromAI(aiContent, analysis);
        }
        doc_analyzer:EXAMPLES_README => {
            return createExamplesReadmeFromAI(aiContent, analysis);
        }
        doc_analyzer:TESTS_README => {
            return createTestsReadmeFromAI(aiContent, analysis);
        }
        _ => {
            return createMainReadmeFromAI(aiContent, analysis);
        }
    }
}

// Create main README from AI content
function createMainReadmeFromAI(ai_generator:AIEnhancedContent aiContent, 
                               doc_analyzer:ConnectorAnalysis analysis) returns string {
    return string `# Ballerina ${analysis.connectorName} connector

[![Build](https://github.com/ballerina-platform/module-ballerinax-${analysis.connectorName.toLowerAscii()}/actions/workflows/ci.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-${analysis.connectorName.toLowerAscii()}/actions/workflows/ci.yml)

## Overview

${aiContent.description}

The \`ballerinax/${analysis.connectorName.toLowerAscii()}\` package offers APIs to connect and interact with ${analysis.connectorName} services.

${aiContent.features}

## Setup guide

${aiContent.setupGuide}

## Quickstart

${aiContent.quickstart}

## Examples

${aiContent.examples}

## API Reference

${aiContent.apiOverview}

## Build from the source

### Setting up the prerequisites

1. Download and install Java SE Development Kit (JDK) version 17.
2. Download and install [Ballerina Swan Lake](https://ballerina.io/).
3. Download and install [Docker](https://www.docker.com/get-started).

### Build options

Execute the commands below to build from the source.

1. To build the package:
   \`\`\`bash
   ./gradlew clean build
   \`\`\`

2. To run the tests:
   \`\`\`bash
   ./gradlew clean test
   \`\`\`

## Contribute to Ballerina

As an open-source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful links

* For more information go to the [\`${analysis.connectorName.toLowerAscii()}\` package](https://central.ballerina.io/ballerinax/${analysis.connectorName.toLowerAscii()}/latest).
* For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/learn/by-example/).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
`;
}

// Create Ballerina module README from AI content
function createBallerinaReadmeFromAI(ai_generator:AIEnhancedContent aiContent, 
                                   doc_analyzer:ConnectorAnalysis analysis) returns string {
    return string `## Overview

${aiContent.description}

The \`ballerinax/${analysis.connectorName.toLowerAscii()}\` package offers APIs to connect and interact with ${analysis.connectorName} services.

## Module Overview

This module provides a Ballerina connector for ${analysis.connectorName}, enabling developers to:

${aiContent.features}

## Setup guide

${aiContent.setupGuide}

## Quickstart

${aiContent.quickstart}

## Examples

${aiContent.examples}

## Compatibility

- Ballerina Swan Lake 2201.x and later
- ${analysis.connectorName} API ${analysis.version}
`;
}

// Create Examples README from AI content
function createExamplesReadmeFromAI(ai_generator:AIEnhancedContent aiContent, 
                                  doc_analyzer:ConnectorAnalysis analysis) returns string {
    
    string examplesList = "";
    int index = 1;
    foreach doc_analyzer:ExampleProject example in analysis.examples {
        examplesList += string `${index}. [${example.name}](https://github.com/ballerina-platform/module-ballerinax-${analysis.connectorName.toLowerAscii()}/tree/main/examples/${example.name}) - ${example.description}\n\n`;
        index += 1;
    }
    
    return string `# Examples

The \`ballerinax/${analysis.connectorName.toLowerAscii()}\` connector provides practical examples illustrating usage in various scenarios. ${aiContent.examples}

## Available Examples

${examplesList}

## Prerequisites

${aiContent.setupGuide}

## Running Examples

1. Configure your credentials in \`Config.toml\`
2. Navigate to an example directory
3. Run: \`bal run\`

## Running an example

Execute the following commands to build an example from the source:

* To build an example:
    \`\`\`bash
    bal build
    \`\`\`

* To run an example:
    \`\`\`bash
    bal run
    \`\`\`
`;
}

// Create Tests README from AI content  
function createTestsReadmeFromAI(ai_generator:AIEnhancedContent aiContent, 
                                doc_analyzer:ConnectorAnalysis analysis) returns string {
    return string `# Running Tests

This guide explains how to run tests for the ${analysis.connectorName} connector.

## Prerequisites

${aiContent.setupGuide}

## Test Configuration

Create a \`Config.toml\` file in the tests directory with the following configurations:

\`\`\`toml
${analysis.connectorName.toLowerAscii()}Token = "<Your_${analysis.connectorName}_Access_Token>"
\`\`\`

## Running Tests

Execute the tests using:

\`\`\`bash
bal test
\`\`\`

## Test Coverage

The test suite covers:
- ${analysis.connectorName} API operations (${analysis.operations.length()} operations tested)
- Authentication and authorization flows
- Error handling scenarios
- Edge cases and boundary conditions

## Test Data

Tests use mock data to avoid affecting production systems. The mock service simulates ${analysis.connectorName} API responses for reliable testing.
`;
}

// Generate individual example documentation
function generateExampleDocumentation(doc_analyzer:ConnectorAnalysis analysis, CLIConfig config) returns error? {
    if analysis.examples.length() == 0 {
        log:printInfo("No examples found, skipping individual example documentation");
        return;
    }
    
    foreach doc_analyzer:ExampleProject example in analysis.examples {
        string exampleReadmePath = string `${config.outputDir}/examples/${example.name}/README.md`;
        
        string content = string `# ${example.name} Example

${example.description}

## Prerequisites

1. Generate ${analysis.connectorName} credentials as described in the [Setup guide](https://central.ballerina.io/ballerinax/${analysis.connectorName.toLowerAscii()}/latest#setup-guide).

2. Create a \`Config.toml\` file with your credentials:

\`\`\`toml
${analysis.connectorName.toLowerAscii()}Token = "<Your_${analysis.connectorName}_Access_Token>"
\`\`\`

## Setup

1. Configure your ${analysis.connectorName} credentials
2. Install dependencies: \`bal build\`

## Running

\`\`\`bash
bal run
\`\`\`

## Expected Output

This example demonstrates ${example.description.toLowerAscii()}.
`;
        
        error? dirResult = ensureDirectoryExists(exampleReadmePath);
        if dirResult is error {
            log:printWarn(string `Failed to create directory for ${example.name}`, dirResult);
            continue;
        }
        
        check io:fileWriteString(exampleReadmePath, content);
        
        if config.verbose {
            log:printInfo(string `✅ Generated example README: ${exampleReadmePath}`);
        }
    }
    
    return;
}

// Parse CLI arguments
function parseCliArgs(string[] args) returns CLIConfig {
    CLIConfig config = {
        connectorPath: "/home/hansika/dev/sanitizor/temp-workspace/module-ballerinax-smartsheet",
        mode: ALL,
        outputDir: "/home/hansika/dev/sanitizor/doc_generator/output",
        useAI: true,
        verbose: true
    };
    
    int i = 0;
    while i < args.length() {
        match args[i] {
            "--path" | "-p" => {
                if i + 1 < args.length() {
                    config.connectorPath = args[i + 1];
                    i += 2;
                } else {
                    i += 1;
                }
            }
            "--mode" | "-m" => {
                if i + 1 < args.length() {
                    match args[i + 1] {
                        "all" => config.mode = ALL;
                        "main" => config.mode = MAIN_README;
                        "ballerina" => config.mode = BALLERINA_README;
                        "examples" => config.mode = EXAMPLES_README;
                        "tests" => config.mode = TESTS_README;
                        "individual" => config.mode = INDIVIDUAL_EXAMPLES;
                    }
                    i += 2;
                } else {
                    i += 1;
                }
            }
            "--output" | "-o" => {
                if i + 1 < args.length() {
                    config.outputDir = args[i + 1];
                    i += 2;
                } else {
                    i += 1;
                }
            }
            "--no-ai" => {
                config.useAI = false;
                i += 1;
            }
            "--quiet" | "-q" => {
                config.verbose = false;
                i += 1;
            }
            "--help" | "-h" => {
                printUsage();
                i += 1;
            }
            _ => {
                i += 1;
            }
        }
    }
    
    return config;
}

// Print CLI usage information
function printUsage() {
    io:println("AI-Powered Ballerina Connector Documentation Generator");
    io:println("");
    io:println("Usage: bal run cli.bal [OPTIONS]");
    io:println("");
    io:println("Options:");
    io:println("  -p, --path <path>     Path to connector directory");
    io:println("                        (default: /home/hansika/dev/sanitizor/temp-workspace/module-ballerinax-smartsheet)");
    io:println("  -m, --mode <mode>     Generation mode: all, main, ballerina, examples, tests, individual");
    io:println("                        (default: all)");
    io:println("  -o, --output <dir>    Output directory (default: ./output)");
    io:println("  --no-ai               Disable AI generation, use templates only");
    io:println("  -q, --quiet           Quiet mode (less verbose output)");
    io:println("  -h, --help            Show this help message");
    io:println("");
    io:println("Examples:");
    io:println("  bal run cli.bal --path /path/to/connector --mode all");
    io:println("  bal run cli.bal --mode main --no-ai");
    io:println("  bal run cli.bal --path /path/to/connector --output ./docs");
}

// Ensure directory exists for file path
function ensureDirectoryExists(string filePath) returns error? {
    // Extract directory path
    int? lastSlash = filePath.lastIndexOf("/");
    if lastSlash is () {
        return;
    }
    
    string dirPath = filePath.substring(0, lastSlash);
    
    // Check if directory exists, create if it doesn't
    if !file:test(dirPath, file:EXISTS) {
        check file:createDir(dirPath, file:RECURSIVE);
    }
    
    return;
}