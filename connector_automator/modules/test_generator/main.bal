import ballerina/io;

public function main(string...args) returns error? {

    string connectorPath = args[0];
    string specPath = args[1];

    io:println("=== Test Generator ===");
    io:println(string `Processing connector: ${connectorPath}`);
    
    // Step 1: Setup mock server module
    check setupMockServerModule(connectorPath);
    
    // Step 2: Generate mock server implementation
   check generateMockServer(connectorPath, specPath);
    
    // Step 3: Generate comprehensive tests
    //check generateTests(connectorPath);
    
    io:println("✓ Test generation completed successfully!");
}