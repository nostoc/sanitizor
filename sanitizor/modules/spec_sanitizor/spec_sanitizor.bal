import ballerina/ai;
import ballerina/io;
import ballerina/lang.runtime;
import ballerina/log;
import ballerina/regex;
import ballerinax/ai.anthropic;

public type LLMServiceError distinct error; // custom error type for LLM related failures

// Batch processing types
public type DescriptionRequest record {
    string id;
    string name;
    string context;
    string schemaPath; // e.g., "User.properties.email" or "User"
};

public type SchemaRenameRequest record {
    string originalName;
    string schemaDefinition;
    string usageContext;
};

public type BatchDescriptionResponse record {
    string id;
    string description;
};

public type BatchRenameResponse record {
    string originalName;
    string newName;
};

// Retry configuration
public type RetryConfig record {
    int maxRetries = 3;
    decimal initialDelaySeconds = 1.0;
    decimal maxDelaySeconds = 60.0;
    decimal backoffMultiplier = 2.0;
    boolean jitter = true;
};

configurable string apiKey = ?;
configurable RetryConfig retryConfig = {};

ai:ModelProvider? anthropicModel = ();

# Initialize the LLM service
#
# + quietMode - Whether to suppress verbose logging
# + return - return value description
public function initLLMService(boolean quietMode = false) returns LLMServiceError? {

    ai:ModelProvider|error modelProvider = new anthropic:ModelProvider(
        apiKey,
        anthropic:CLAUDE_SONNET_4_20250514,
        maxTokens = 60000,
        timeout = 300
    );

    if modelProvider is error {
        return error LLMServiceError("Failed to initialize Anthropic model provider", modelProvider);
    }

    anthropicModel = modelProvider;
    if !quietMode {
        log:printInfo("LLM service initialized successfully");
    }
}

// Helper function to calculate exponential backoff delay
function calculateBackoffDelay(int attempt, RetryConfig config) returns decimal {
    decimal delay = config.initialDelaySeconds;

    // Calculate exponential backoff manually
    int i = 0;
    while i < attempt {
        delay = delay * config.backoffMultiplier;
        i += 1;
    }

    // Cap at maximum delay
    if delay > config.maxDelaySeconds {
        delay = config.maxDelaySeconds;
    }

    // Add simple jitter to avoid thundering herd
    if config.jitter {
        // Add random jitter up to 25% of the delay (simplified)
        decimal jitterRange = delay * 0.25d;
        // Use a simple pseudo-random approach
        decimal randomValue = <decimal>(attempt % 100) / 100.0d;
        decimal randomJitter = (randomValue * jitterRange * 2.0d) - jitterRange;
        delay = delay + randomJitter;

        // Ensure delay is not negative
        if delay < 0.1d {
            delay = 0.1d;
        }
    }

    return delay;
}

// Helper function to determine if an error is retryable
function isRetryableError(error err) returns boolean {
    string message = err.message().toLowerAscii();

    // Retry on these types of errors
    boolean isNetworkError = message.includes("network") ||
                            message.includes("connection") ||
                            message.includes("timeout") ||
                            message.includes("socket");

    boolean isRateLimitError = message.includes("rate limit") ||
                            message.includes("429") ||
                            message.includes("too many requests");

    boolean isServerError = message.includes("500") ||
                        message.includes("502") ||
                        message.includes("503") ||
                        message.includes("504") ||
                        message.includes("server error");

    boolean isTemporaryError = message.includes("temporary") ||
                            message.includes("unavailable") ||
                            message.includes("overloaded");

    return isNetworkError || isRateLimitError || isServerError || isTemporaryError;
}

