import connector_automator.sanitizor;

import ballerina/file;
import ballerina/io;
import ballerina/lang.regexp;

function setupMockServerModule(string connectorPath) returns error? {
    string ballerinaDir = connectorPath + "/ballerina";
    // cd into ballerina dir and add mock.server module using bal add cmd

    string command = string `bal add mock.server`;

    sanitizor:CommandResult addResult = sanitizor:executeCommand(command, ballerinaDir);
    if !addResult.success {
        return error("Failed to add mock.server module" + addResult.stderr);
    }

    // delete the auto generated tests directory
    string mockTestDir = ballerinaDir + "/modules/mock.server/tests";
    if check file:test(mockTestDir, file:EXISTS) {
        check file:remove(mockTestDir, file:RECURSIVE);
        io:println("Removed auto generated tests directory");
    }

    // delete auto generated mock.server.bal file
    string mockServerFile = ballerinaDir + "/modules/mock.server/mock.server.bal";
    if check file:test(mockServerFile, file:EXISTS) {
        check file:remove(mockServerFile, file:RECURSIVE);
        io:println("Removed auto generated mock.server.bal file");
    }

    return;
}

function generateMockServer(string connectorPath, string specPath) returns error? {
    string ballerinaDir = connectorPath + "/ballerina";
    string mockServerDir = ballerinaDir + "/modules/mock.server";
    io:println("COUNTING OPERATION IDS....");
    int operationCount = check countOperationsInSpec(specPath);

    string command;

    if operationCount <= MAX_OPERATIONS {
        io:println(string `Using all ${operationCount} operations`);
        command = string `bal openapi -i ${specPath} -o ${mockServerDir}`;
    } else {
        io:println(string `Filtering from ${operationCount} to ${MAX_OPERATIONS} most useful operations`);
        string operationsList = check selectOperationsUsingAI(specPath);
        io:println(string `Selected operations: ${operationsList}`);
        command = string `bal openapi -i ${specPath} -o ${mockServerDir} --operations ${operationsList}`;
    }

    // generate mock service template using openapi tool
    sanitizor:CommandResult result = sanitizor:executeCommand(command, ballerinaDir);
    if !result.success {
        return error("Failed to generate mock server using ballerina openAPI tool" + result.stderr);
    }

    // rename mock server
    string mockServerPathOld = mockServerDir + "/aligned_ballerina_openapi_service.bal";
    string mockServerPathNew = mockServerDir + "/mock_server.bal";
    if check file:test(mockServerPathOld, file:EXISTS) {
        check file:rename(mockServerPathOld, mockServerPathNew);
        io:println("Renamed mock server file");
    }

    // delete client.bal
    string clientPath = mockServerDir + "/client.bal";
    if check file:test(clientPath, file:EXISTS) {
        check file:remove(clientPath, file:RECURSIVE);
        io:println("Removed client.bal");
    }

    return;
}

function countOperationsInSpec(string specPath) returns int|error {
    string specContent = check io:fileReadString(specPath);

    // count operationId occurences in the spec
    regexp:RegExp operationIdPattern = re `"operationId"\s*:\s*"[^"]*"`;
    regexp:Span[] matches = operationIdPattern.findAll(specContent);
    io:println(matches.length());
    return matches.length();

}
