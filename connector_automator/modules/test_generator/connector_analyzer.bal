import ballerina/io;
import ballerina/lang.'string as strings;
import ballerina/lang.regexp;

public type ConnectorAnalysis record {
    string packageName;
    string mockServerContent;
};

function analyzeConnectorForTests(string connectorPath) returns ConnectorAnalysis|error {
    // Read Ballerina.toml to get package name
    string tomlContent = check io:fileReadString(connectorPath + "/ballerina/Ballerina.toml");
    string packageName = extractPackageName(tomlContent);

    // Read mock server content
    string mockServerContent = check io:fileReadString(connectorPath + "/ballerina/modules/mock.server/mock_server.bal");

    return {
        packageName,
        mockServerContent
    };
}

function extractPackageName(string tomlContent) returns string {
    string connectorName = "";
    string[] tomlLines = regexp:split(re `\n`, tomlContent);
    foreach string line in tomlLines {
        string trimmedLine = strings:trim(line);
        if strings:startsWith(trimmedLine, "name") {
            string[] parts = regexp:split(re `=`, trimmedLine);
            if parts.length() > 1 {
                connectorName = strings:trim(regexp:replaceAll(re `"`, parts[1], ""));
            }
        }
    }
    return connectorName;
}