# Process multiple description requests with retry and exponential backoff
#
# + requests - Array of description requests to process
# + apiContext - API context for better descriptions
# + quietMode - Whether to suppress verbose logging
# + config - Retry configuration (optional, uses default if not provided)
# + return - Array of generated descriptions or error
public function generateDescriptionsBatchWithRetry(DescriptionRequest[] requests, string apiContext, boolean quietMode = false, RetryConfig? config = ()) returns BatchDescriptionResponse[]|LLMServiceError {
    RetryConfig retryConf = config ?: retryConfig;

    int attempt = 0;
    while attempt <= retryConf.maxRetries {
        BatchDescriptionResponse[]|LLMServiceError result = generateDescriptionsBatch(requests, apiContext);

        if result is BatchDescriptionResponse[] {
            if !quietMode && attempt > 0 {
                log:printInfo("Batch description generation succeeded after retry", attempt = attempt);
            }
            return result;
        } else {
            // Check if this is the last attempt
            if attempt == retryConf.maxRetries {
                if !quietMode {
                    log:printError("Batch description generation failed after all retries",
                            finalAttempt = attempt, maxRetries = retryConf.maxRetries, 'error = result);
                }
                return result;
            }

            // Check if error is retryable
            if !isRetryableError(result) {
                if !quietMode {
                    log:printError("Non-retryable error in batch description generation", 'error = result);
                }
                return result;
            }

            // Calculate backoff delay and wait
            decimal delay = calculateBackoffDelay(attempt, retryConf);
            if !quietMode {
                log:printWarn("Batch description generation failed, retrying",
                        attempt = attempt + 1, maxRetries = retryConf.maxRetries,
                        delaySeconds = delay, 'error = result);
            }

            runtime:sleep(delay);
            attempt += 1;
        }
    }

    // This should never be reached, but just in case
    return error LLMServiceError("Unexpected error in retry logic");
}

# Process multiple schema rename requests with retry and exponential backoff
#
# + requests - Array of schema rename requests
# + apiContext - API context for better naming
# + existingNames - Existing schema names to avoid conflicts
# + quietMode - Whether to suppress verbose logging
# + config - Retry configuration (optional, uses default if not provided)
# + return - Array of new schema names or error
public function generateSchemaNamesBatchWithRetry(SchemaRenameRequest[] requests, string apiContext, string[] existingNames, boolean quietMode = false, RetryConfig? config = ()) returns BatchRenameResponse[]|LLMServiceError {
    RetryConfig retryConf = config ?: retryConfig;

    int attempt = 0;
    while attempt <= retryConf.maxRetries {
        BatchRenameResponse[]|LLMServiceError result = generateSchemaNamesBatch(requests, apiContext, existingNames);

        if result is BatchRenameResponse[] {
            if attempt > 0 {
                log:printInfo("Batch schema naming succeeded after retry", attempt = attempt);
            }
            return result;
        } else {
            // Check if this is the last attempt
            if attempt == retryConf.maxRetries {
                log:printError("Batch schema naming failed after all retries",
                        finalAttempt = attempt, maxRetries = retryConf.maxRetries, 'error = result);
                return result;
            }

            // Check if error is retryable
            if !isRetryableError(result) {
                log:printError("Non-retryable error in batch schema naming", 'error = result);
                return result;
            }

            // Calculate backoff delay and wait
            decimal delay = calculateBackoffDelay(attempt, retryConf);
            log:printWarn("Batch schema naming failed, retrying",
                    attempt = attempt + 1, maxRetries = retryConf.maxRetries,
                    delaySeconds = delay, 'error = result);

            runtime:sleep(delay);
            attempt += 1;
        }
    }

    // This should never be reached, but just in case
    return error LLMServiceError("Unexpected error in retry logic");
}

# Enhanced batch processing version of addMissingDescriptions with retry
#
# + specFilePath - Path to the OpenAPI specification file
# + batchSize - Number of items to process per batch (default: 20)
# + quietMode - Whether to suppress verbose logging
# + config - Retry configuration (optional, uses default if not provided)
# + return - Number of descriptions added or error
public function addMissingDescriptionsBatchWithRetry(string specFilePath, int batchSize = 20, boolean quietMode = false, RetryConfig? config = ()) returns int|LLMServiceError {
    if !quietMode {
        log:printInfo("Processing OpenAPI spec for missing descriptions (batch mode with retry)",
                specPath = specFilePath, batchSize = batchSize);
    }

    // Read the OpenAPI spec file
    json|error specResult = io:fileReadJson(specFilePath);
    if specResult is error {
        return error LLMServiceError("Failed to read OpenAPI spec file", specResult);
    }

    json specJson = specResult;
    int descriptionsAdded = 0;

    if specJson is map<json> {
        json|error componentsResult = specJson.get("components");
        if componentsResult is map<json> {
            json|error schemasResult = componentsResult.get("schemas");
            if schemasResult is map<json> {
                map<json> schemas = <map<json>>schemasResult;
                string apiContext = extractApiContext(specJson);

                // Collect all missing description requests
                DescriptionRequest[] allRequests = [];
                map<string> requestToLocationMap = {}; // Map request ID to location for updating

                foreach string schemaName in schemas.keys() {
                    json|error schemaResult = schemas.get(schemaName);
                    if schemaResult is map<json> {
                        map<json> schemaMap = <map<json>>schemaResult;

                        // Collect schema-level and property-level description requests
                        collectDescriptionRequests(schemaMap, schemaName, "", allRequests, requestToLocationMap, specJson);
                    }
                }

                // Process requests in batches with retry
                int totalRequests = allRequests.length();
                if !quietMode {
                    log:printInfo("Collected description requests", totalRequests = totalRequests);
                }

                int startIdx = 0;
                while startIdx < totalRequests {
                    int endIdx = startIdx + batchSize;
                    if endIdx > totalRequests {
                        endIdx = totalRequests;
                    }

                    DescriptionRequest[] batch = allRequests.slice(startIdx, endIdx);
                    if !quietMode {
                        log:printInfo("Processing batch with retry", batchNumber = (startIdx / batchSize) + 1,
                                batchSize = batch.length());
                    }

                    BatchDescriptionResponse[]|LLMServiceError batchResult = generateDescriptionsBatchWithRetry(batch, apiContext, quietMode, config);
                    if batchResult is BatchDescriptionResponse[] {
                        // Apply the generated descriptions
                        foreach BatchDescriptionResponse response in batchResult {
                            string? location = requestToLocationMap[response.id];
                            if location is string {
                                error? updateResult = updateDescriptionInSpec(schemas, location, response.description);
                                if updateResult is () {
                                    descriptionsAdded += 1;
                                    if !quietMode {
                                        log:printInfo("Applied batch description", id = response.id, location = location);
                                    }
                                } else {
                                    log:printError("Failed to apply description", id = response.id, 'error = updateResult);
                                }
                            }
                        }
                    } else {
                        if !quietMode {
                            log:printError("Batch processing failed after all retries", batchNumber = (startIdx / batchSize) + 1, 'error = batchResult);
                        }
                        // Continue with next batch instead of failing completely
                    }
                    startIdx += batchSize;
                }

                // Update the spec with modified schemas
                componentsResult["schemas"] = schemas;
                specJson["components"] = componentsResult;
            }
        }
    }

    // Save updated spec back to file
    error? writeResult = io:fileWriteJson(specFilePath, specJson);
    if writeResult is error {
        return error LLMServiceError("Failed to write updated OpenAPI spec", writeResult);
    }

    return descriptionsAdded;
}

# Batch version of renameInlineResponseSchemas with retry and configurable batch size
#
# + specFilePath - Path to the OpenAPI specification file
# + batchSize - Number of schemas to process per batch (default: 10)
# + quietMode - Whether to suppress verbose logging
# + config - Retry configuration (optional, uses default if not provided)
# + return - Number of schemas renamed or error
public function renameInlineResponseSchemasBatchWithRetry(string specFilePath, int batchSize = 10, boolean quietMode = false, RetryConfig? config = ()) returns int|LLMServiceError {
    if !quietMode {
        log:printInfo("Processing OpenAPI spec to rename InlineResponse schemas (batch mode with retry)",
                specPath = specFilePath, batchSize = batchSize);
    }

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

    // Collect all existing schema names to ensure global uniqueness
    string[] allExistingNames = [];
    foreach string schemaName in schemas.keys() {
        if (!schemaName.startsWith("InlineResponse")) {
            allExistingNames.push(schemaName);
        }
    }

    // Collect all InlineResponse schemas for batch processing
    SchemaRenameRequest[] renameRequests = [];
    string apiContext = extractApiContext(specMap);

    foreach string schemaName in schemas.keys() {
        if (schemaName.startsWith("InlineResponse") || schemaName.endsWith("AllOf2") || schemaName.endsWith("OneOf2")) {
            json|error schemaResult = schemas.get(schemaName);
            if (schemaResult is map<json>) {
                string schemaDefinition = (<map<json>>schemaResult).toJsonString();
                string usageContext = extractSchemaUsageContext(schemaName, specMap);

                renameRequests.push({
                    originalName: schemaName,
                    schemaDefinition: schemaDefinition,
                    usageContext: usageContext
                });
            }
        }
    }

    if renameRequests.length() == 0 {
        if !quietMode {
            log:printInfo("No InlineResponse schemas found to rename");
        }
        return 0;
    }

    map<string> nameMapping = {};
    int renamedCount = 0;
    int totalRequests = renameRequests.length();

    if !quietMode {
        log:printInfo("Collected schema rename requests", totalRequests = totalRequests);
    }

    // Process requests in batches with retry
    int startIdx = 0;
    while startIdx < totalRequests {
        int endIdx = startIdx + batchSize;
        if endIdx > totalRequests {
            endIdx = totalRequests;
        }

        SchemaRenameRequest[] batch = renameRequests.slice(startIdx, endIdx);
        if !quietMode {
            log:printInfo("Processing schema rename batch with retry", batchNumber = (startIdx / batchSize) + 1,
                    batchSize = batch.length());
        }

        BatchRenameResponse[]|LLMServiceError batchResult = generateSchemaNamesBatchWithRetry(batch, apiContext, allExistingNames, quietMode, config);
        if batchResult is BatchRenameResponse[] {
            // Process the generated names
            foreach BatchRenameResponse response in batchResult {
                string newName = response.newName;

                // Validate that the generated name is safe for JSON and schema naming
                if (isValidSchemaName(newName)) {
                    // Double-check uniqueness (LLM should handle this, but safety first)
                    if (!isNameTaken(newName, allExistingNames, nameMapping)) {
                        // Add the name to our tracking list to prevent future conflicts
                        allExistingNames.push(newName);
                        nameMapping[response.originalName] = newName;
                        if !quietMode {
                            log:printInfo("Generated new name for schema", oldName = response.originalName, newName = newName);
                        }
                        renamedCount += 1;
                    } else {
                        // Fallback if LLM somehow generated a duplicate
                        log:printWarn("LLM generated duplicate name, using fallback",
                                schema = response.originalName, duplicateName = newName);
                        string fallbackName = newName + "Alt";
                        int counter = 1;
                        while (isNameTaken(fallbackName, allExistingNames, nameMapping)) {
                            fallbackName = newName + "Alt" + counter.toString();
                            counter += 1;
                        }
                        allExistingNames.push(fallbackName);
                        nameMapping[response.originalName] = fallbackName;
                        renamedCount += 1;
                    }
                } else {
                    log:printWarn("Generated name is not valid, using fallback",
                            schema = response.originalName, invalidName = newName);
                    string fallbackBaseName = "Schema" + response.originalName.substring(14);
                    string fallbackName = fallbackBaseName;
                    int counter = 1;
                    while (isNameTaken(fallbackName, allExistingNames, nameMapping)) {
                        fallbackName = fallbackBaseName + counter.toString();
                        counter += 1;
                    }
                    allExistingNames.push(fallbackName);
                    nameMapping[response.originalName] = fallbackName;
                    renamedCount += 1;
                }
            }
        } else {
            if !quietMode {
                log:printError("Schema rename batch processing failed after all retries",
                        batchNumber = (startIdx / batchSize) + 1, 'error = batchResult);
            }
            // Continue with next batch instead of failing completely
        }

        startIdx += batchSize;
    }

    // Apply the renaming if we have any mappings
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
        json updatedSpecResult = updateSchemaReferences(specMap, nameMapping, quietMode);

        // Write the updated spec back to file
        error? writeResult = io:fileWriteJson(specFilePath, updatedSpecResult);
        if (writeResult is error) {
            return error LLMServiceError("Failed to write updated OpenAPI spec", writeResult);
        }
    }

    return renamedCount;
}

# Process multiple description requests in a single LLM call
#
# + requests - Array of description requests to process
# + apiContext - API context for better descriptions
# + return - Array of generated descriptions or error
public function generateDescriptionsBatch(DescriptionRequest[] requests, string apiContext) returns BatchDescriptionResponse[]|LLMServiceError {
    ai:ModelProvider? model = anthropicModel;
    if model is () {
        return error LLMServiceError("LLM service not initialized");
    }

    if requests.length() == 0 {
        return [];
    }

    // Build batch prompt
    string requestsSection = "";
    foreach int i in 0 ..< requests.length() {
        DescriptionRequest req = requests[i];
        requestsSection += string `
${i + 1}. ID: ${req.id}
   Name: ${req.name}
   Path: ${req.schemaPath}
   Context: ${req.context}
`;
    }

    string prompt = string `You are an API documentation expert. Generate concise, professional descriptions for the following fields/schemas.

API CONTEXT:
${apiContext}

REQUESTS TO PROCESS:
${requestsSection}

INSTRUCTIONS:
1. For each request, generate a description under 100 characters
2. Use professional API documentation language
3. Consider the API context and field context
4. Return responses in the exact JSON format shown below
5. Do not include fenced code blocks in the response. 
6. Keep the descriptions concise under 80 characters but informative

REQUIRED RESPONSE FORMAT (JSON):
{
  "descriptions": [
    {
      "id": "request_id_1",
      "description": "Generated description text"
    },
    {
      "id": "request_id_2", 
      "description": "Generated description text"
    }
  ]
}`;

    ai:ChatMessage[] messages = [
        {role: "user", content: prompt}
    ];

    ai:ChatAssistantMessage|error response = model->chat(messages);
    if response is error {
        return error LLMServiceError("Failed to generate batch descriptions", response);
    }

    string? content = response.content;
    if content is string {
        // Parse JSON response
        json|error jsonResult = content.fromJsonString();
        if jsonResult is error {
            return error LLMServiceError("Failed to parse batch response JSON", jsonResult);
        }

        if jsonResult is map<json> && jsonResult.hasKey("descriptions") {
            json descriptionsJson = jsonResult.get("descriptions");
            if descriptionsJson is json[] {
                BatchDescriptionResponse[] results = [];
                foreach json desc in descriptionsJson {
                    if desc is map<json> {
                        string? id = desc.get("id") is string ? <string>desc.get("id") : ();
                        string? description = desc.get("description") is string ? <string>desc.get("description") : ();
                        if id is string && description is string {
                            results.push({id: id, description: description.trim()});
                        }
                    }
                }
                return results;
            }
        }
        return error LLMServiceError("Invalid batch response format");
    } else {
        return error LLMServiceError("Empty response from LLM");
    }
}

# Process multiple schema rename requests in a single LLM call
#
# + requests - Array of schema rename requests
# + apiContext - API context for better naming
# + existingNames - Existing schema names to avoid conflicts
# + return - Array of new schema names or error
public function generateSchemaNamesBatch(SchemaRenameRequest[] requests, string apiContext, string[] existingNames) returns BatchRenameResponse[]|LLMServiceError {
    ai:ModelProvider? model = anthropicModel;
    if model is () {
        return error LLMServiceError("LLM service not initialized");
    }

    if requests.length() == 0 {
        return [];
    }

    string requestsSection = "";
    foreach int i in 0 ..< requests.length() {
        SchemaRenameRequest req = requests[i];
        requestsSection += string `
${i + 1}. Original: ${req.originalName}
   Definition: ${req.schemaDefinition}
   Usage: ${req.usageContext}
`;
    }

    string existingNamesStr = string:'join(", ", ...existingNames);

    string prompt = string `You are an expert in naming OpenAPI schemas. Generate meaningful, unique PascalCase names for these schemas.

API CONTEXT:
${apiContext}

EXISTING SCHEMA NAMES (avoid conflicts):
${existingNamesStr}

SCHEMAS TO RENAME:
${requestsSection}

REQUIREMENTS:
- Use PascalCase (e.g., UserProfile, AttachmentResponse)
- Be descriptive but concise (2-4 words max)
- Ensure names are unique and don't conflict with existing names
- Consider schema role (Request, Response, List, Details, etc.)
- Do not include fenced code blocks in the response. 

REQUIRED RESPONSE FORMAT (JSON):
{
  "renames": [
    {
      "originalName": "InlineResponse200",
      "newName": "UserListResponse"
    },
    {
      "originalName": "InlineResponse201",
      "newName": "CreateUserResponse"
    }
  ]
}`;

    ai:ChatMessage[] messages = [
        {role: "user", content: prompt}
    ];

    ai:ChatAssistantMessage|error response = model->chat(messages);
    if response is error {
        return error LLMServiceError("Failed to generate batch schema names", response);
    }

    string? content = response.content;
    if content is string {
        json|error jsonResult = content.fromJsonString();
        if jsonResult is error {
            return error LLMServiceError("Failed to parse batch rename response JSON", jsonResult);
        }

        if jsonResult is map<json> && jsonResult.hasKey("renames") {
            json renamesJson = jsonResult.get("renames");
            if renamesJson is json[] {
                BatchRenameResponse[] results = [];
                foreach json rename in renamesJson {
                    if rename is map<json> {
                        string? originalName = rename.get("originalName") is string ? <string>rename.get("originalName") : ();
                        string? newName = rename.get("newName") is string ? <string>rename.get("newName") : ();
                        if originalName is string && newName is string {
                            results.push({originalName: originalName, newName: newName.trim()});
                        }
                    }
                }
                return results;
            }
        }
        return error LLMServiceError("Invalid batch rename response format");
    } else {
        return error LLMServiceError("Empty response from LLM");
    }
}

// Helper function to collect description requests from schema
function collectDescriptionRequests(map<json> schemaMap, string schemaName, string pathPrefix,
        DescriptionRequest[] requests, map<string> locationMap, json fullSpec) {
    // Check if schema itself needs description
    if !schemaMap.hasKey("description") {
        string requestId = generateRequestId(schemaName, pathPrefix, "schema");
        string context = string `Schema '${schemaName}' definition: ${schemaMap.toString()}`;
        requests.push({
            id: requestId,
            name: schemaName,
            context: context,
            schemaPath: pathPrefix.length() > 0 ? pathPrefix : schemaName
        });
        locationMap[requestId] = pathPrefix.length() > 0 ? pathPrefix : schemaName;
    }

    // Process properties
    if schemaMap.hasKey("properties") {
        json|error propertiesResult = schemaMap.get("properties");
        if propertiesResult is map<json> {
            map<json> properties = <map<json>>propertiesResult;
            collectPropertyDescriptionRequests(properties, schemaName, pathPrefix, requests, locationMap, fullSpec);
        }
    }

    // Process nested schemas (allOf, oneOf, anyOf)
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
                        string nestedPath = pathPrefix.length() > 0 ?
                            pathPrefix + "." + nestedType + "[" + i.toString() + "]" :
                            schemaName + "." + nestedType + "[" + i.toString() + "]";
                        collectDescriptionRequests(nestedItemMap, schemaName, nestedPath, requests, locationMap, fullSpec);
                    }
                }
            }
        }
    }
}

// Helper function to collect property description requests
function collectPropertyDescriptionRequests(map<json> properties, string parentSchemaName, string pathPrefix,
        DescriptionRequest[] requests, map<string> locationMap, json fullSpec) {
    foreach string propertyName in properties.keys() {
        json|error propertyResult = properties.get(propertyName);
        if propertyResult is map<json> {
            map<json> propertyMap = <map<json>>propertyResult;
            string propertyPath = pathPrefix.length() > 0 ?
                pathPrefix + ".properties." + propertyName :
                parentSchemaName + ".properties." + propertyName;

            // Check if property needs description (not $ref and no description)
            if !propertyMap.hasKey("description") && !propertyMap.hasKey("$ref") {
                string requestId = generateRequestId(parentSchemaName, propertyPath, "property");
                string context = string `Property '${propertyName}' in schema '${parentSchemaName}'. Property definition: ${propertyMap.toString()}`;
                requests.push({
                    id: requestId,
                    name: propertyName,
                    context: context,
                    schemaPath: propertyPath
                });
                locationMap[requestId] = propertyPath;
            }

            // Recursively process nested properties
            if propertyMap.hasKey("properties") {
                json|error nestedPropertiesResult = propertyMap.get("properties");
                if nestedPropertiesResult is map<json> {
                    map<json> nestedProperties = <map<json>>nestedPropertiesResult;
                    collectPropertyDescriptionRequests(nestedProperties, parentSchemaName, propertyPath, requests, locationMap, fullSpec);
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
                            string itemPath = propertyPath + ".items";
                            collectPropertyDescriptionRequests(itemProperties, parentSchemaName, itemPath, requests, locationMap, fullSpec);
                        }
                    }
                }
            }
        }
    }
}

// Helper function to generate unique request IDs
function generateRequestId(string schemaName, string path, string requestType) returns string {
    string cleanPath = regex:replaceAll(path, "\\.", "_");
    cleanPath = regex:replaceAll(cleanPath, "\\[", "_");
    cleanPath = regex:replaceAll(cleanPath, "\\]", "_");
    return string `${schemaName}_${requestType}_${cleanPath}`;
}

// Helper function to update description in spec using location path
function updateDescriptionInSpec(map<json> schemas, string location, string description) returns error? {
    string[] pathParts = regex:split(location, "\\.");

    if pathParts.length() == 1 {
        // Schema-level description
        string schemaName = pathParts[0];
        json|error schemaResult = schemas.get(schemaName);
        if schemaResult is map<json> {
            map<json> schemaMap = <map<json>>schemaResult;
            schemaMap["description"] = description;
            // No need to reassign since we're modifying the original reference
        }
    } else {
        // Property-level description - navigate to the correct location
        string schemaName = pathParts[0];
        json|error schemaResult = schemas.get(schemaName);
        if schemaResult is map<json> {
            error? result = updateNestedDescription(<map<json>>schemaResult, pathParts, 1, description);
            if result is error {
                return result;
            }
        }
    }

    return ();
}

// Recursive helper to safely update nested descriptions
function updateNestedDescription(map<json> current, string[] pathParts, int index, string description) returns error? {
    if index == pathParts.length() {
        // We've reached the target - add description
        current["description"] = description;
        return ();
    }

    string part = pathParts[index];

    if part.includes("[") {
        // Handle array indices like "allOf[0]"
        string[] indexParts = regex:split(part, "\\[");
        string arrayName = indexParts[0];
        string indexStr = regex:replaceAll(indexParts[1], "\\]", "");
        int|error indexResult = int:fromString(indexStr);

        if indexResult is int {
            json|error arrayResult = current.get(arrayName);
            if arrayResult is json[] {
                json[] array = arrayResult;
                if indexResult < array.length() && array[indexResult] is map<json> {
                    return updateNestedDescription(<map<json>>array[indexResult], pathParts, index + 1, description);
                }
            }
        }
    } else {
        json|error nextResult = current.get(part);
        if nextResult is map<json> {
            return updateNestedDescription(<map<json>>nextResult, pathParts, index + 1, description);
        }
    }

    return ();
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
function updateSchemaReferences(json jsonData, map<string> nameMapping, boolean quietMode = false) returns json {
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
                            if !quietMode {
                                log:printInfo("Updated schema reference", oldRef = refValue, newRef = newRef);
                            }
                        } else {
                            resultMap[key] = value;
                        }
                    } else {
                        resultMap[key] = value;
                    }
                } else {
                    // Recursively process nested structures
                    resultMap[key] = updateSchemaReferences(value, nameMapping, quietMode);
                }
            }
        }

        return resultMap;
    } else if (jsonData is json[]) {
        json[] resultArray = [];
        foreach json item in jsonData {
            resultArray.push(updateSchemaReferences(item, nameMapping, quietMode));
        }
        return resultArray;
    } else {
        // Primitive values remain unchanged
        return jsonData;
    }
}

