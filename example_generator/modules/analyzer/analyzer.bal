import ballerina/file;
import ballerina/io;
import ballerina/lang.'string as strings;
import ballerina/lang.regexp;

import connectorautomation/fixer;

// Helper function to check if array contains a value
function arrayContains(string[] arr, string value) returns boolean {
    foreach string item in arr {
        if item == value {
            return true;
        }
    }
    return false;
}

public type ConnectorDetails record {|
    string connectorName;
    int apiCount;
    string clientBalContent;
    string typesBalContent;
    string functionSignatures;
    string typeNames;

|};

public function analyzeConnector(string connectorPath) returns ConnectorDetails|error {
    string clientBalPath = connectorPath + "/ballerina/client.bal";
    string typesBalPath = connectorPath + "/ballerina/types.bal";
    string ballerinaTomlPath = connectorPath + "/ballerina/Ballerina.toml";

    string clientContent = check io:fileReadString(clientBalPath);
    string typesContent = check io:fileReadString(typesBalPath);
    string balTomlContent = check io:fileReadString(ballerinaTomlPath);

    int apiCount = countApiOperations(clientContent);
    // get the connector name from Ballerina.toml
    string connectorName = "";
    string[] tomlLines = regexp:split(re `\n`, balTomlContent);
    foreach string line in tomlLines {
        string trimmedLine = strings:trim(line);
        if strings:startsWith(trimmedLine, "name") {
            string[] parts = regexp:split(re `=`, trimmedLine);
            if parts.length() > 1 {
                connectorName = strings:trim(regexp:replaceAll(re `"`, parts[1], ""));
            }
        }
    }

    // Extract function signatures
    string functionSignatures = extractFunctionSignatures(clientContent);

    return {
        connectorName: connectorName,
        apiCount: apiCount,
        clientBalContent: clientContent,
        typesBalContent: typesContent,
        functionSignatures: functionSignatures,
        typeNames: ""
    };
}

function countApiOperations(string clientContent) returns int {
    int count = 0;

    // Count resource functions
    regexp:RegExp resourcePattern = re `resource\s+isolated\s+function`;
    regexp:Span[] resourceMatches = resourcePattern.findAll(clientContent);
    count += resourceMatches.length();

    // Count remote functions
    regexp:RegExp remotePattern = re `remote\s+isolated\s+function`;
    regexp:Span[] remoteMatches = remotePattern.findAll(clientContent);
    count += remoteMatches.length();

    return count;
}

public function extractFunctionSignatures(string clientContent) returns string {
    string[] signatures = [];
    
    // Extract resource functions with cleaner formatting
    regexp:RegExp resourcePattern = re `resource\s+isolated\s+function\s+[^{]+`;
    regexp:Span[] resourceMatches = resourcePattern.findAll(clientContent);
    foreach regexp:Span span in resourceMatches {
        string signature = clientContent.substring(span.startIndex, span.endIndex);
        // Clean up the signature for better LLM understanding
        signature = regexp:replaceAll(re `\s+`, signature, " ");
        signatures.push(signature.trim());
    }
    
    // Extract remote functions with cleaner formatting
    regexp:RegExp remotePattern = re `remote\s+isolated\s+function\s+[^{]+`;
    regexp:Span[] remoteMatches = remotePattern.findAll(clientContent);
    foreach regexp:Span span in remoteMatches {
        string signature = clientContent.substring(span.startIndex, span.endIndex);
        // Clean up the signature for better LLM understanding
        signature = regexp:replaceAll(re `\s+`, signature, " ");
        signatures.push(signature.trim());
    }
    
    return string:'join("\n\n", ...signatures);
}

