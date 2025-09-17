import ballerina/ai;
import ballerina/io;
import ballerina/log;
import ballerina/os;
import ballerina/regex;
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
// Enhanced function to add missing descriptions and fix $ref patterns
public function addMissingDescriptions(string specFilePath) returns int|LLMServiceError {
    log:printInfo("Processing OpenAPI spec for missing descriptions", specPath = specFilePath);
    
    // Read the OpenAPI spec file
    json|error specResult = io:fileReadJson(specFilePath);
    if specResult is error {
        return error LLMServiceError("Failed to read OpenAPI spec file", specResult);
    }
    
    json specJson = specResult;
    
    // Track the number of descriptions added
    int descriptionsAdded = 0;
    
    // Process components/schemas for missing descriptions
    if specJson is map<json> {
        json|error componentsResult = specJson.get("components");
        if componentsResult is map<json> {
            json|error schemasResult = componentsResult.get("schemas");
            if schemasResult is map<json> {
                map<json> schemas = <map<json>>schemasResult;
                
                // Process each schema
                foreach string schemaName in schemas.keys() {
                    json|error schemaResult = schemas.get(schemaName);
                    if schemaResult is map<json> {
                        map<json> schemaMap = <map<json>>schemaResult;
                        
                        // Check if schema itself needs description
                        if !schemaMap.hasKey("description") {
                            string context = string `Schema '${schemaName}' definition: ${schemaMap.toString()}`;
                            string|LLMServiceError description = generateFieldDescription(schemaName, context);
                            if description is string {
                                schemaMap["description"] = description;
                                descriptionsAdded += 1;
                                log:printInfo("Added description to schema", schema = schemaName);
                            } else {
                                log:printError("Failed to generate description for schema", schema = schemaName, 'error = description);
                            }
                        }
                        
                        // Process properties within the schema
                        if schemaMap.hasKey("properties") {
                            json|error propertiesResult = schemaMap.get("properties");
                            if propertiesResult is map<json> {
                                map<json> properties = <map<json>>propertiesResult;
                                descriptionsAdded += processSchemaProperties(properties, schemaName);
                            }
                        }
                        
                        // Process allOf, oneOf, anyOf arrays
                        descriptionsAdded += processNestedSchemas(schemaMap, schemaName);
                    }
                }
                
                // Update the spec with processed schemas
                componentsResult["schemas"] = schemas;
                specJson["components"] = componentsResult;
            }
        }
    }
    
    // Write the updated spec back to file
    error? writeResult = io:fileWriteJson(specFilePath, specJson);
    if writeResult is error {
        return error LLMServiceError("Failed to write updated OpenAPI spec", writeResult);
    }
    
    return descriptionsAdded;
}

// Helper function to process schema properties recursively
function processSchemaProperties(map<json> properties, string parentSchemaName) returns int {
    int descriptionsAdded = 0;
    
    foreach string propertyName in properties.keys() {
        json|error propertyResult = properties.get(propertyName);
        if propertyResult is map<json> {
            map<json> propertyMap = <map<json>>propertyResult;
            
            // Handle $ref with description pattern - convert to allOf
            if propertyMap.hasKey("$ref") && propertyMap.hasKey("description") {
                string refValue = <string>propertyMap.get("$ref");
                string description = <string>propertyMap.get("description");
                
                // Convert to allOf format
                map<json> newPropertyMap = {
                    "description": description,
                    "allOf": [{"$ref": refValue}]
                };
                
                // Remove the original $ref
                _ = propertyMap.removeIfHasKey("$ref");
                
                // Update the property with the new format
                properties[propertyName] = newPropertyMap;
                log:printInfo("Converted $ref with description to allOf format", 
                             schema = parentSchemaName, property = propertyName);
                continue;
            }
            
            // Check if property needs description
            if !propertyMap.hasKey("description") && !propertyMap.hasKey("$ref") {
                string context = string `Property '${propertyName}' in schema '${parentSchemaName}'. Property definition: ${propertyMap.toString()}`;
                string|LLMServiceError description = generateFieldDescription(propertyName, context);
                if description is string {
                    propertyMap["description"] = description;
                    descriptionsAdded += 1;
                    log:printInfo("Added description to property", schema = parentSchemaName, property = propertyName);
                } else {
                    log:printError("Failed to generate description for property", 
                                  schema = parentSchemaName, property = propertyName, 'error = description);
                }
            }
            
            // Recursively process nested properties
            if propertyMap.hasKey("properties") {
                json|error nestedPropertiesResult = propertyMap.get("properties");
                if nestedPropertiesResult is map<json> {
                    map<json> nestedProperties = <map<json>>nestedPropertiesResult;
                    descriptionsAdded += processSchemaProperties(nestedProperties, parentSchemaName + "." + propertyName);
                }
            }
            
            // Process items for arrays
            if propertyMap.hasKey("items") {
                json|error itemsResult = propertyMap.get("items");
                if itemsResult is map<json> {
                    map<json> items = <map<json>>itemsResult;
                    if items.hasKey("properties") {
                        json|error itemPropertiesResult = items.get("properties");
                        if itemPropertiesResult is map<json> {
                            map<json> itemProperties = <map<json>>itemPropertiesResult;
                            descriptionsAdded += processSchemaProperties(itemProperties, parentSchemaName + "." + propertyName + "[]");
                        }
                    }
                }
            }
        }
    }
    
    return descriptionsAdded;
}

// Helper function to process nested schemas (allOf, oneOf, anyOf)
function processNestedSchemas(map<json> schemaMap, string schemaName) returns int {
    int descriptionsAdded = 0;
    
    string[] nestedTypes = ["allOf", "oneOf", "anyOf"];
    
    foreach string nestedType in nestedTypes {
        if schemaMap.hasKey(nestedType) {
            json|error nestedResult = schemaMap.get(nestedType);
            if nestedResult is json[] {
                json[] nestedArray = nestedResult;
                foreach int i in 0 ..< nestedArray.length() {
                    json nestedItem = nestedArray[i];
                    if nestedItem is map<json> {
                        map<json> nestedItemMap = <map<json>>nestedItem;
                        
                        // Process properties in nested schemas
                        if nestedItemMap.hasKey("properties") {
                            json|error propertiesResult = nestedItemMap.get("properties");
                            if propertiesResult is map<json> {
                                map<json> properties = <map<json>>propertiesResult;
                                descriptionsAdded += processSchemaProperties(properties, schemaName + "." + nestedType + "[" + i.toString() + "]");
                            }
                        }
                    }
                }
            }
        }
    }
    
    return descriptionsAdded;
}

# Generate a meaningful name for an InlineResponse schema
#
# + schemaName - Original schema name (e.g., "InlineResponse20048")
# + schemaDefinition - Schema definition as JSON string
# + return - Generated meaningful name or error
public function generateSchemaName(string schemaName, string schemaDefinition) returns string|LLMServiceError {
    ai:ModelProvider? model = anthropicModel;
    if (model is ()) {
        return error LLMServiceError("LLM service not initialized");
    }

    string prompt = string `You are an API schema naming expert. Generate a meaningful, descriptive name for this OpenAPI schema that currently has a generic name "${schemaName}".

SCHEMA DEFINITION:
${schemaDefinition}

NAMING GUIDELINES:
CRITICAL: The generated schema names MUST be globally unique across the entire API specification.

1. Use PascalCase (e.g., UserProfile, ContactList, AttachmentResponse)
2. Make it descriptive but concise (2-4 words max)
3. Indicate what the schema represents (e.g., Response, Request, List, Details, etc.)
4. Consider the properties and their purpose
5. If it's a response with "data" array, consider what type of data it contains
6. If it uses allOf/oneOf, consider the combined meaning
7. Avoid generic terms like "Object", "Item", "Thing"
8. Avoid patterns that likely already exist like:
   - Simple entity names: User, Group, Sheet, Report, Folder, Workspace
   - Simple operations: Create, Delete, Update, Get, List
   - Common combinations: UserCreate, GroupDelete, SheetUpdate, etc.
   - Generic response names: Response, Result, Data
9. Be more specific and descriptive to ensure uniqueness

Examples of good UNIQUE names:
- Schema with user data array -> "UserCollectionApiResponse"
- Schema with attachment properties -> "AttachmentMetadataDetails" 
- Schema combining results -> "SearchQueryResultsResponse"
- Schema with proof attachments -> "ProofAttachmentListApiResponse"
- Schema with webhook events -> "WebhookEventNotificationResponse"

CRITICAL: Return ONLY the new schema name as a single word with no spaces, explanations, punctuation, or additional text. The name must be unique and specific enough to avoid conflicts.

Your response:`;

    ai:ChatMessage[] messages = [
        {role: "user", content: prompt}
    ];

    ai:ChatAssistantMessage|error response = model->chat(messages);
    if (response is error) {
        return error LLMServiceError("Failed to generate schema name", response);
    }

    string? content = response.content;
    if (content is string) {
        // Clean up the response to ensure it's a valid identifier
        string cleanName = content.trim();
        
        // Remove any quotes or extra characters
        cleanName = regex:replaceAll(cleanName, "[\"'`]", "");
        
        // Handle cases where LLM returns explanatory text followed by the actual name
        // Look for the last line that looks like a valid PascalCase identifier
        string[] lines = regex:split(cleanName, "\n");
        int i = lines.length() - 1;
        while (i >= 0) {
            string trimmedLine = lines[i].trim();
            // Check if this line looks like a valid schema name (PascalCase, no spaces, reasonable length)
            if (trimmedLine.length() > 0 && 
                trimmedLine.length() < 50 && 
                !trimmedLine.includes(" ") && 
                !trimmedLine.includes(".") && 
                !trimmedLine.includes(",") &&
                !trimmedLine.includes("?") &&
                !trimmedLine.includes("!") &&
                regex:matches(trimmedLine, "[A-Z][a-zA-Z0-9]*")) {
                return trimmedLine;
            }
            i = i - 1;
        }
        
        // If no valid line found, try to extract the first valid identifier from the entire response
        string[] words = regex:split(cleanName, "\\s+");
        foreach string word in words {
            string trimmedWord = word.trim();
            if (trimmedWord.length() > 0 && 
                trimmedWord.length() < 50 && 
                !trimmedWord.includes(".") && 
                !trimmedWord.includes(",") &&
                !trimmedWord.includes("?") &&
                !trimmedWord.includes("!") &&
                regex:matches(trimmedWord, "[A-Z][a-zA-Z0-9]*")) {
                return trimmedWord;
            }
        }
        
        // As a last resort, return a fallback name
        return "GeneratedResponse";
    } else {
        return error LLMServiceError("Empty response from LLM");
    }
}

// Helper function to validate if a generated name is safe for schema naming
function isValidSchemaName(string name) returns boolean {
    // Check basic requirements for a valid schema name
    if (name.length() == 0 || name.length() > 100) {
        return false;
    }
    
    // Should not contain spaces, special characters that could break JSON
    if (name.includes(" ") || name.includes("\n") || name.includes("\t") || 
        name.includes("\"") || name.includes("'") || name.includes("`") ||
        name.includes("{") || name.includes("}") || name.includes("[") || name.includes("]") ||
        name.includes(",") || name.includes(":") || name.includes(";") || 
        name.includes("?") || name.includes("!") || name.includes("\\") || 
        name.includes("/") || name.includes("<") || name.includes(">")) {
        return false;
    }
    
    // Should start with uppercase letter (PascalCase)
    string firstChar = name.substring(0, 1);
    if (!(firstChar >= "A" && firstChar <= "Z")) {
        return false;
    }
    
    // Should only contain alphanumeric characters
    return regex:matches(name, "[A-Z][a-zA-Z0-9]*");
}

// Helper function to check if a name is already taken
function isNameTaken(string name, string[] existingNames, map<string> nameMapping) returns boolean {
    // Check against existing schema names
    foreach string existingName in existingNames {
        if (existingName == name) {
            return true;
        }
    }
    
    // Check against already mapped names
    foreach string key in nameMapping.keys() {
        string? mappedName = nameMapping[key];
        if (mappedName is string && mappedName == name) {
            return true;
        }
    }
    
    return false;
}

// Helper function to update schema references throughout the JSON structure
function updateSchemaReferences(json jsonData, map<string> nameMapping) returns json {
    if (jsonData is map<json>) {
        map<json> resultMap = {};
        
        foreach string key in jsonData.keys() {
            json|error value = jsonData.get(key);
            if (value is json) {
                if (key == "$ref" && value is string) {
                    // Update schema reference if it matches a renamed schema
                    string refValue = <string>value;
                    if (refValue.startsWith("#/components/schemas/")) {
                        string schemaName = refValue.substring(21); // Remove "#/components/schemas/"
                        string? newName = nameMapping[schemaName];
                        if (newName is string) {
                            string newRef = "#/components/schemas/" + newName;
                            resultMap[key] = newRef;
                            log:printInfo("Updated schema reference", oldRef = refValue, newRef = newRef);
                        } else {
                            resultMap[key] = value;
                        }
                    } else {
                        resultMap[key] = value;
                    }
                } else {
                    // Recursively process nested structures
                    resultMap[key] = updateSchemaReferences(value, nameMapping);
                }
            }
        }
        
        return resultMap;
    } else if (jsonData is json[]) {
        json[] resultArray = [];
        foreach json item in jsonData {
            resultArray.push(updateSchemaReferences(item, nameMapping));
        }
        return resultArray;
    } else {
        // Primitive values remain unchanged
        return jsonData;
    }
}

# Rename InlineResponse schemas to meaningful names in OpenAPI spec
#
# + specFilePath - Path to the OpenAPI specification file
# + return - Number of schemas renamed or error
public function renameInlineResponseSchemas(string specFilePath) returns int|LLMServiceError {
    log:printInfo("Processing OpenAPI spec to rename InlineResponse schemas", specPath = specFilePath);
    
    // Read the OpenAPI spec file
    json|error specResult = io:fileReadJson(specFilePath);
    if specResult is error {
        return error LLMServiceError("Failed to read OpenAPI spec file", specResult);
    }
    
    json specJson = specResult;
    
    if !(specJson is map<json>) {
        return error LLMServiceError("Invalid OpenAPI spec format");
    }
    
    map<json> specMap = <map<json>>specJson;
    
    // Get components/schemas
    json|error componentsResult = specMap.get("components");
    if !(componentsResult is map<json>) {
        return error LLMServiceError("No components section found in OpenAPI spec");
    }
    
    map<json> components = <map<json>>componentsResult;
    json|error schemasResult = components.get("schemas");
    if !(schemasResult is map<json>) {
        return error LLMServiceError("No schemas section found in components");
    }
    
    map<json> schemas = <map<json>>schemasResult;
    
    // First, collect all existing schema names to ensure global uniqueness
    string[] allExistingNames = [];
    foreach string schemaName in schemas.keys() {
        if (!schemaName.startsWith("InlineResponse")) {
            allExistingNames.push(schemaName);
        }
    }
    
    // Find all InlineResponse schemas and generate new names
    map<string> nameMapping = {};
    int renamedCount = 0;
    
    foreach string schemaName in schemas.keys() {
        if (schemaName.startsWith("InlineResponse")) {
            json|error schemaResult = schemas.get(schemaName);
            if (schemaResult is map<json>) {
                map<json> schemaMap = <map<json>>schemaResult;
                string schemaDefinition = schemaMap.toString();
                
                string|LLMServiceError newName = generateSchemaName(schemaName, schemaDefinition);
                if (newName is string) {
                    // Validate that the generated name is safe for JSON and schema naming
                    if (isValidSchemaName(newName)) {
                        // Ensure the new name doesn't conflict with ANY existing schema names
                        string finalName = newName;
                        int counter = 1;
                        while (isNameTaken(finalName, allExistingNames, nameMapping)) {
                            finalName = newName + counter.toString();
                            counter += 1;
                        }
                        
                        // Add the final name to our tracking list to prevent future conflicts
                        allExistingNames.push(finalName);
                        nameMapping[schemaName] = finalName;
                        log:printInfo("Generated new name for schema", oldName = schemaName, newName = finalName);
                        renamedCount += 1;
                    } else {
                        log:printWarn("Generated name is not valid, using fallback", 
                                     schema = schemaName, invalidName = newName);
                        string fallbackBaseName = "Schema" + schemaName.substring(14); // Remove "InlineResponse"
                        string fallbackName = fallbackBaseName;
                        int counter = 1;
                        while (isNameTaken(fallbackName, allExistingNames, nameMapping)) {
                            fallbackName = fallbackBaseName + counter.toString();
                            counter += 1;
                        }
                        allExistingNames.push(fallbackName);
                        nameMapping[schemaName] = fallbackName;
                        renamedCount += 1;
                    }
                } else {
                    log:printError("Failed to generate name for schema", schema = schemaName, 'error = newName);
                }
            }
        }
    }
    
    // Apply the renaming
    if (nameMapping.length() > 0) {
        // First, rename the schema definitions in the schemas map
        map<json> newSchemas = {};
        foreach string oldName in schemas.keys() {
            json|error schemaValue = schemas.get(oldName);
            if (schemaValue is json) {
                if (nameMapping.hasKey(oldName)) {
                    string? newNameResult = nameMapping[oldName];
                    if (newNameResult is string) {
                        newSchemas[newNameResult] = schemaValue;
                    }
                } else {
                    newSchemas[oldName] = schemaValue;
                }
            }
        }
        
        // Update the schemas in the components section
        components["schemas"] = newSchemas;
        specMap["components"] = components;
        
        // Update all $ref references throughout the spec
        json updatedSpecResult = updateSchemaReferences(specMap, nameMapping);
        
        // Write the updated spec back to file
        error? writeResult = io:fileWriteJson(specFilePath, updatedSpecResult);
        if (writeResult is error) {
            return error LLMServiceError("Failed to write updated OpenAPI spec", writeResult);
        }
    }
    
    return renamedCount;
}

// # Fix Ballerina compilation errors by directly modifying the code
// #
// # + errorMessages - Array of error messages
// # + typesFilePath - Path to the types.bal file that needs fixing
// # + return - Success status and description of changes made
// public function fixBallerinaCodeErrors(string[] errorMessages, string typesFilePath) returns [boolean, string]|LLMServiceError {
//     ai:ModelProvider? model = anthropicModel;
//     if (model is ()) {
//         return error LLMServiceError("LLM service not initialized");
//     }

//     // Read the current types.bal file
//     string|error fileContent = io:fileReadString(typesFilePath);
//     if (fileContent is error) {
//         return error LLMServiceError("Failed to read types.bal file", fileContent);
//     }

//     string errorsText = string:'join("\n", ...errorMessages);
//     string prompt = string `You are a Ballerina programming expert. Fix the following compilation errors in the Ballerina code.

// ERRORS TO FIX:
// ${errorsText}

// CURRENT CODE:
// ${fileContent}

// INSTRUCTIONS:
// 1. Analyze each error and determine the exact fix needed
// 2. For field type conflicts, adjust the types to be compatible (e.g., use 'decimal' instead of 'int' if needed)
// 3. For missing tokens, add the required syntax elements
// 4. Return the COMPLETE fixed code for the entire file
// 5. Preserve all existing code structure and only make minimal necessary changes
// 6. Ensure all record types and field definitions are valid Ballerina syntax

// Return only the corrected Ballerina code without any explanations or markdown formatting.`;

//     ai:ChatMessage[] messages = [
//         {role: "user", content: prompt}
//     ];

//     ai:ChatAssistantMessage|error response = model->chat(messages);
//     if (response is error) {
//         return error LLMServiceError("Failed to generate code fixes", response);
//     }

//     string? fixedCode = response.content;
//     if (fixedCode is ()) {
//         return error LLMServiceError("Empty response from LLM");
//     }

//     // Write the fixed code back to the file
//     error? writeResult = io:fileWriteString(typesFilePath, fixedCode);
//     if (writeResult is error) {
//         return error LLMServiceError("Failed to write fixed code to file", writeResult);
//     }

//     return [true, string `Fixed ${errorMessages.length()} compilation errors in ${typesFilePath}`];
// }

