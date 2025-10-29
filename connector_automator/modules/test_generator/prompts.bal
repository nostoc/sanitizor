

string backtick = "`";
string tripleBacktick = "```";

function createMockServerPrompt(string mockServerTemplate, string types) returns string {
    return string `
    You are an expert Ballerina developer specializing in creating flawless mock API servers. Your goal is to complete a given Ballerina service template by filling in the resource functions with realistic, type-correct mock data.

    **Phase 1: Reflection (Internal Monologue)**

    Before generating any code, take a moment to reflect on the requirements for a perfect response.
    1.  **Output Purity:** The final output must be a single, complete, raw Ballerina source code file. It absolutely cannot contain any conversational text, explanations, apologies, or markdown formatting like ${tripleBacktick}ballerina. It must start with the first line of code and end with the last.
    2.  **Structural Integrity:** I must adhere strictly to the provided template. My job is to *fill in the blanks* (the function bodies), not to refactor or add new elements.
    3.  **Server Initialization:** This is a common point of failure. The user wants the service attached directly to an ${backtick}http:Listener${backtick} on port 9090. A critical mistake to avoid is generating a separate ${backtick}public function init()${backtick}. The listener and service declaration are sufficient to define the running server. I will not add an ${backtick}init${backtick} function.
    4.  **Data Accuracy:** The mock data must be more than just plausible; it must be a perfect match for the Ballerina record types provided in the ${backtick}<AVAILABLE_TYPES>${backtick} context. I need to meticulously check every field, data type (string, int, boolean), and structure (arrays, nested records, optional fields) to ensure 100% type safety. The return value should be a JSON literal.
    5.  **Completeness:** Every single resource function in the template must be implemented. No function should be left with an empty body or a placeholder comment.

    **Phase 2: Execution**

    Now, based on my reflection, I will generate the complete ${backtick}mock_server.bal${backtick} file. I will follow these instructions with extreme precision.

    **Critically Important:**
    - Your response MUST be a complete, raw Ballerina source code file.
    - Do NOT include any explanations or markdown formatting.

    <CONTEXT>
      <MOCK_SERVER_TEMPLATE>
        ${mockServerTemplate}
      </MOCK_SERVER_TEMPLATE>

      <AVAILABLE_TYPES>
        ${types}
      </AVAILABLE_TYPES>
    </CONTEXT>

    **Requirements:**
    1.  **Copyright Header:** The generated file must start with the exact copyright header from the template.
    2.  **HTTP Listener:** The service must be attached to a globally defined ${backtick}http:Listener ep0 = new (9090);${backtick}.
    3.  **NO ${backtick}init${backtick} FUNCTION:** You must not include any ${backtick}init${backtick} function. The service definition attached to the listener is the complete server configuration.
    4.  **Complete All Functions:** Implement the body for every resource function.
    5.  **Realistic & Type-Correct JSON:** Use believable data for all fields. The returned JSON structure must strictly adhere to the function's return type signature as defined in the provided types.
    6.  **Preserve Doc Comments:** All documentation comments (${backtick}# ...${backtick}) above the resource functions in the template must be preserved.

    **Example of a well-implemented resource function:**
    ${tripleBacktick}ballerina
    # Deletes the Tweet specified by the Tweet ID.
    resource function delete users/[string id]/bookmarks/[string tweet_id]() returns BookmarkMutationResponse|http:Response {
        return {
            "data": {"bookmarked": false}
        };
    }
    ${tripleBacktick}

    Now, generate the complete and final ${backtick}mock_server.bal${backtick} file.
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
