import ballerina/log;
import ballerina/test;

import hansika/sanitizor.llm_service;

@test:Config {}
function testAddMissingDescriptions() returns error? {
    // Initialize the LLM service
    llm_service:LLMServiceError? initResult = llm_service:initLLMService();
    if (initResult is llm_service:LLMServiceError) {
        test:assertFail("Failed to initialize LLM service: " + initResult.message());
    }

    // Test the add missing descriptions function
    string specPath = "/home/hansika/dev/sanitizor/temp-workspace/docs/spec/aligned_ballerina_openapi.json";
    int|llm_service:LLMServiceError result = llm_service:addMissingDescriptions(specPath);

    if (result is llm_service:LLMServiceError) {
        test:assertFail("Failed to add missing descriptions: " + result.message());
    }

    log:printInfo("Successfully added descriptions", descriptionsAdded = result);
    test:assertTrue(result >= 0, "Should have added some descriptions or returned 0");
}
