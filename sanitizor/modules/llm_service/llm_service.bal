import ballerina/ai;
import ballerina/log;
import ballerina/os;
import ballerinax/ai.anthropic;

public type LLMServiceError distinct error;

ai:ModelProvider? anthropicModel = ();

# Initialize the LLM service
# + return - return value description
public function initLLMService() returns LLMServiceError? {
    string? apiKey = os:getEnv("ANTHROPIC_API_KEY");
    if (apiKey is ()) {
        return error LLMServiceError("ANTHROPIC_API_KEY environment variable not set");
    }

    ai:ModelProvider|error modelProvider = new anthropic:ModelProvider(
        apiKey,
        anthropic:CLAUDE_SONNET_4_20250514,
        "2023-06-01"
    );

    if (modelProvider is error) {
        return error LLMServiceError("Failed to initialize Anthropic model provider", modelProvider);
    }

    anthropicModel = modelProvider;
    log:printInfo("LLM service initialized successfully");
}

# Fix undocumented field by generating description from schema context
#
# + fieldName - Name of the undocumented field
# + schemaContext - Relevant schema context from OpenAPI spec
# + return - Generated description or error
public function generateFieldDescription(string fieldName, string schemaContext) returns string|LLMServiceError {
    ai:ModelProvider? model = anthropicModel;
    if (model is ()) {
        return error LLMServiceError("LLM service not initialized");
    }

    string prompt = string `Generate a concise description for the field "${fieldName}" based on this OpenAPI schema context:

${schemaContext}

Return only the description text, no JSON or extra formatting. Keep it professional and under 100 characters.`;

    ai:ChatMessage[] messages = [
        {role: "user", content: prompt}
    ];

    ai:ChatAssistantMessage|error response = model->chat(messages);
    if (response is error) {
        return error LLMServiceError("Failed to generate description", response);
    }

    string? content = response.content;
    if (content is string) {
        return content;
    } else {
        return error LLMServiceError("Empty response from LLM");
    }
}

# Fix Ballerina compilation errors using LLM
#
# + errorMessages - Array of error messages
# + codeContext - Ballerina code context
# + return - Suggested fixes or error
public function generateBallerinaDixSuggestions(string[] errorMessages, string codeContext) returns string[]|LLMServiceError {
    ai:ModelProvider? model = anthropicModel;
    if (model is ()) {
        return error LLMServiceError("LLM service not initialized");
    }

    string errorsText = string:'join("\n", ...errorMessages);
    string prompt = string `Fix these Ballerina compilation errors:

Errors:
${errorsText}

Code context:
${codeContext}

Provide specific fix suggestions, one per line. Be concise.`;

    ai:ChatMessage[] messages = [
        {role: "user", content: prompt}
    ];

    ai:ChatAssistantMessage|error response = model->chat(messages);
    if (response is error) {
        return error LLMServiceError("Failed to generate fixes", response);
    }

    // For now, return the response as a single suggestion
    string? content = response.content;
    if (content is string) {
        return [content];
    } else {
        return error LLMServiceError("Empty response from LLM");
    }
}

