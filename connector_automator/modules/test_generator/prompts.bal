function createMockServerPrompt(string mockServerTemplate, string types) returns string {
    return string `
You are an expert Ballerina developer. Complete the mock server implementation by filling in realistic dummy data for all resource function bodies.

**Mock Server Template:**
${mockServerTemplate}

**Available Types:**
${types}

**Requirements:**
1. Fill all resource function bodies with realistic return data
2. Use proper type structures matching the return types
3. Include realistic field values (IDs, names, URLs, dates, etc.)
4. Handle different HTTP methods appropriately (GET, POST, PUT, DELETE)
5. Ensure all required fields are populated
6. Use meaningful test data that represents real-world scenarios
7. For path parameters, incorporate them into response data where appropriate
8. Add proper error handling and edge cases

**Example Response Structure:**
For a GET albums endpoint, return:
{
    "data": [
        {
            "id": "1234567890",
            "type": "albums",
            "attributes": {
                "name": "Sample Album",
                "artistName": "Sample Artist"
                // ... other realistic fields
            }
        }
    ]
}

Generate the complete mock_server.bal file with all function bodies implemented.
`;
}

function createTestGenerationPrompt(ConnectorAnalysis analysis) returns string {
    return string `
You are an expert Ballerina test developer. Generate comprehensive test cases for this connector based on the mock server implementation.

**Package Name:** ${analysis.packageName}

**Mock Server Implementation:**
${analysis.mockServerContent}

**Requirements:**
1. Import mock server with: import ${analysis.packageName}.mock.server as _;
2. Create configurable variables for live vs mock testing
3. Setup HTTP client configuration pointing to localhost:9090
4. Generate test functions for each resource endpoint found in the mock server
5. Use proper test assertions checking response structure
6. Include both positive and negative test scenarios where appropriate
7. Use @test:Config with appropriate groups: ["live_tests", "mock_tests"]
8. Follow the pattern: test:assertTrue(response?.data !is ()) and test:assertTrue(response?.errors is ())
9. Extract endpoint information from the mock server resource functions
10. Use realistic test data that matches what the mock server returns
11. Test different parameter combinations (required vs optional parameters)
12. Test path parameter variations (different IDs, storefronts, etc.)

**Test Structure Example:**
@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetAlbumsFromCatalog() returns error? {
    AlbumsResponse response = check clientEp->/catalog/us/albums(ids = ["1234567890"]);
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
    // Additional structural validations based on mock responses
}

**Instructions:**
- Analyze each resource function in the mock server
- Generate corresponding test functions 
- Use the same endpoint paths and parameter names
- Test both successful responses and error cases
- Include tests for different storefronts, relationships, views, etc.
- Ensure test data matches what the mock server expects/returns

Generate a complete test.bal file with comprehensive test coverage.
`;
}
