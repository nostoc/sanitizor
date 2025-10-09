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
    
    // Analyze client.bal file for operations
    analysis = check analyzeClientFile(connectorPath, analysis);
    
    // Analyze examples if they exist
    if analysis.hasExamples {
        analysis = check analyzeExamples(connectorPath, analysis);
    }
    
    log:printInfo("Connector analysis completed", 
        connectorName = analysis.connectorName,
        version = analysis.version,
        hasExamples = analysis.hasExamples,
        hasTests = analysis.hasTests,
        operationsCount = analysis.operations.length(),
        examplesCount = analysis.examples.length()
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
    
    // Extract keywords array
    string[] keywords = extractTomlArray(content, "keywords");
    
    ConnectorAnalysis analysis = {
        connectorName: name,
        description: description,
        version: version,
        keywords: keywords,
        hasExamples: false,
        hasTests: false,
        operations: [],
        examples: [],
        setupRequirements: [],
        imports: []
    };
    
    log:printInfo("Basic info extracted", 
        name = name, 
        version = version,
        description = description,
        keywordsCount = keywords.length()
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

// Extract array values from TOML content
function extractTomlArray(string content, string key) returns string[] {
    string[] result = [];
    string[] lines = regex:split(content, "\n");
    
    foreach string line in lines {
        string trimmedLine = line.trim();
        if trimmedLine.startsWith(key + " =") {
            // Find the array content between [ and ]
            int? startBracket = trimmedLine.indexOf("[");
            int? endBracket = trimmedLine.indexOf("]");
            
            if startBracket is int && endBracket is int {
                string arrayContent = trimmedLine.substring(startBracket + 1, endBracket);
                // Split by comma and clean up quotes
                string[] items = regex:split(arrayContent, ",");
                foreach string item in items {
                    string cleanItem = item.trim();
                    if cleanItem.startsWith("\"") && cleanItem.endsWith("\"") {
                        cleanItem = cleanItem.substring(1, cleanItem.length() - 1);
                    }
                    if cleanItem.length() > 0 {
                        result.push(cleanItem);
                    }
                }
            }
            break;
        }
    }
    
    return result;
}

// Analyze client.bal file to extract operations
function analyzeClientFile(string connectorPath, ConnectorAnalysis analysis) returns ConnectorAnalysis|AnalysisError {
    string clientPath = connectorPath + "/ballerina/client.bal";
    boolean clientExists = file:test(clientPath, file:EXISTS) is true;
    
    if !clientExists {
        log:printInfo("client.bal not found, skipping operation analysis", path = clientPath);
        return analysis;
    }
    
    string|io:Error contentResult = io:fileReadString(clientPath);
    if contentResult is io:Error {
        log:printWarn("Failed to read client.bal", message = contentResult.message());
        return analysis;
    }
    
    string content = contentResult;
    ConnectorAnalysis updatedAnalysis = analysis;
    
    // Extract operations (simple pattern matching for resource functions)
    updatedAnalysis.operations = extractOperations(content);
    
    // Extract imports
    updatedAnalysis.imports = extractImports(content);
    
    log:printInfo("Client analysis completed", 
        operationsFound = updatedAnalysis.operations.length(),
        importsFound = updatedAnalysis.imports.length()
    );
    
    return updatedAnalysis;
}

// Extract operations from client.bal content
function extractOperations(string content) returns Operation[] {
    Operation[] operations = [];
    string[] lines = regex:split(content, "\n");
    
    foreach string line in lines {
        string trimmedLine = line.trim();
        // Look for resource function patterns
        if trimmedLine.includes("resource function") && 
           (trimmedLine.includes("get") || trimmedLine.includes("post") || 
            trimmedLine.includes("put") || trimmedLine.includes("delete")) {
            
            Operation operation = extractOperationFromLine(trimmedLine);
            if operation.name.length() > 0 {
                operations.push(operation);
            }
        }
    }
    
    return operations;
}

// Extract a single operation from a function line
function extractOperationFromLine(string line) returns Operation {
    string operationName = "unknown";
    string httpMethod = "";
    
    // Simple extraction logic
    if line.includes("resource function get") {
        httpMethod = "GET";
        int? getIndex = line.indexOf("get");
        if getIndex is int {
            string afterGet = line.substring(getIndex + 3).trim();
            int? spaceIndex = afterGet.indexOf(" ");
            if spaceIndex is int {
                operationName = afterGet.substring(0, spaceIndex);
            }
        }
    } else if line.includes("resource function post") {
        httpMethod = "POST";
        int? postIndex = line.indexOf("post");
        if postIndex is int {
            string afterPost = line.substring(postIndex + 4).trim();
            int? spaceIndex = afterPost.indexOf(" ");
            if spaceIndex is int {
                operationName = afterPost.substring(0, spaceIndex);
            }
        }
    }
    
    return {
        name: operationName,
        description: "",
        httpMethod: httpMethod,
        endpoint: ""
    };
}

// Extract imports from client.bal content
function extractImports(string content) returns string[] {
    string[] imports = [];
    string[] lines = regex:split(content, "\n");
    
    foreach string line in lines {
        string trimmedLine = line.trim();
        if trimmedLine.startsWith("import ") {
            string importLine = trimmedLine.substring(7); // Remove "import "
            int? semicolonIndex = importLine.indexOf(";");
            if semicolonIndex is int {
                string importName = importLine.substring(0, semicolonIndex).trim();
                imports.push(importName);
            }
        }
    }
    
    return imports;
}

// Analyze examples directory
function analyzeExamples(string connectorPath, ConnectorAnalysis analysis) returns ConnectorAnalysis|AnalysisError {
    string examplesPath = connectorPath + "/examples";
    
    ConnectorAnalysis updatedAnalysis = analysis;
    updatedAnalysis.examples = [];
    
    // For now, create a simple example entry since we know examples exist
    // This can be enhanced later to actually read the directory contents
    ExampleProject defaultExample = {
        name: "example",
        path: examplesPath,
        description: "Example usage of the connector",
        hasConfig: false
    };
    
    updatedAnalysis.examples.push(defaultExample);
    
    log:printInfo("Examples analysis completed", examplesFound = updatedAnalysis.examples.length());
    return updatedAnalysis;
}

// Analyze a single example project
function analyzeExampleProject(string examplePath) returns ExampleProject|AnalysisError {
    string exampleName = extractDirectoryName(examplePath);
    
    // Check for Ballerina.toml in example
    string exampleTomlPath = examplePath + "/Ballerina.toml";
    boolean hasConfig = file:test(exampleTomlPath, file:EXISTS) is true;
    
    // Try to extract description from example's Ballerina.toml or main.bal
    string description = "";
    if hasConfig {
        string|io:Error contentResult = io:fileReadString(exampleTomlPath);
        if contentResult is string {
            description = extractTomlValue(contentResult, "description") ?: "";
        }
    }
    
    return {
        name: exampleName,
        path: examplePath,
        description: description,
        hasConfig: hasConfig
    };
}

// Extract directory name from full path
function extractDirectoryName(string fullPath) returns string {
    string[] pathParts = regex:split(fullPath, "/");
    if pathParts.length() > 0 {
        return pathParts[pathParts.length() - 1];
    }
    return "unknown";
}
