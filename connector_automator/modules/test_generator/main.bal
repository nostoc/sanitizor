import ballerina/io;

public function main(string... args) returns error? {



    string connectorPath = args[0];
    string specPath = args[1];

    io:println("=== Test Generator ===");
    io:println(string `Processing connector: ${connectorPath}`);

    // Step 1: Setup mock server module
    check setupMockServerModule(connectorPath);

    // Step 2: Generate mock server implementation
    check generateMockServer(connectorPath, specPath);

    string mockServerPath = connectorPath + "/ballerina/modules/mock.server/mock_server.bal";
    string typesPath = connectorPath + "/ballerina/modules/mock.server/types.bal";

    // step 3: complete mock server template
    io:println("starting to complete the template...");
    check completeMockServer(mockServerPath,typesPath);

    // Step 3: Generate comprehensive tests
    check generateTestFile(connectorPath);

    io:println("✓ Test generation completed successfully!");
}

