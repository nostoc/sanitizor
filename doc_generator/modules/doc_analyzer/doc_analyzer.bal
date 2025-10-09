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
    
    // Extract setup requirements
    analysis = check extractSetupRequirements(analysis);
    
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
    
    string currentDescription = "";
    
    foreach int i in 0..<lines.length() {
        string line = lines[i];
        string trimmedLine = line.trim();
        
        // Look for documentation comments before resource functions
        if trimmedLine.startsWith("# ") && !trimmedLine.includes("+ ") && !trimmedLine.includes("return") {
            // Extract operation description from comment
            currentDescription = trimmedLine.substring(2).trim();
        }
        
        // Look for resource function patterns: "resource isolated function get/post/put/delete"
        if trimmedLine.startsWith("resource isolated function ") {
            Operation? operation = extractOperationFromResourceLine(trimmedLine, currentDescription);
            if operation is Operation && operation.name.length() > 0 {
                operations.push(operation);
            }
            currentDescription = ""; // Reset for next operation
        }
    }
    
    return operations;
}

// Extract a single operation from a resource function line
function extractOperationFromResourceLine(string line, string description) returns Operation? {
    string operationName = "";
    string httpMethod = "";
    
    // Parse: "resource isolated function get contacts(..."
    // or: "resource isolated function get contacts/[decimal contactId](..."
    
    if line.includes("resource isolated function get ") {
        httpMethod = "GET";
        string afterGet = extractAfterKeyword(line, "get ");
        operationName = extractOperationName(afterGet);
    } else if line.includes("resource isolated function post ") {
        httpMethod = "POST";
        string afterPost = extractAfterKeyword(line, "post ");
        operationName = extractOperationName(afterPost);
    } else if line.includes("resource isolated function put ") {
        httpMethod = "PUT";
        string afterPut = extractAfterKeyword(line, "put ");
        operationName = extractOperationName(afterPut);
    } else if line.includes("resource isolated function delete ") {
        httpMethod = "DELETE";
        string afterDelete = extractAfterKeyword(line, "delete ");
        operationName = extractOperationName(afterDelete);
    }
    
    if operationName.length() > 0 {
        // Use provided description or generate one
        string finalDescription = description.length() > 0 ? description : generateDefaultDescription(httpMethod, operationName);
        
        return {
            name: operationName,
            httpMethod: httpMethod,
            description: finalDescription
        };
    }
    
    return ();
}

// Generate default description if none provided
function generateDefaultDescription(string httpMethod, string operationName) returns string {
    match httpMethod {
        "GET" => {
            if operationName.includes("list") || operationName.includes("all") {
                return "List " + operationName;
            } else {
                return "Get " + operationName;
            }
        }
        "POST" => {
            return "Create " + operationName;
        }
        "PUT" => {
            return "Update " + operationName;
        }
        "DELETE" => {
            return "Delete " + operationName;
        }
        _ => {
            return httpMethod + " " + operationName;
        }
    }
}

// Helper to extract text after a keyword
function extractAfterKeyword(string line, string keyword) returns string {
    int? keywordIndex = line.indexOf(keyword);
    if keywordIndex is int {
        return line.substring(keywordIndex + keyword.length()).trim();
    }
    return "";
}

// Extract operation name from resource path
function extractOperationName(string resourcePath) returns string {
    // Extract the first part before '(' or space
    int? parenIndex = resourcePath.indexOf("(");
    string beforeParen = parenIndex is int ? resourcePath.substring(0, parenIndex) : resourcePath;
    
    // Clean up path parameters and get the base name
    string[] pathParts = regex:split(beforeParen, "/");
    if pathParts.length() > 0 {
        string baseName = pathParts[0].trim();
        // Remove any type annotations like ["folder"|"report"]
        int? bracketIndex = baseName.indexOf("[");
        if bracketIndex is int {
            return baseName.substring(0, bracketIndex);
        }
        return baseName;
    }
    
    return "";
}

// Extract endpoint pattern from resource path
function extractEndpoint(string resourcePath) returns string {
    int? parenIndex = resourcePath.indexOf("(");
    string pathPart = parenIndex is int ? resourcePath.substring(0, parenIndex) : resourcePath;
    
    // Convert Ballerina resource path to REST endpoint
    string endpoint = "/" + pathPart.trim();
    
    // Replace path parameters with placeholders
    endpoint = regex:replaceAll(endpoint, "\\[([^\\]]+)\\]", "{$1}");
    
    return endpoint;
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
    
    // Try to read example directories using a simple approach
    boolean readmePath = file:test(examplesPath + "/README.md", file:EXISTS) is true;
    if readmePath {
        // Read the examples README for overall info
        string|io:Error readmeResult = io:fileReadString(examplesPath + "/README.md");
        if readmeResult is string {
            log:printInfo("Found examples README", hasContent = readmeResult.length() > 0);
        }
    }
    
    // Check for common example directory patterns
    string[] commonExampleNames = [
        "project_task_management",
        "basic_example", 
        "quickstart",
        "getting_started",
        "simple_example"
    ];
    
    foreach string exampleName in commonExampleNames {
        string exampleDir = examplesPath + "/" + exampleName;
        boolean exampleExists = file:test(exampleDir, file:EXISTS) is true;
        
        if exampleExists {
            ExampleProject|AnalysisError exampleResult = analyzeExampleProject(exampleDir);
            if exampleResult is ExampleProject {
                updatedAnalysis.examples.push(exampleResult);
                log:printInfo("Example project analyzed", 
                    name = exampleResult.name, 
                    hasConfiguration = exampleResult.hasConfiguration,
                    description = exampleResult.description
                );
            }
        }
    }
    
    // If no specific examples found, add a generic one
    if updatedAnalysis.examples.length() == 0 {
        ExampleProject defaultExample = {
            name: "examples",
            path: examplesPath,
            description: "Example usage demonstrations",
            hasConfiguration: false
        };
        updatedAnalysis.examples.push(defaultExample);
    }
    
    log:printInfo("Examples analysis completed", examplesFound = updatedAnalysis.examples.length());
    return updatedAnalysis;
}

