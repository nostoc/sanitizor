import ballerina/log;
import doc_generator.doc_analyzer;

public function main() returns error? {
    log:printInfo("Starting Documentation Generator - Step 3: Enhanced Analysis");
    
    // Test with the smartsheet connector
    string smartsheetPath = "/home/hansika/dev/sanitizor/temp-workspace/module-ballerinax-smartsheet";
    
    log:printInfo("Testing enhanced analysis with smartsheet connector", path = smartsheetPath);
    
    // Analyze the real connector
    doc_analyzer:ConnectorAnalysis|doc_analyzer:AnalysisError result = 
        doc_analyzer:analyzeConnector(smartsheetPath);
    
    if result is doc_analyzer:AnalysisError {
        log:printError("Analysis failed", message = result.message());
        return result;
    }
    
    doc_analyzer:ConnectorAnalysis analysis = result;
    
    log:printInfo("Enhanced analysis completed successfully!",
        connectorName = analysis.connectorName,
        description = analysis.description,
        version = analysis.version,
        keywordsCount = analysis.keywords.length(),
        hasExamples = analysis.hasExamples,
        hasTests = analysis.hasTests,
        operationsCount = analysis.operations.length(),
        examplesCount = analysis.examples.length(),
        importsCount = analysis.imports.length()
    );
    
    // Show detailed results
    log:printInfo("Keywords found", keywords = analysis.keywords);
    log:printInfo("Imports found", imports = analysis.imports);
    
    foreach doc_analyzer:Operation operation in analysis.operations {
        log:printInfo("Operation found", 
            name = operation.name, 
            httpMethod = operation.httpMethod ?: "unknown"
        );
    }
    
    foreach doc_analyzer:ExampleProject example in analysis.examples {
        log:printInfo("Example found", 
            name = example.name, 
            hasConfig = example.hasConfig
        );
    }
    
    log:printInfo("Step 3 completed successfully - Enhanced analysis is working!");
}
