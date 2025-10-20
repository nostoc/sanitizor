import example_generator.analyzer;

import ballerina/ai;
import ballerina/log;
import ballerinax/ai.anthropic;

//import connectorautomation/fixer;

configurable string apiKey = ?;
ai:ModelProvider? anthropicModel = ();

public function initExampleGenerator() returns error? {

    ai:ModelProvider|error modelProvider = new anthropic:ModelProvider(
        apiKey,
        anthropic:CLAUDE_SONNET_4_20250514,
        maxTokens = 60000,
        timeout = 300
    );
    if modelProvider is error {
        return error("Failed to initialize Anthropic model provider", modelProvider);
    }
    anthropicModel = modelProvider;
    log:printInfo("LLM service initialized successfully");
}

public function generateuseCase(analyzer:ConnectorDetails details) returns string|error {
    string prompt = getUsecasePrompt(details);
    ai:ModelProvider? model = anthropicModel;
    if model is () {
        return error("AI model not initialized. Please call initDocumentationGenerator() first.");
    }
    ai:ChatMessage[] messages = [{role: "user", content: prompt}];
    ai:ChatAssistantMessage|error response = model->chat(messages);

    if response is error {
        return error("Failed to generate use case", response);
    }
    return response.content ?: error("Empty use case response from LLM");
}

public function generateExampleCode(analyzer:ConnectorDetails details, string useCase) returns string|error {
    string prompt = getExampleCodegenerationPrompt(details, useCase);
    ai:ModelProvider? model = anthropicModel;
    if model is () {
        return error("AI model not initialized. Please call initDocumentationGenerator() first.");
    }
    ai:ChatMessage[] messages = [{role: "user", content: prompt}];
    ai:ChatAssistantMessage|error response = model->chat(messages);

    if response is error {
        return error("Failed to generate example code", response);
    }
    return response.content ?: error("Empty code response from LLM");
}

public function generateExampleName(string useCase) returns string|error {
    string prompt = getExampleNamePrompt(useCase);
    ai:ModelProvider? model = anthropicModel;
    if model is () {
        return error("AI model not initialized. Please call initExampleGenerator() first.");
    }
    ai:ChatMessage[] messages = [{role: "user", content: prompt}];
    ai:ChatAssistantMessage|error response = model->chat(messages);

    if response is error {
        return error("Failed to generate example name", response);
    }
    string  exampleName = response.content ?: "Example-1";
    return exampleName;
}
