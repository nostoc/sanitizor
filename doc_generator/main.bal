import ballerina/log;
import doc_generator.doc_analyzer;

public function main() returns error? {
    log:printInfo("Starting Documentation Generator - Step 2: File Analysis");
    
    // Test with the smartsheet connector (ballerina subdirectory)
    string smartsheetPath = "/home/hansika/dev/sanitizor/temp-workspace/module-ballerinax-smartsheet";
    
    log:printInfo("Testing file analysis with smartsheet connector", path = smartsheetPath);
    
    // Analyze the real connector
    doc_analyzer:ConnectorAnalysis|doc_analyzer:AnalysisError result = 
        doc_analyzer:analyzeConnector(smartsheetPath);
    
    if result is doc_analyzer:AnalysisError {
        log:printError("Analysis failed", message = result.message());
        return result;
    }
    
    doc_analyzer:ConnectorAnalysis analysis = result;
    
    log:printInfo("Analysis completed successfully!",
        connectorName = analysis.connectorName,
        description = analysis.description,
        version = analysis.version,
        hasExamples = analysis.hasExamples,
        hasTests = analysis.hasTests
    );
    
    log:printInfo("Step 2 completed successfully - File analysis is working!");
}