// Helper function to extract API context (info section)
function extractApiContext(json spec) returns string {
    if (spec is map<json>) {
        json|error infoResult = spec.get("info");
        if (infoResult is map<json>) {
            map<json> infoMap = <map<json>>infoResult;

            string title = "Unknown API";
            if (infoMap.hasKey("title") && infoMap.get("title") is string) {
                title = <string>infoMap.get("title");
            }

            string description = "";
            if (infoMap.hasKey("description") && infoMap.get("description") is string) {
                description = <string>infoMap.get("description");
            }

            // Truncate description if too long to avoid token limits
            if (description.length() > 1000) {
                description = description.substring(0, 1000) + "...";
            }

            return string `API: ${title}
Description: ${description}`;
        }
    }
    return "API context not available";
}

// Helper function to extract usage context (where schema is referenced)
function extractSchemaUsageContext(string schemaName, json spec) returns string {
    string[] usages = [];
    string refPattern = string `#/components/schemas/${schemaName}`;

    if (spec is map<json>) {
        // Check paths for usage
        json|error pathsResult = spec.get("paths");
        if (pathsResult is map<json>) {
            map<json> paths = <map<json>>pathsResult;
            foreach string path in paths.keys() {
                json|error pathItem = paths.get(path);
                if (pathItem is map<json>) {
                    string pathUsages = findSchemaUsageInPathItem(path, <map<json>>pathItem, refPattern);
                    if (pathUsages.length() > 0) {
                        usages.push(pathUsages);
                    }
                }
            }
        }
    }

    if (usages.length() > 0) {
        return string:'join("\n", ...usages);
    }
    return string `Schema '${schemaName}' usage context not found`;
}

