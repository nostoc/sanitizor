import ballerina/regex;
import ballerina/log;

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

// Helper function to update parameter description in spec
function updateParameterDescriptionInSpec(map<json> paths, string location, string description) returns error? {
    // Parse location: paths.{path}.{method}.parameters[name={paramName}]
    if location.startsWith("paths.") {
        string locationWithoutPrefix = location.substring(6); // Remove "paths."
        
        // Find the first dot to separate path from method
        int? firstDot = locationWithoutPrefix.indexOf(".");
        if firstDot is int {
            string path = locationWithoutPrefix.substring(0, firstDot);
            string remainingLocation = locationWithoutPrefix.substring(firstDot + 1);
            
            // Find second dot to separate method from parameters
            int? secondDot = remainingLocation.indexOf(".");
            if secondDot is int {
                string method = remainingLocation.substring(0, secondDot);
                string paramLocation = remainingLocation.substring(secondDot + 1);
                
                // Extract parameter name from parameters[name={paramName}]
                if paramLocation.startsWith("parameters[name=") && paramLocation.endsWith("]") {
                    string paramName = paramLocation.substring(16, paramLocation.length() - 1); // Remove "parameters[name=" and "]"
                    
                    json|error pathItem = paths.get(path);
                    if pathItem is map<json> {
                        map<json> pathItemMap = <map<json>>pathItem;
                        
                        if pathItemMap.hasKey(method) {
                            json|error operation = pathItemMap.get(method);
                            if operation is map<json> {
                                map<json> operationMap = <map<json>>operation;
                                
                                if operationMap.hasKey("parameters") {
                                    json|error parametersResult = operationMap.get("parameters");
                                    if parametersResult is json[] {
                                        json[] parameters = parametersResult;
                                        
                                        // Find the parameter by name
                                        foreach int i in 0 ..< parameters.length() {
                                            json param = parameters[i];
                                            if param is map<json> {
                                                map<json> paramMap = <map<json>>param;
                                                if paramMap.hasKey("name") && paramMap.get("name") == paramName {
                                                    paramMap["description"] = description;
                                                    return ();
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    return error("Could not find parameter at location: " + location);
}

// Helper function to update operation description in spec
function updateOperationDescriptionInSpec(map<json> paths, string location, string description) returns error? {
    // Parse location: paths.{path}.{method}
    if location.startsWith("paths.") {
        string locationWithoutPrefix = location.substring(6); // Remove "paths."
        
        // Find the first dot to separate path from method
        int? firstDot = locationWithoutPrefix.indexOf(".");
        if firstDot is int {
            string path = locationWithoutPrefix.substring(0, firstDot);
            string method = locationWithoutPrefix.substring(firstDot + 1);
            
            json|error pathItem = paths.get(path);
            if pathItem is map<json> {
                map<json> pathItemMap = <map<json>>pathItem;
                
                if pathItemMap.hasKey(method) {
                    json|error operation = pathItemMap.get(method);
                    if operation is map<json> {
                        map<json> operationMap = <map<json>>operation;
                        operationMap["description"] = description;
                        return ();
                    }
                }
            }
        }
    }
    
    return error("Could not find operation at location: " + location);
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

// Helper function to update operationId in the spec
function updateOperationIdInSpec(map<json> paths, string location, string operationId) returns error? {
    string[] locationParts = regex:split(location, "\\.");
    if locationParts.length() != 2 {
        return error("Invalid location format: " + location);
    }

    string path = locationParts[0];
    string method = locationParts[1];

    json|error pathItem = paths.get(path);
    if pathItem is map<json> {
        map<json> pathItemMap = <map<json>>pathItem;

        if pathItemMap.hasKey(method) {
            json|error operation = pathItemMap.get(method);
            if operation is map<json> {
                map<json> operationMap = <map<json>>operation;
                operationMap["operationId"] = operationId;
                return ();
            }
        }
    }

    return error("Could not find operation at location: " + location);
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