// Analyze a single example project
function analyzeExampleProject(string examplePath) returns ExampleProject|AnalysisError {
    string exampleName = extractDirectoryName(examplePath);
    
    // Check for Ballerina.toml in example
    string exampleTomlPath = examplePath + "/Ballerina.toml";
    boolean hasConfig = file:test(exampleTomlPath, file:EXISTS) is true;
    
    // Try to extract description from example's Ballerina.toml
    string description = "";
    if hasConfig {
        string|io:Error contentResult = io:fileReadString(exampleTomlPath);
        if contentResult is string {
            description = extractTomlValue(contentResult, "description") ?: "";
            
            // If no description in TOML, try to infer from name
            if description.length() == 0 {
                description = generateDescriptionFromName(exampleName);
            }
        }
    } else {
        // Try to read main.bal for comments or description
        string mainBalPath = examplePath + "/main.bal";
        boolean hasMain = file:test(mainBalPath, file:EXISTS) is true;
        if hasMain {
            string|io:Error mainResult = io:fileReadString(mainBalPath);
            if mainResult is string {
                description = extractDescriptionFromMainBal(mainResult) ?: generateDescriptionFromName(exampleName);
            }
        } else {
            description = generateDescriptionFromName(exampleName);
        }
    }
    
    return {
        name: exampleName,
        path: examplePath,
        description: description,
        hasConfiguration: hasConfig
    };
}

// Generate a description from example name
function generateDescriptionFromName(string exampleName) returns string {
    // Convert underscore/dash separated names to readable descriptions
    string cleaned = regex:replaceAll(exampleName, "[_-]", " ");
    
    match exampleName {
        "project_task_management" => {
            return "Demonstrates project and task management operations using the connector";
        }
        "basic_example" => {
            return "Basic usage example showing fundamental connector operations";
        }
        "quickstart" => {
            return "Quick start guide with essential connector setup and usage";
        }
        "getting_started" => {
            return "Getting started guide for new users of the connector";
        }
        _ => {
            return "Example demonstrating " + cleaned + " functionality";
        }
    }
}

// Extract description from main.bal file comments
function extractDescriptionFromMainBal(string content) returns string? {
    string[] lines = regex:split(content, "\n");
    
    foreach string line in lines {
        string trimmedLine = line.trim();
        // Look for top-level comments that describe the example
        if trimmedLine.startsWith("// ") && 
           (trimmedLine.includes("example") || trimmedLine.includes("demonstrates") || 
            trimmedLine.includes("shows") || trimmedLine.includes("illustrates")) {
            return trimmedLine.substring(3).trim();
        }
    }
    
    return ();
}

// Extract directory name from full path
function extractDirectoryName(string fullPath) returns string {
    string[] pathParts = regex:split(fullPath, "/");
    if pathParts.length() > 0 {
        return pathParts[pathParts.length() - 1];
    }
    return "unknown";
}

// Extract setup requirements based on connector analysis
function extractSetupRequirements(ConnectorAnalysis analysis) returns ConnectorAnalysis|AnalysisError {
    ConnectorAnalysis updatedAnalysis = analysis;
    updatedAnalysis.setupRequirements = [];
    
    // Basic requirements based on connector type and keywords
    SetupRequirement apiKeyReq = {
        name: "API Access Token",
        description: "Generate an API access token from your " + analysis.connectorName + " account",
        required: true
    };
    updatedAnalysis.setupRequirements.push(apiKeyReq);
    
    // Add Ballerina requirement
    SetupRequirement ballerinaReq = {
        name: "Ballerina Swan Lake",
        description: "Install Ballerina Swan Lake 2201.x or later",
        required: true
    };
    updatedAnalysis.setupRequirements.push(ballerinaReq);
    
    // Add requirements based on keywords
    foreach string keyword in analysis.keywords {
        if keyword.includes("management") || keyword.includes("project") {
            SetupRequirement projectReq = {
                name: "Project Access",
                description: "Ensure you have appropriate permissions to manage projects and tasks",
                required: false
            };
            updatedAnalysis.setupRequirements.push(projectReq);
            break;
        }
    }
    
    // Add requirements based on imports
    foreach string imp in analysis.imports {
        if imp.includes("http") {
            SetupRequirement networkReq = {
                name: "Network Access",
                description: "Ensure network connectivity to " + analysis.connectorName + " API endpoints",
                required: true
            };
            updatedAnalysis.setupRequirements.push(networkReq);
            break;
        }
    }
    
    log:printInfo("Setup requirements extracted", requirementsCount = updatedAnalysis.setupRequirements.length());
    return updatedAnalysis;
}
