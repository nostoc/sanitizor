import sanitizor.llm_service;

import ballerina/log;
import ballerina/test;
import ballerina/io;

@test:Config {}
public function testSchemaRenaming() returns error? {
    log:printInfo("Testing schema renaming feature");

    // Initialize LLM service
    llm_service:LLMServiceError? initResult = llm_service:initLLMService();
    if (initResult is llm_service:LLMServiceError) {
        test:assertFail("Failed to initialize LLM service: " + initResult.message());
    }

    string specPath = "/home/hansika/dev/sanitizor/temp-workspace/docs/spec/openapi.json";
    log:printInfo("Attempting to rename InlineResponse schemas in OpenAPI spec...");
    int|llm_service:LLMServiceError result = llm_service:renameInlineResponseSchemas(specPath);
    io:println("==============================");
    io:println(result);

    if (result is llm_service:LLMServiceError) {
        log:printError("Failed to rename schemas", 'error = result);
        test:assertFail("Failed to generate schema names" + result.message());
    }

    log:printInfo("Schema renaming completed successfully", renamedCount = result);
    test:assertTrue(result > 0, "Should have generated some schema names or returned 0");
   

}
