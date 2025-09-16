import ballerina/ai;
import ballerina/io;
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
        anthropic:CLAUDE_SONNET_4_20250514
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

    ai:ChatMessage[]|ai:ChatUserMessage messages = [
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

# Fix Ballerina compilation errors by directly modifying the code
#
# + errorMessages - Array of error messages
# + typesFilePath - Path to the types.bal file that needs fixing
# + return - Success status and description of changes made
public function fixBallerinaCodeErrors(string[] errorMessages, string typesFilePath) returns [boolean, string]|LLMServiceError {
    ai:ModelProvider? model = anthropicModel;
    if (model is ()) {
        return error LLMServiceError("LLM service not initialized");
    }

    // Read the current types.bal file
    string|error fileContent = io:fileReadString(typesFilePath);
    if (fileContent is error) {
        return error LLMServiceError("Failed to read types.bal file", fileContent);
    }

    string errorsText = string:'join("\n", ...errorMessages);
    string prompt = string `You are a Ballerina programming expert. Fix the following compilation errors in the Ballerina code.

ERRORS TO FIX:
${errorsText}

CURRENT CODE:
${fileContent}

INSTRUCTIONS:
1. Analyze each error and determine the exact fix needed
2. For field type conflicts, adjust the types to be compatible (e.g., use 'decimal' instead of 'int' if needed)
3. For missing tokens, add the required syntax elements
4. Return the COMPLETE fixed code for the entire file
5. Preserve all existing code structure and only make minimal necessary changes
6. Ensure all record types and field definitions are valid Ballerina syntax

Return only the corrected Ballerina code without any explanations or markdown formatting.`;

    ai:ChatMessage[] messages = [
        {role: "user", content: prompt}
    ];

    ai:ChatAssistantMessage|error response = model->chat(messages);
    if (response is error) {
        return error LLMServiceError("Failed to generate code fixes", response);
    }

    string? fixedCode = response.content;
    if (fixedCode is ()) {
        return error LLMServiceError("Empty response from LLM");
    }

    // Write the fixed code back to the file
    error? writeResult = io:fileWriteString(typesFilePath, fixedCode);
    if (writeResult is error) {
        return error LLMServiceError("Failed to write fixed code to file", writeResult);
    }

    return [true, string `Fixed ${errorMessages.length()} compilation errors in ${typesFilePath}`];
}

