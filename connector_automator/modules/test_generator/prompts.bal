string backtick = "`";
string tripleBacktick = "```";

function createMockServerPrompt(string mockServerTemplate, string types) returns string {
    return string `
    You are an expert Ballerina developer. Your task is to complete the provided mock server implementation by filling in all the resource function bodies with realistic dummy data.
    You must follow the exact format of the example provided.

    **Critically Important:**
    - Your response MUST be a complete, raw Ballerina source code file.
    - Do NOT include any explanations, apologies, or markdown formatting like ${tripleBacktick}ballerina.

    <CONTEXT>
      <MOCK_SERVER_TEMPLATE>
        ${mockServerTemplate}
      </MOCK_SERVER_TEMPLATE>

      <AVAILABLE_TYPES>
        ${types}
      </AVAILABLE_TYPES>
    </CONTEXT>

    **Requirements:**
    1.  **Complete all Functions:** Every resource function in the template must be implemented.
    2.  **Realistic Data:** Use believable data for all fields (e.g., plausible names, IDs, and titles).
    3.  **Correct Types:** Ensure the returned data strictly adheres to the function's return type signature.
    4.  **JSON format:** The returned data should be in JSON format.
    5.  **Copyright Header:** The generated file must start with the copyright header as in the example.
    6.  **HTTP Listener:** The service should be attached to an HTTP listener on port 9090.
    7.  **${backtick}init${backtick} function:** Include the ${backtick}init${backtick} function to start the mock server.

    **Example of a well-implemented resource function:**
    ${tripleBacktick}ballerina
    resource function delete users/[UserIdMatchesAuthenticatedUser id]/bookmarks/[TweetId tweet_id]() returns BookmarkMutationResponse|http:Response {
        return {
            "data": {"bookmarked": false}
        };
    }
    ${tripleBacktick}

    Now, generate the complete ${backtick}mock_server.bal${backtick} file. Before returning the response, make sure by double checking that the dummy data you entered mathces the type declarations in the ${backtick}types.bal${backtick}.
`;
}

function createTestGenerationPrompt(ConnectorAnalysis analysis) returns string {
    return string `
    You are an expert Ballerina test developer. Your task is to generate a comprehensive set of test cases for the provided connector.
    You must follow the exact format of the example test file.

    **Critically Important:**
    - Your response MUST be a complete, raw Ballerina source code file.
    - Do NOT include any explanations, apologies, or markdown formatting like ${tripleBacktick}ballerina.

    <CONTEXT>
      <PACKAGE_NAME>
        ${analysis.packageName}
      </PACKAGE_NAME>

      <MOCK_SERVER_IMPLEMENTATION>
        ${analysis.mockServerContent}
      </MOCK_SERVER_IMPLEMENTATION>

       <CLIENT_INIT_METHOD>
        ${analysis.initMethodSignature}
      </CLIENT_INIT_METHOD>
      
      <REFERENCED_TYPE_DEFINITIONS>
        ${analysis.referencedTypeDefinitions}
      </REFERENCED_TYPE_DEFINITIONS>
    </CONTEXT>

    **Requirements:**
    1.  **Import mock server:** You must include the line: ${backtick}import ${analysis.packageName}.mock.server as _;${backtick}
    2.  **Configurable Variables:** Set up configurable variables for both live and mock testing environments.
    3.  **Client Initialization:** The HTTP client must be configured to point to ${backtick}http://localhost:9090${backtick} for mock tests. 
    Use <CLIENT_INIT_METHOD>${analysis.initMethodSignature}</CLIENT_INIT_METHOD> and <REFERENCED_TYPE_DEFINITIONS>${analysis.referencedTypeDefinitions}</REFERENCED_TYPE_DEFINITIONS> to initialize the client in the test.bal correctly. 
    4.  **Test Coverage:** Generate a test function for each resource endpoint in the mock server.
    5.  **Assertions:** Don't use assertions. Just write the test function like in the given example. 
    6.  **Test Groups:** All test functions must be annotated with ${backtick}@test:Config { groups: ["live_tests", "mock_tests"] }${backtick}.
    7.  **Copyright Header:** The generated file must start with the copyright header as in the example.

    **Example of a well-written test function:**
    ${tripleBacktick}ballerina
    @test:Config {
        groups: ["live_tests", "mock_tests"]
    }
    isolated function testUserLikeAPost() returns error? {
        UsersLikesCreateResponse response = check twitter->/users/[userId]/likes.post(
            payload = {
                tweetId: testPostId
            }
        );
        
    }
    ${tripleBacktick}

    Now, generate the complete ${tripleBacktick}test.bal${tripleBacktick} file with comprehensive test coverage. Double check the response before returing, make sure that the returned test.bal file is error free
`;
}