// Find a matching function in client content based on LLM-provided function name
public function findMatchingFunction(string clientContent, string llmFunctionName) returns string? {
    // Extract all function definitions
    regexp:RegExp functionPattern = re `(resource\s+isolated\s+function|remote\s+isolated\s+function)\s+[^{]+\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}`;
    regexp:Span[] matches = functionPattern.findAll(clientContent);
    
    foreach regexp:Span span in matches {
        string functionDef = clientContent.substring(span.startIndex, span.endIndex);
        
        // Check if this function could match the LLM-provided name
        // For resource functions like "get advisories" -> look for "get" method in path with "advisories"
        // For remote functions, match by function name more directly
        if isMatchingFunction(functionDef, llmFunctionName) {
            return functionDef;
        }
    }
    
    return ();
}

// Helper to determine if a function definition matches the LLM-provided name
public function isMatchingFunction(string functionDef, string llmFunctionName) returns boolean {
    string lowerFuncDef = functionDef.toLowerAscii();
    string lowerLLMName = llmFunctionName.toLowerAscii();
    
    // Simple keyword matching - if key words from LLM name appear in function definition
    string[] keywords = regexp:split(re `[\s/\[\]]+`, lowerLLMName);
    int matchCount = 0;
    
    foreach string keyword in keywords {
        if keyword.length() > 2 && lowerFuncDef.includes(keyword) {
            matchCount += 1;
        }
    }
    
    // If more than half the keywords match, consider it a match
    return matchCount >= (keywords.length() / 2);
}

public function numberOfExamples(int apiCount) returns int {
    if apiCount < 10 {
        return 1;
    } else if apiCount <= 20 {
        return 2;
    } else if apiCount <= 30 {
        return 3;
    } else {
        return 4;
    }
}

public function writeExampleToFile(string connectorPath, string exampleName, string useCase, string exampleCode) returns error? {
    // Create examples directory if it doesn't exist
    string examplesDir = connectorPath + "/examples";
    check file:createDir(examplesDir, file:RECURSIVE);

    // Use the provided example name directly
    string exampleDir = examplesDir + "/" + exampleName;

    // Create example directory
    check file:createDir(exampleDir, file:RECURSIVE);

    // Create .github directory
    string githubDir = exampleDir + "/.github";
    check file:createDir(githubDir, file:RECURSIVE);

    // Write main.bal file
    string mainBalPath = exampleDir + "/main.bal";
    check io:fileWriteString(mainBalPath, exampleCode);

    // Write Ballerina.toml file
    string ballerinaTomlPath = exampleDir + "/Ballerina.toml";
    string ballerinaTomlContent = generateBallerinaToml(exampleName);
    check io:fileWriteString(ballerinaTomlPath, ballerinaTomlContent);
}

// Function to sanitize example name for Ballerina package name
function sanitizePackageName(string exampleName) returns string {
    string sanitized = regexp:replaceAll(re `-`, exampleName, "_");

    sanitized = regexp:replaceAll(re `[^a-zA-Z0-9_.]`, sanitized, "");
    // Ensure it's not empty
    if sanitized == "" {
        sanitized = "example";
    }

    return sanitized;
}

function generateBallerinaToml(string exampleName) returns string {
    string packageName = sanitizePackageName(exampleName);
    return string `[package]
org = "ballerina"
name = "${packageName}"
version = "0.1.0"
distribution = "2201.10.0"

[build-options]
observabilityIncluded = true
`;
}

public function fixExampleCode(string exampleDir, string exampleName) returns error? {
    io:println(string `Checking and fixing compilation errors for example: ${exampleName}`);

    // Use the fixer to fix all compilation errors in the example directory
    fixer:FixResult|fixer:BallerinaFixerError fixResult = fixer:fixAllErrors(exampleDir, autoYes = true);

    if fixResult is fixer:FixResult {
        if fixResult.success {
            io:println(string `✓ Example '${exampleName}' compiles successfully!`);
            if fixResult.errorsFixed > 0 {
                io:println(string `  Fixed ${fixResult.errorsFixed} compilation errors`);
                if fixResult.appliedFixes.length() > 0 {
                    io:println("  Applied fixes:");
                    foreach string fix in fixResult.appliedFixes {
                        io:println(string `    • ${fix}`);
                    }
                }
            }
        } else {
            io:println(string `⚠ Example '${exampleName}' partially fixed:`);
            io:println(string `  Fixed ${fixResult.errorsFixed} errors`);
            io:println(string `  ${fixResult.errorsRemaining} errors remain`);
            if fixResult.appliedFixes.length() > 0 {
                io:println("  Applied fixes:");
                foreach string fix in fixResult.appliedFixes {
                    io:println(string `    • ${fix}`);
                }
            }
            // Don't fail completely, but warn about remaining errors
            io:println("  Some errors may require manual intervention");
        }
    } else {
        io:println(string `✗ Failed to fix example '${exampleName}': ${fixResult.message()}`);
        return error(string `Failed to fix compilation errors in example: ${exampleName}`, fixResult);
    }

    return;
}

