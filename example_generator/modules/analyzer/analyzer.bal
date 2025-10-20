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
    } else if apiCount <=30 {
        return 3;
    } else {
        return 4;
    }
}
