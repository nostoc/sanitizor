import ballerina/file;
import ballerina/io;
import ballerina/log;
import ballerina/regex;

// Analyze a Ballerina connector directory
public function analyzeConnector(string connectorPath) returns ConnectorAnalysis|AnalysisError {
    log:printInfo("Starting connector analysis", path = connectorPath);
    
    // Check if directory exists
    boolean pathExists = file:test(connectorPath, file:EXISTS) is true;
    if !pathExists {
        return error AnalysisError("Connector path does not exist: " + connectorPath, message = "Path not found");
    }
    
    // Read basic project structure
    ConnectorAnalysis analysis = check readBasicInfo(connectorPath);
    
    // Analyze directory structure
    analysis = check analyzeDirectoryStructure(connectorPath, analysis);
    
    log:printInfo("Connector analysis completed", 
        connectorName = analysis.connectorName,
        version = analysis.version,
        hasExamples = analysis.hasExamples,
        hasTests = analysis.hasTests
    );
    
    return analysis;
}

// Read basic information from Ballerina.toml
function readBasicInfo(string connectorPath) returns ConnectorAnalysis|AnalysisError {
    string ballerinaTomlPath = connectorPath + "/ballerina/Ballerina.toml";
    
    boolean tomlExists = file:test(ballerinaTomlPath, file:EXISTS) is true;
    if !tomlExists {
        return error AnalysisError("Ballerina.toml not found at: " + ballerinaTomlPath, message = "TOML file not found");
    }
    
    string|io:Error contentResult = io:fileReadString(ballerinaTomlPath);
    if contentResult is io:Error {
        return error AnalysisError("Failed to read Ballerina.toml: " + contentResult.message(), message = "File read error");
    }
    string content = contentResult;
    
    // Extract basic info using simple string parsing
    string name = extractTomlValue(content, "name") ?: "unknown-connector";
    string version = extractTomlValue(content, "version") ?: "1.0.0";
    string description = extractTomlValue(content, "description") ?: "";
    
    ConnectorAnalysis analysis = {
        connectorName: name,
        description: description,
        version: version,
        hasExamples: false,
        hasTests: false
    };
    
    log:printInfo("Basic info extracted", 
        name = name, 
        version = version,
        description = description
    );
    
    return analysis;
}

// Analyze directory structure to detect examples and tests
function analyzeDirectoryStructure(string connectorPath, ConnectorAnalysis analysis) returns ConnectorAnalysis|AnalysisError {
    ConnectorAnalysis updatedAnalysis = analysis;
    
    // Check for examples directory
    string examplesPath = connectorPath + "/examples";
    boolean examplesExist = file:test(examplesPath, file:EXISTS) is true;
    if examplesExist {
        updatedAnalysis.hasExamples = true;
        log:printInfo("Examples directory found", path = examplesPath);
    }
    
    // Check for tests directory (could be in root or under ballerina/)
    string[] testPaths = [
        connectorPath + "/tests",
        connectorPath + "/ballerina/tests"
    ];
    
    foreach string testPath in testPaths {
        boolean testExists = file:test(testPath, file:EXISTS) is true;
        if testExists {
            updatedAnalysis.hasTests = true;
            log:printInfo("Tests directory found", path = testPath);
            break;
        }
    }
    
    return updatedAnalysis;
}

// Simple helper to extract values from TOML content
function extractTomlValue(string content, string key) returns string? {
    // Look for pattern: key = "value"
    string[] lines = regex:split(content, "\n");
    
    foreach string line in lines {
        string trimmedLine = line.trim();
        if trimmedLine.startsWith(key + " =") || trimmedLine.startsWith(key + "=") {
            // Find the quoted value
            int? startQuotePos = trimmedLine.indexOf("\"");
            if startQuotePos is int {
                int? endQuotePos = trimmedLine.indexOf("\"", startQuotePos + 1);
                if endQuotePos is int {
                    return trimmedLine.substring(startQuotePos + 1, endQuotePos);
                }
            }
        }
    }
    
    return ();
}
