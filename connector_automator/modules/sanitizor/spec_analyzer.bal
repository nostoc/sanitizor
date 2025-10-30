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

// Helper function to collect existing operationIds from paths
function collectExistingOperationIds(map<json> paths, string[] existingOperationIds) {
    string[] httpMethods = ["get", "post", "put", "delete", "patch", "head", "options", "trace"];

    foreach string path in paths.keys() {
        json|error pathItem = paths.get(path);
        if pathItem is map<json> {
            map<json> pathItemMap = <map<json>>pathItem;

            foreach string method in httpMethods {
                if pathItemMap.hasKey(method) {
                    json|error operation = pathItemMap.get(method);
                    if operation is map<json> {
                        map<json> operationMap = <map<json>>operation;
                        if operationMap.hasKey("operationId") {
                            json|error operationIdResult = operationMap.get("operationId");
                            if operationIdResult is string {
                                existingOperationIds.push(<string>operationIdResult);
                            }
                        }
                    }
                }
            }
        }
    }
}


// Helper function to collect missing operationId requests
function collectMissingOperationIdRequests(map<json> paths, OperationIdRequest[] requests,
        map<string> locationMap, string apiContext) {
    string[] httpMethods = ["get", "post", "put", "delete", "patch", "head", "options", "trace"];

    foreach string path in paths.keys() {
        json|error pathItem = paths.get(path);
        if pathItem is map<json> {
            map<json> pathItemMap = <map<json>>pathItem;

            foreach string method in httpMethods {
                if pathItemMap.hasKey(method) {
                    json|error operationResult = pathItemMap.get(method);
                    if operationResult is map<json> {
                        map<json> operation = <map<json>>operationResult;

                        // Check if operationId is missing
                        if !operation.hasKey("operationId") {
                            string requestId = generateOperationRequestId(path, method);
                            string location = string `${path}.${method}`;

                            // Safely extract optional fields
                            string? summary = ();
                            if operation.hasKey("summary") {
                                json summaryJson = operation.get("summary");
                                if summaryJson is string {
                                    summary = summaryJson;
                                }
                            }

                            string? description = ();
                            if operation.hasKey("description") {
                                json descriptionJson = operation.get("description");
                                if descriptionJson is string {
                                    description = descriptionJson;
                                }
                            }

                            string[]? tags = ();
                            if operation.hasKey("tags") {
                                json tagsJson = operation.get("tags");
                                if tagsJson is json[] {
                                    string[] tagStrings = [];
                                    foreach json tag in tagsJson {
                                        if tag is string {
                                            tagStrings.push(tag);
                                        }
                                    }
                                    if tagStrings.length() > 0 {
                                        tags = tagStrings;
                                    }
                                }
                            }

                            OperationIdRequest request = {
                                id: requestId,
                                path: path,
                                method: method,
                                summary: summary,
                                description: description,
                                tags: tags
                            };

                            requests.push(request);
                            locationMap[requestId] = location;
                        }
                    }
                }
            }
        }
    }
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
