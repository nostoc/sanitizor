import ballerina/io;
import ballerina/log;
import ballerina/regex;
import doc_generator.doc_analyzer;
import doc_generator.template_manager;

public function main() returns error? {
    log:printInfo("🚀 Starting Ballerina Connector Documentation Generator");
    
    // Path to analyze (example connector)
    string connectorPath = "/home/hansika/dev/sanitizor/temp-workspace/module-ballerinax-smartsheet";
    
    log:printInfo(string `📁 Analyzing connector at: ${connectorPath}`);
    
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
    
    // Show first 10 operations
    if analysis.operations.length() > 0 {
        log:printInfo("\n🔧 Sample Operations:");
        int count = 0;
        foreach doc_analyzer:Operation op in analysis.operations {
            if count >= 10 { break; }
            log:printInfo(string `  ${count + 1}. ${op.httpMethod} ${op.name}: ${op.description}`);
            count += 1;
        }
        if analysis.operations.length() > 10 {
            log:printInfo(string `  ... and ${analysis.operations.length() - 10} more operations`);
        }
    }
    
    // Show examples
    if analysis.examples.length() > 0 {
        log:printInfo("\n📚 Examples Found:");
        foreach doc_analyzer:ExampleProject example in analysis.examples {
            log:printInfo(string `  - ${example.name}: ${example.description} ${example.hasConfiguration ? "(configured)" : ""}`);
        }
    }
    
    // Show setup requirements
    if analysis.setupRequirements.length() > 0 {
        log:printInfo("\n🛠️ Setup Requirements:");
        foreach doc_analyzer:SetupRequirement req in analysis.setupRequirements {
            string marker = req.required ? "[Required]" : "[Optional]";
            log:printInfo(string `  ${marker} ${req.name}: ${req.description}`);
        }
    }
    
    // **NEW: Template System Demonstration**
    log:printInfo("\n🎨 Generating Documentation Templates...");
    
    // Generate placeholder values from analysis
    doc_analyzer:PlaceholderValue[] placeholderValues = template_manager:generatePlaceholderValues(analysis);
    log:printInfo(string `📝 Generated ${placeholderValues.length()} placeholder values`);
    
    // Generate Main README
    doc_analyzer:TemplateContent|doc_analyzer:AnalysisError mainTemplate = template_manager:loadTemplate(doc_analyzer:MAIN_README);
    if mainTemplate is doc_analyzer:TemplateContent {
        string generatedMainReadme = template_manager:replacePlaceholders(mainTemplate.content, placeholderValues);
        
        // Write to file
        string outputPath = "/home/hansika/dev/sanitizor/doc_generator/output/README.md";
        check io:fileWriteString(outputPath, generatedMainReadme);
        log:printInfo(string `✅ Generated Main README: ${outputPath}`);
        
        // Show preview
        string[] lines = regex:split(generatedMainReadme, "\n");
        log:printInfo("\n📖 README Preview (first 15 lines):");
        int lineCount = 0;
        foreach string line in lines {
            if lineCount >= 15 { break; }
            log:printInfo(string `  ${line}`);
            lineCount += 1;
        }
        log:printInfo("  ...");
    }
    
    // Generate Ballerina README
    doc_analyzer:TemplateContent|doc_analyzer:AnalysisError ballerinaTemplate = template_manager:loadTemplate(doc_analyzer:BALLERINA_README);
    if ballerinaTemplate is doc_analyzer:TemplateContent {
        string generatedBallerinaReadme = template_manager:replacePlaceholders(ballerinaTemplate.content, placeholderValues);
        
        string outputPath = "/home/hansika/dev/sanitizor/doc_generator/output/BALLERINA_README.md";
        check io:fileWriteString(outputPath, generatedBallerinaReadme);
        log:printInfo(string `✅ Generated Ballerina README: ${outputPath}`);
    }
    
    // Generate Examples README
    doc_analyzer:TemplateContent|doc_analyzer:AnalysisError examplesTemplate = template_manager:loadTemplate(doc_analyzer:EXAMPLES_README);
    if examplesTemplate is doc_analyzer:TemplateContent {
        string generatedExamplesReadme = template_manager:replacePlaceholders(examplesTemplate.content, placeholderValues);
        
        string outputPath = "/home/hansika/dev/sanitizor/doc_generator/output/EXAMPLES_README.md";
        check io:fileWriteString(outputPath, generatedExamplesReadme);
        log:printInfo(string `✅ Generated Examples README: ${outputPath}`);
    }
    
    log:printInfo("\n🎉 Template System Test Complete!");
    log:printInfo(string `📁 All generated files available in: /home/hansika/dev/sanitizor/doc_generator/output/`);
}
