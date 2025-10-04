import sanitizor.spec_sanitizor;

import ballerina/io;
import ballerina/log;
import ballerina/os;
import ballerina/test;

@test:Config {}
public function testLLM() returns error? {
    log:printInfo("Testing LLM service initialization...");
    string? apiKey = os:getEnv("ANTHROPIC_API_KEY");
    if (apiKey is ()) {
        io:println("ANTHROPIC_API_KEY environment variable not set");
        return;
    } else {
        io:println("ANTHROPIC_API_KEY is set");
    }

    spec_sanitizor:LLMServiceError? initResult = spec_sanitizor:initLLMService();
    if (initResult is spec_sanitizor:LLMServiceError) {
        io:println("LLM service initialization failed:");
        io:println("Error: " + initResult.message());
        io:println("Details: " + initResult.toString());
        return;
    } else {
        io:println("LLM service initialized successfully");
    }

    io:println("Testing field description generation...");
    string|spec_sanitizor:LLMServiceError descResult = spec_sanitizor:generateFieldDescription(
            "userId",
            "A field in a user management schema representing user identification"
    );

    if (descResult is string) {
        io:println("Field description generated: " + descResult);
    } else {
        io:println("Field description generation failed:");
        io:println("Error: " + descResult.message());
        io:println("Details: " + descResult.toString());
    }
}
