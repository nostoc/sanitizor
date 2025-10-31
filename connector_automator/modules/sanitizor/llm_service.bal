import ballerina/ai;
import ballerina/log;
import ballerinax/ai.anthropic;

ai:ModelProvider? anthropicModel = ();

public function initLLMService(boolean quietMode = false) returns LLMServiceError? {

    ai:ModelProvider|error modelProvider = new anthropic:ModelProvider(
        apiKey,
        anthropic:CLAUDE_SONNET_4_20250514,
        maxTokens = 64000,
        timeout = 400
    );

    if modelProvider is error {
        return error LLMServiceError("Failed to initialize Anthropic model provider", modelProvider);
    }

    anthropicModel = modelProvider;
    if !quietMode {
        log:printInfo("LLM service initialized successfully");
    }
}
