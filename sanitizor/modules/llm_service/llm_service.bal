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

# Generate descriptions for fields missing descriptions in OpenAPI spec
#
# + specFilePath - Path to the OpenAPI specification file
# + return - Number of descriptions added or error
public function addMissingDescriptions(string specFilePath) returns int|LLMServiceError {
    ai:ModelProvider? model = anthropicModel;
    if (model is ()) {
        return error LLMServiceError("LLM service not initialized");
    }

    // Read the OpenAPI spec file
    string|error fileContent = io:fileReadString(specFilePath);
    if (fileContent is error) {
        return error LLMServiceError("Failed to read OpenAPI spec file", fileContent);
    }

    json|error jsonSpec = fileContent.fromJsonString();
    if (jsonSpec is error) {
        return error LLMServiceError("Failed to parse OpenAPI spec as JSON", jsonSpec);
    }

    int descriptionsAdded = 0;
    json updatedSpec = jsonSpec;

    // Find all schemas with properties missing descriptions
    json|error componentsResult = updatedSpec.components;
    if (componentsResult is error) {
        log:printWarn("No components section found in OpenAPI spec");
        return 0;
    }

    json components = componentsResult;
    json|error schemasResult = components.schemas;
    if (schemasResult is error) {
        log:printWarn("No schemas section found in OpenAPI spec");
        return 0;
    }

    json schemas = schemasResult;

    // Iterate through all schemas
    if (schemas is map<json>) {
        foreach string schemaName in schemas.keys() {
            json|error schemaResult = schemas[schemaName];
            if (schemaResult is error) {
                continue;
            }

            json schema = schemaResult;
            json|error propertiesResult = schema.properties;
            if (propertiesResult is error) {
                continue; // Schema has no properties
            }

            json properties = propertiesResult;
            if (properties is map<json>) {
                foreach string fieldName in properties.keys() {
                    json|error fieldResult = properties[fieldName];
                    if (fieldResult is error) {
                        continue;
                    }

                    json fieldDef = fieldResult;

                    // Check if description is missing
                    json|error descResult = fieldDef.description;
                    if (descResult is error) {
                        // Description is missing, generate one
                        string schemaContext = string `Schema: ${schemaName}
Field: ${fieldName}
Field Definition: ${fieldDef.toJsonString()}
Schema Context: ${schema.toJsonString()}`;

                        string|LLMServiceError generatedDesc = generateFieldDescription(fieldName, schemaContext);
                        if (generatedDesc is LLMServiceError) {
                            log:printError("Failed to generate description for field", fieldName = fieldName, 'error = generatedDesc);
                            continue;
                        }

                        // Add the description to the field definition
                        if (fieldDef is map<json>) {
                            fieldDef["description"] = generatedDesc;
                            descriptionsAdded += 1;
                            log:printInfo("Added description for field", schemaName = schemaName, fieldName = fieldName, description = generatedDesc);
                        }
                    }
                }
            }
        }
    }

    // Write the updated content back to the file
    if (descriptionsAdded > 0) {
        string updatedContent = updatedSpec.toJsonString();
        error? writeResult = io:fileWriteString(specFilePath, updatedContent);
        if (writeResult is error) {
            return error LLMServiceError("Failed to write updated OpenAPI spec to file", writeResult);
        }
        log:printInfo("Successfully added descriptions to OpenAPI spec", descriptionsAdded = descriptionsAdded);
    }

    return descriptionsAdded;
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

