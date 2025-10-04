import sanitizor.spec_sanitizor;

import ballerina/io;
import ballerina/log;
import ballerina/test;

@test:Config {}
public function testSchemaRenaming() returns error? {
    log:printInfo("Testing schema renaming feature");

    // Initialize LLM service
    spec_sanitizor:LLMServiceError? initResult = spec_sanitizor:initLLMService();
    if (initResult is spec_sanitizor:LLMServiceError) {
        test:assertFail("Failed to initialize LLM service: " + initResult.message());
    }

    string specPath = "/home/hansika/dev/sanitizor/temp-workspace/docs/spec/aligned_ballerina_openapi.json";
    log:printInfo("Attempting to rename InlineResponse schemas in OpenAPI spec...");
    int|spec_sanitizor:LLMServiceError result = spec_sanitizor:renameInlineResponseSchemas(specPath);
    io:println("==============================");
    io:println(result);

    if (result is spec_sanitizor:LLMServiceError) {
        log:printError("Failed to rename schemas", 'error = result);
        test:assertFail("Failed to generate schema names" + result.message());
    }

    log:printInfo("Schema renaming completed successfully", renamedCount = result);
    test:assertTrue(result > 0, "Should have generated some schema names or returned 0");

}
