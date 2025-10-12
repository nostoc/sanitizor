import ballerina/file;
import ballerina/io;
import ballerina/lang.'string as strings;
import ballerina/lang.regexp;

public type ConnectorMetadata record {
    string connectorName;
    string version;
    string description;
    string[] dependencies;
    string[] clientMethods;
    string[] types;
    string[] examples;
};

public function analyzeConnector(string connectorPath) returns ConnectorMetadata|error {
    file:MetaData|error pathMeta = file:getMetaData(connectorPath);
    if pathMeta is error {
        return error("Invalid connector path: " + connectorPath);
    }

    if !pathMeta.dir {
        return error("Connector path must be a directory");
    }

    ConnectorMetadata metadata = {
        connectorName: "",
        version: "1.0.0",
        description: "",
        dependencies: [],
        clientMethods: [],
        types: [],
        examples: []
    };

    error? result = extractMetadata(connectorPath, metadata);
    if result is error {
        return result;
    }

    return metadata;
}

function extractMetadata(string connectorPath, ConnectorMetadata metadata) returns error? {
    check analyzeBallerinaToml(connectorPath, metadata);
    check analyzeClientFile(connectorPath, metadata);
    check analyzeTypesFile(connectorPath, metadata);
    check analyzeExamples(connectorPath, metadata);
}

function analyzeBallerinaToml(string connectorPath, ConnectorMetadata metadata) returns error? {
    string ballerinaTomlPath = connectorPath + "/Ballerina.toml";

    if !check file:test(ballerinaTomlPath, file:EXISTS) {
        ballerinaTomlPath = connectorPath + "/ballerina/Ballerina.toml";
    }

    if check file:test(ballerinaTomlPath, file:EXISTS) {
        string content = check io:fileReadString(ballerinaTomlPath);

        string[] lines = regexp:split(re `\n`, content);
        foreach string line in lines {
            string trimmedLine = strings:trim(line);
            if strings:startsWith(trimmedLine, "name") {
                string[] parts = regexp:split(re `=`, trimmedLine);
                if parts.length() > 1 {
                    metadata.connectorName = strings:trim(regexp:replaceAll(re `"`, parts[1], ""));
                }
            }
            if strings:startsWith(trimmedLine, "version") {
                string[] parts = regexp:split(re `=`, trimmedLine);
                if parts.length() > 1 {
                    metadata.version = strings:trim(regexp:replaceAll(re `"`, parts[1], ""));
                }
            }
            if strings:startsWith(trimmedLine, "description") {
                string[] parts = regexp:split(re `=`, trimmedLine);
                if parts.length() > 1 {
                    metadata.description = strings:trim(regexp:replaceAll(re `"`, parts[1], ""));
                }
            }
        }
    }
}

function analyzeClientFile(string connectorPath, ConnectorMetadata metadata) returns error? {
    string[] possibleClientPaths = [
        connectorPath + "/ballerina/client.bal",
        connectorPath + "/client.bal"
    ];

    foreach string clientPath in possibleClientPaths {
        if check file:test(clientPath, file:EXISTS) {
            string content = check io:fileReadString(clientPath);
            metadata.clientMethods = extractFunctionNames(content);
            break;
        }
    }
}

function analyzeTypesFile(string connectorPath, ConnectorMetadata metadata) returns error? {
    string[] possibleTypesPaths = [
        connectorPath + "/ballerina/types.bal",
        connectorPath + "/types.bal"
    ];

    foreach string typesPath in possibleTypesPaths {
        if check file:test(typesPath, file:EXISTS) {
            string content = check io:fileReadString(typesPath);
            metadata.types = extractTypeNames(content);
            break;
        }
    }
}

function analyzeExamples(string connectorPath, ConnectorMetadata metadata) returns error? {
    string examplesPath = connectorPath + "/examples";

    if check file:test(examplesPath, file:EXISTS) {
        file:MetaData[] examples = check file:readDir(examplesPath);

        foreach file:MetaData example in examples {
            if example.dir {
                string exampleName = example.absPath.substring(examplesPath.length() + 1);
                metadata.examples.push(exampleName);
            }
        }
    }
}

function extractFunctionNames(string content) returns string[] {
    string[] functions = [];
    string[] lines = regexp:split(re `\n`, content);

    foreach string line in lines {
        string trimmedLine = strings:trim(line);
        if strings:includes(trimmedLine, "remote function") ||
            strings:includes(trimmedLine, "resource function") {
            string[] parts = regexp:split(re ` `, trimmedLine);
            foreach int i in 0 ..< parts.length() - 1 {
                if parts[i] == "function" && parts.length() > i + 1 {
                    string funcName = parts[i + 1];
                    if strings:includes(funcName, "(") {
                        int? parenIndex = funcName.indexOf("(");
                        if parenIndex is int {
                            funcName = funcName.substring(0, parenIndex);
                        }
                    }
                    functions.push(funcName);
                    break;
                }
            }
        }
    }

    return functions;
}

function extractTypeNames(string content) returns string[] {
    string[] types = [];
    string[] lines = regexp:split(re `\n`, content);

    foreach string line in lines {
        string trimmedLine = strings:trim(line);
        if strings:startsWith(trimmedLine, "public type") {
            string[] parts = regexp:split(re ` `, trimmedLine);
            if parts.length() >= 3 {
                types.push(parts[2]);
            }
        }
    }

    return types;
}

public function getConnectorSummary(ConnectorMetadata metadata) returns string {
    string summary = "Connector: " + metadata.connectorName + "\n";
    summary += "Version: " + metadata.version + "\n";
    summary += "Description: " + metadata.description + "\n";
    summary += "Client Methods: " + strings:'join(", ", ...metadata.clientMethods) + "\n";
    summary += "Types: " + strings:'join(", ", ...metadata.types) + "\n";
    summary += "Examples: " + strings:'join(", ", ...metadata.examples) + "\n";

    return summary;
}