// Helper function to find schema usage in a path item
function findSchemaUsageInPathItem(string path, map<json> pathItem, string refPattern) returns string {
    string[] usages = [];

    // Define the possible HTTP methods to check for
    string[] possibleMethods = ["get", "post", "put", "delete", "patch", "head", "options", "trace"];

    // Dynamically check what methods are actually available in this path item
    foreach string method in possibleMethods {
        if (pathItem.hasKey(method)) {
            json|error operationResult = pathItem.get(method);
            if (operationResult is map<json>) {
                map<json> operation = <map<json>>operationResult;

                // Check if this operation uses the schema in request/response
                if (containsSchemaReference(operation, refPattern)) {
                    string? operationId = operation.get("operationId") is string ? <string>operation.get("operationId") : ();
                    string? summary = operation.get("summary") is string ? <string>operation.get("summary") : ();

                    string operationDesc = operationId ?: (summary ?: string `${method.toUpperAscii()} ${path}`);
                    usages.push(string `- Used in: ${operationDesc}`);
                }
            }
        }
    }

    return string:'join("\n", ...usages);
}

// Helper function to recursively check if JSON contains schema reference
function containsSchemaReference(json data, string refPattern) returns boolean {
    if (data is map<json>) {
        foreach string key in data.keys() {
            json|error value = data.get(key);
            if (value is json) {
                if (key == "$ref" && value is string && (<string>value).includes(refPattern)) {
                    return true;
                }
                if (containsSchemaReference(value, refPattern)) {
                    return true;
                }
            }
        }
    } else if (data is json[]) {
        foreach json item in data {
            if (containsSchemaReference(item, refPattern)) {
                return true;
            }
        }
    }
    return false;
}
