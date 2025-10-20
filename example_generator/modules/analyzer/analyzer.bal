import ballerina/file;
import ballerina/io;
import ballerina/lang.'string as strings;
import ballerina/lang.regexp;

public type ConnectorDetails record {|
    string connectorName;
    int apiCount;
    string clientBalContent;
    string typesBalContent;
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

    return {
        connectorName: connectorName,
        apiCount: apiCount,
        clientBalContent: clientContent,
        typesBalContent: typesContent
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
