import ballerina/io;
import ballerina/log;
import ballerina/regex;
import ballerina/file;
import doc_generator.doc_analyzer;
import doc_generator.template_manager;
import doc_generator.ai_generator;

public function main() returns error? {
    log:printInfo("🚀 Starting AI-Powered Ballerina Connector Documentation Generator");
    
    // Path to analyze (example connector)
    string connectorPath = "/home/hansika/dev/sanitizor/temp-workspace/module-ballerinax-smartsheet";
    string outputDir = "/home/hansika/dev/sanitizor/doc_generator/output";
    boolean useAI = true;
    
    log:printInfo(string `📁 Analyzing connector at: ${connectorPath}`);
    log:printInfo(string `📝 Output directory: ${outputDir}`);
    log:printInfo(string `🤖 AI Generation: ${useAI ? "Enabled" : "Template-only"}`);
    
    // Initialize AI service
    if useAI {
        error? aiInit = ai_generator:initAIService();
        if aiInit is error {
            log:printError("Failed to initialize AI service. Falling back to templates.", aiInit);
            useAI = false;
        } else {
            log:printInfo("✅ AI service initialized successfully");
        }
    }
    
    // Perform comprehensive analysis
    doc_analyzer:ConnectorAnalysis|doc_analyzer:AnalysisError analysis = doc_analyzer:analyzeConnector(connectorPath);
    
    if analysis is doc_analyzer:AnalysisError {
        log:printError(string `❌ Analysis failed: ${analysis.message()}`);
        return analysis;
    }
    
    log:printInfo("✅ Analysis completed successfully!");
    
    // Display analysis summary
    log:printInfo(string `📊 Analysis Summary:
    📦 Connector: ${analysis.connectorName} v${analysis.version}
    📝 Description: ${analysis.description}
    🔧 Operations: ${analysis.operations.length()}
    📚 Examples: ${analysis.examples.length()}
    🛠️ Setup Requirements: ${analysis.setupRequirements.length()}
    🏷️ Keywords: ${analysis.keywords.length()}`);
    
    // Show first 5 operations
    if analysis.operations.length() > 0 {
        log:printInfo("\n🔧 Sample Operations:");
        int count = 0;
        foreach doc_analyzer:Operation op in analysis.operations {
            if count >= 5 { break; }
            log:printInfo(string `  ${count + 1}. ${op.httpMethod} ${op.name}: ${op.description}`);
            count += 1;
        }
        if analysis.operations.length() > 5 {
            log:printInfo(string `  ... and ${analysis.operations.length() - 5} more operations`);
        }
    }
    
    // Show examples
    if analysis.examples.length() > 0 {
        log:printInfo("\n📚 Examples Found:");
        foreach doc_analyzer:ExampleProject example in analysis.examples {
            log:printInfo(string `  - ${example.name}: ${example.description} ${example.hasConfiguration ? "(configured)" : ""}`);
        }
    }
    
    // **AI-POWERED DOCUMENTATION GENERATION**
    log:printInfo("\n🤖 Generating AI-Powered Documentation...");
    
    // Define all documents to generate
    [doc_analyzer:DocumentationType, string, string][] documents = [
        [doc_analyzer:MAIN_README, "README.md", "Main repository README"],
        [doc_analyzer:BALLERINA_README, "ballerina/README.md", "Ballerina module README"],
        [doc_analyzer:EXAMPLES_README, "examples/README.md", "Examples README"],
        [doc_analyzer:TESTS_README, "ballerina/tests/README.md", "Tests README"]
    ];
    
    int successCount = 0;
    
    foreach [doc_analyzer:DocumentationType, string, string] doc in documents {
        doc_analyzer:DocumentationType docType = doc[0];
        string relativePath = doc[1];
        string description = doc[2];
        string outputPath = outputDir + "/" + relativePath;
        
        log:printInfo(string `📝 Generating ${description}...`);
        
        error? result = generateDocument(analysis, docType, outputPath, useAI);
        if result is error {
            log:printError(string `❌ Failed to generate ${description}`, result);
        } else {
            successCount += 1;
            log:printInfo(string `✅ Generated ${description}: ${outputPath}`);
        }
    }
    
    // Generate individual example READMEs
    if analysis.examples.length() > 0 {
        log:printInfo(string `📚 Generating ${analysis.examples.length()} individual example README files...`);
        
        foreach doc_analyzer:ExampleProject example in analysis.examples {
            string examplePath = string `${outputDir}/examples/${example.name}/README.md`;
            error? result = generateExampleReadme(example, analysis, examplePath);
            if result is error {
                log:printError(string `❌ Failed to generate example README for ${example.name}`, result);
            } else {
                successCount += 1;
                log:printInfo(string `✅ Generated example README: ${examplePath}`);
            }
        }
    }
    
    // Final summary
    log:printInfo("\n🎉 AI-Powered Documentation Generation Complete!");
    log:printInfo(string `📊 Success: ${successCount} documents generated`);
    log:printInfo(string `📁 All generated files available in: ${outputDir}/`);
    
    // Show first few lines of main README as preview
    string mainReadmePath = outputDir + "/README.md";
    if file:test(mainReadmePath, file:EXISTS) is true {
        string|io:Error previewResult = io:fileReadString(mainReadmePath);
        if previewResult is string {
            string[] lines = regex:split(previewResult, "\n");
            log:printInfo("\n📖 Main README Preview (first 10 lines):");
            int lineCount = 0;
            foreach string line in lines {
                if lineCount >= 10 { break; }
                log:printInfo(string `  ${line}`);
                lineCount += 1;
            }
            log:printInfo("  ...");
        }
    }
}

// Generate a single document using AI or templates
function generateDocument(doc_analyzer:ConnectorAnalysis analysis, 
                         doc_analyzer:DocumentationType docType,
                         string outputPath, boolean useAI) returns error? {
    
    // Generate document content
    string documentContent = "";
    
    if useAI {
        // Use AI generation with specialized prompts
        string|error aiResult = ai_generator:generateSpecificDocument(analysis, docType);
        if aiResult is error {
            log:printWarn("AI generation failed, using template fallback", aiResult);
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

// Generate content using templates as fallback
function generateTemplateContent(doc_analyzer:ConnectorAnalysis analysis, doc_analyzer:DocumentationType docType) returns string {
    // Load template
    doc_analyzer:TemplateContent|doc_analyzer:AnalysisError template = template_manager:loadTemplate(docType);
    if template is doc_analyzer:AnalysisError {
        // Return a simple fallback if template loading fails
        return string `# ${analysis.connectorName} Documentation\n\n${analysis.description}\n\nGenerated documentation for ${analysis.connectorName} connector.`;
    }
    
    // Generate placeholder values
    doc_analyzer:PlaceholderValue[] placeholders = template_manager:generatePlaceholderValues(analysis);
    
    // Replace placeholders
    return template_manager:replacePlaceholders(template.content, placeholders);
}

// Generate individual example README
function generateExampleReadme(doc_analyzer:ExampleProject example, doc_analyzer:ConnectorAnalysis analysis, 
                              string outputPath) returns error? {
    
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
    
    error? dirResult = ensureDirectoryExists(outputPath);
    if dirResult is error {
        return dirResult;
    }
    
    check io:fileWriteString(outputPath, content);
    return;
}

// Ensure directory exists for file path
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