public function extractTargetedContext(ConnectorDetails details, string[] functionNames) returns string|error {
    string clientContent = details.clientBalContent;
    string typesContent = details.typesBalContent;

    string context = "";
    string[] allDependentTypes = [];

    // Extract function definitions by matching the LLM-provided names to actual function signatures
    foreach string funcName in functionNames {
        string? matchedFunction = findMatchingFunction(clientContent, funcName);
        if matchedFunction is string {
            context += matchedFunction + "\n\n";
        }
    }

    // Find all types used in the function signatures (parameters and return types)
    string[] directTypes = findTypesInSignatures(context);
    allDependentTypes.push(...directTypes);

    // Recursively find all nested types
    findNestedTypes(directTypes, typesContent, allDependentTypes);

    // Extract the full definitions for all identified types
    foreach string typeName in allDependentTypes {
        string typeDef = extractBlock(typesContent, "public type " + typeName, "{", "}");
        if typeDef == "" {
            typeDef = extractBlock(typesContent, "public type " + typeName, ";", ";");
        }
        context += typeDef + "\n\n";
    }
    return context;
}

function findNestedTypes(string[] typesToSearch, string typesContent, string[] foundTypes) {
    string[] newTypesFound = [];
    foreach string typeName in typesToSearch {
        string typeDef = extractBlock(typesContent, "public type " + typeName, "{", "}");
        if typeDef == "" {
            typeDef = extractBlock(typesContent, "public type " + typeName, ";", ";");
        }

        if typeDef != "" {
            string[] nested = findTypesInSignatures(typeDef);
            foreach string nestedType in nested {
                // If it's a new type we haven't processed yet, add it to the list
                if !arrayContains(foundTypes, nestedType) {
                    newTypesFound.push(nestedType);
                    foundTypes.push(nestedType);
                }
            }
        }
    }
    // If we found new types, we need to search within them as well
    if newTypesFound.length() > 0 {
        findNestedTypes(newTypesFound, typesContent, foundTypes);
    }
}

function findTypesInSignatures(string signatures) returns string[] {
    regexp:RegExp typePattern = re `[A-Z][a-zA-Z0-9_]*`;
    regexp:Span[] matches = typePattern.findAll(signatures);
    string[] types = [];
    foreach regexp:Span span in matches {
        types.push(signatures.substring(span.startIndex, span.endIndex));
    }
    return types;
}

function extractBlock(string content, string startPattern, string openChar, string closeChar) returns string {
    // This is a simplified block extractor. It finds the start pattern and then balances
    // the open/close characters to find the end of the block.
    int? startIndex = content.indexOf(startPattern);
    if startIndex is () {
        return "";
    }

    int? openBraceIndex = content.indexOf(openChar, startIndex);
    if openBraceIndex is () {
        return "";
    }

    int braceCount = 1;
    int currentIndex = openBraceIndex + 1;
    while (braceCount > 0 && currentIndex < content.length()) {
        if content.substring(currentIndex, currentIndex + 1) == openChar {
            braceCount += 1;
        } else if content.substring(currentIndex, currentIndex + 1) == closeChar {
            braceCount -= 1;
        }
        currentIndex += 1;
    }

    return content.substring(startIndex, currentIndex);
}
