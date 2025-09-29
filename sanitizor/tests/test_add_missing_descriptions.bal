import ballerina/log;
import ballerina/test;

import hansika/sanitizor.spec_sanitizor;

@test:Config {}
function testAddMissingDescriptions() returns error? {
    // Initialize the LLM service
    spec_sanitizor:LLMServiceError? initResult = spec_sanitizor:initLLMService();
    if (initResult is spec_sanitizor:LLMServiceError) {
        test:assertFail("Failed to initialize LLM service: " + initResult.message());
    }

    // Test the add missing descriptions function
    string specPath = "/home/hansika/dev/sanitizor/temp-workspace/docs/spec/aligned_ballerina_openapi.json";
    int|spec_sanitizor:LLMServiceError result = spec_sanitizor:addMissingDescriptions(specPath);

    if (result is spec_sanitizor:LLMServiceError) {
        test:assertFail("Failed to add missing descriptions: " + result.message());
    }

    log:printInfo("Successfully added descriptions", descriptionsAdded = result);
    test:assertTrue(result >= 0, "Should have added some descriptions or returned 0");
}
