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
    check completeMockServer(mockServerPath, typesPath);

    // Step 4: Generate tests
    check generateTestFile(connectorPath);

     // Step 5: Create test configuration file
    io:println("Step 5: Creating test configuration...");
    check createTestConfig(connectorPath);

     // Step 6: Fix all compilation errors related to tests
    io:println("Step 5: Building and fixing compilation errors...");
    check fixTestFileErrors(connectorPath);

    

    io:println("✓ Test generation completed successfully!");
}

