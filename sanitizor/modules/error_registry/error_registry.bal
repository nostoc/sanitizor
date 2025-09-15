import sanitizor.command_executor;

import ballerina/io;
import ballerina/log;
import ballerina/regex;

public type ErrorRegistryError distinct error;

# Error handling strategies
public enum ErrorHandlingStrategy {
    PROGRAMMATIC_SPEC_FIX,
    LLM_SPEC_FIX,
    LLM_BALLERINA_FIX,
    USER_PROMPT_REQUIRED,
    UNSUPPORTED
}

# Represents a known error pattern with its fix strategy
public type ErrorPattern record {|
    # Unique identifier for this error pattern
    string patternId;
    # Category of error (NAMING_CONFLICT, SYNTAX_ERROR, etc.)
    string category;
    # Error message pattern to match
    string message;
    # Human-readable description of the issue
    string description;
    # Strategy to use for fixing this error
    string fixStrategy;
    # Recommended error handling strategy
    ErrorHandlingStrategy handlingStrategy;
|};

# Result of applying a single fix
public type FixResult record {|
    # Whether the fix was successfully applied
    boolean success;
    # Number of changes made to the spec
    int changesApplied;
    # Description of what was fixed
    string fixDescription;
    # Any error that occurred during fixing
    string? errorMessage;
|};

# Result of applying multiple fixes in batch
public type BatchFixResult record {|
    # Whether all fixes were applied successfully  
    boolean overallSuccess;
    # Total number of errors processed
    int totalErrors;
    # Number of errors successfully fixed
    int fixedErrors;
    # Number of errors that couldn't be fixed
    int failedErrors;
    # Individual fix results
    FixResult[] individualResults;
    # Summary message
    string summary;
|};

# Registry of known error patterns
final readonly & ErrorPattern[] ERROR_PATTERNS = [
    {
        patternId: "REDECLARED_SYMBOL",
        category: "NAMING_CONFLICT",
        message: "redeclared symbol",
        description: "Multiple properties with the same name cause compilation conflicts",
        fixStrategy: "REMOVE_CONFLICTING_PROPERTY",
        handlingStrategy: PROGRAMMATIC_SPEC_FIX
    },
    {
        patternId: "UNDOCUMENTED_FIELD",
        category: "DOCUMENTATION_WARNING",
        message: "undocumented field",
        description: "Field lacks documentation comments",
        fixStrategy: "ADD_FIELD_DOCUMENTATION",
        handlingStrategy: LLM_SPEC_FIX
    }
];

# Match compilation error to known error pattern
#
# + compilationError - The compilation error to match
# + return - Matching ErrorPattern or null if no match found
public function matchErrorPattern(command_executor:CompilationError compilationError) returns ErrorPattern? {
    foreach ErrorPattern pattern in ERROR_PATTERNS {
        if compilationError.message.includes(pattern.message) {
            log:printInfo(string `Matched error pattern: ${pattern.patternId} for message: ${compilationError.message}`);
            return pattern;
        }
    }

    log:printWarn(string `No pattern matched for error: ${compilationError.message}`);
    return ();
}

# Classify unknown errors and determine handling strategy
#
# + errors - Array of unmatched compilation errors
# + return - Recommended handling strategy for unknown errors
public function classifyUnknownErrors(command_executor:CompilationError[] errors) returns ErrorHandlingStrategy {
    if (errors.length() == 0) {
        return UNSUPPORTED;
    }
    // For now, all unknown errors require user prompt
    // This could be enhanced with more sophisticated classification logic
    log:printInfo(string `Found ${errors.length()} unknown errors - user prompt required`);
    return USER_PROMPT_REQUIRED;

}

# Route errors based on their patterns and handling strategies
#
# + errors - Array of all compilation errors
# + return - Categorized errors by handling strategy
public function routeErrorsByStrategy(command_executor:CompilationError[] errors) returns map<command_executor:CompilationError[]> {
    map<command_executor:CompilationError[]> categorizedErrors = {};
    command_executor:CompilationError[] unknownErrors = [];

    foreach command_executor:CompilationError err in errors {
        ErrorPattern? pattern = matchErrorPattern(err);
        if (pattern is ErrorPattern) {
            string strategy = pattern.handlingStrategy.toString();
            if (!categorizedErrors.hasKey(strategy)) {
                categorizedErrors[strategy] = [];
            }
            command_executor:CompilationError[]? existing = categorizedErrors[strategy];
            if (existing is command_executor:CompilationError[]) {
                existing.push(err);
            }
        } else {
            unknownErrors.push(err);
        }
    }

    // Handle unknown errors
    if (unknownErrors.length() > 0) {
        ErrorHandlingStrategy unknownStrategy = classifyUnknownErrors(unknownErrors);
        string strategyKey = unknownStrategy.toString();
        categorizedErrors[strategyKey] = unknownErrors;
    }

    return categorizedErrors;
}

# Apply fix for a specific error pattern
#
# + pattern - The error pattern to fix
# + targetSymbol - The symbol/property causing the issue (extracted from error message)
# + specFilePath - Path to OpenAPI spec file to modify
# + return - FixResult indicating success/failure and changes made
public function applyFix(ErrorPattern pattern, string targetSymbol, string specFilePath) returns FixResult|ErrorRegistryError {
    log:printInfo(string `Applying fix for pattern ${pattern.patternId} targeting symbol '${targetSymbol}' in ${specFilePath}`);

    match pattern.fixStrategy {
        "REMOVE_CONFLICTING_PROPERTY" => {
            return applyRemoveConflictingPropertyFix(targetSymbol, specFilePath);
        }
        "ADD_FIELD_DOCUMENTATION" => {
            return applyAddFieldDocumentationFix(targetSymbol, specFilePath);
        }
        _ => {
            return error ErrorRegistryError(string `Unknown fix strategy: ${pattern.fixStrategy}`);
        }
    }
}

# Apply fixes to multiple errors in batch
#
# + errors - Array of compilation errors to fix
# + specFilePath - Path to OpenAPI spec file to modify
# + return - BatchFixResult with overall success status and individual results
public function applyBatchFixes(command_executor:CompilationError[] errors, string specFilePath) returns BatchFixResult|ErrorRegistryError {
    FixResult[] individualResults = [];
    int fixedCount = 0;
    int failedCount = 0;

    // Group errors by actual conflicting schema to avoid duplicate fixes
    map<command_executor:CompilationError> uniqueSchemas = {};

    foreach command_executor:CompilationError err in errors {
        ErrorPattern? pattern = matchErrorPattern(err);
        if (pattern is ErrorPattern) {
            // For redeclared symbol and undocumented field errors, identify the actual schema based on line analysis
            if (pattern.patternId == "REDECLARED_SYMBOL" || pattern.patternId == "UNDOCUMENTED_FIELD") {
                string typesFilePath = getTypesFilePathFromSpecPath(specFilePath);
                string|ErrorRegistryError schemaResult = identifyConflictingSchemaFromSingleError(err, typesFilePath);
                if (schemaResult is string) {
                    // Use the schema name as the key to avoid duplicates
                    uniqueSchemas[schemaResult] = err;
                } else {
                    failedCount += 1;
                    FixResult errorResult = {
                        success: false,
                        changesApplied: 0,
                        fixDescription: string `Failed to identify schema for line ${err.line}`,
                        errorMessage: schemaResult.message()
                    };
                    individualResults.push(errorResult);
                }
            } else {
                // For other error types, use line number as key to ensure each error is processed
                string errorKey = pattern.patternId + ":" + err.line.toString();
                uniqueSchemas[errorKey] = err;
            }
        }
    }

    // Apply fixes for each unique schema
    foreach string schemaName in uniqueSchemas.keys() {
        command_executor:CompilationError? maybeErr = uniqueSchemas[schemaName];
        if (maybeErr is command_executor:CompilationError) {
            command_executor:CompilationError err = maybeErr;
            ErrorPattern? pattern = matchErrorPattern(err);
            if (pattern is ErrorPattern) {
                string actualTargetSymbol = schemaName;

                // For undocumented field errors, use the field name from message (not the type schema)
                // For other non-redeclared symbol errors, extract target symbol from message
                if (pattern.patternId == "UNDOCUMENTED_FIELD") {
                    actualTargetSymbol = extractTargetSymbol(err.message); // Use field name (e.g., createdAt, modifiedAt)
                } else if (pattern.patternId != "REDECLARED_SYMBOL") {
                    actualTargetSymbol = extractTargetSymbol(err.message);
                }

                FixResult|ErrorRegistryError fixResult = applyFix(pattern, actualTargetSymbol, specFilePath);
                if (fixResult is FixResult) {
                    individualResults.push(fixResult);
                    if (fixResult.success) {
                        fixedCount += 1;
                    } else {
                        failedCount += 1;
                    }
                } else {
                    failedCount += 1;
                    FixResult errorResult = {
                        success: false,
                        changesApplied: 0,
                        fixDescription: "Failed to apply fix",
                        errorMessage: fixResult.message()
                    };
                    individualResults.push(errorResult);
                }
            }
        }
    }

    boolean overallSuccess = failedCount == 0;
    string summary = string `Fixed ${fixedCount}/${errors.length()} errors. ${failedCount} failed.`;

    return {
        overallSuccess: overallSuccess,
        totalErrors: errors.length(),
        fixedErrors: fixedCount,
        failedErrors: failedCount,
        individualResults: individualResults,
        summary: summary
    };
}

# Fix redeclared symbol errors by inlining conflicting schema references
#
# + conflictingSchemaName - Name of schema causing conflicts (e.g., "DiscussionCreateAllOf2")
# + specFilePath - Path to spec file
# + return - FixResult with changes made
function applyRemoveConflictingPropertyFix(string conflictingSchemaName, string specFilePath) returns FixResult|ErrorRegistryError {
    string|error specContent = io:fileReadString(specFilePath);
    if specContent is error {
        return error ErrorRegistryError("Failed to read spec file", specContent);
    }

    json|error specJson = specContent.fromJsonString();
    if specJson is error {
        return error ErrorRegistryError("Invalid JSON in spec file", specJson);
    }

    int changesCount = 0;

    if (specJson is map<json>) {
        json components = specJson["components"];
        if (components is map<json>) {
            json schemas = components["schemas"];
            if (schemas is map<json>) {

                // Step 1: Find and store the conflicting schema definition
                json? conflictingSchemaDefinition = schemas[conflictingSchemaName];
                if (conflictingSchemaDefinition is ()) {
                    // Schema doesn't exist in spec - this means it was removed during flattening
                    // but references still exist in generated code. We need to remove orphaned references.
                    log:printInfo(string `Schema '${conflictingSchemaName}' not found in spec - removing orphaned references`);
                    return removeOrphanedSchemaReferences(conflictingSchemaName, specFilePath);
                }

                log:printInfo(string `Found conflicting schema definition: ${conflictingSchemaName}`);

                // Step 2: Find all $ref references to this schema and inline them
                string schemaRef = string `#/components/schemas/${conflictingSchemaName}`;
                changesCount += inlineSchemaReferences(schemas, schemaRef, conflictingSchemaDefinition);

                // Step 3: Remove the original schema definition to prevent future conflicts
                if (schemas.hasKey(conflictingSchemaName)) {
                    _ = schemas.remove(conflictingSchemaName);
                    changesCount += 1;
                    log:printInfo(string `Removed schema definition: ${conflictingSchemaName}`);
                }

                // Step 4: Write back the modified spec
                if (changesCount > 0) {
                    string modifiedSpec = specJson.toJsonString();
                    error? writeResult = io:fileWriteString(specFilePath, modifiedSpec);
                    if (writeResult is error) {
                        return error ErrorRegistryError("Failed to write modified spec", writeResult);
                    }
                }
            }
        }
    }

    return {
        success: changesCount > 0,
        changesApplied: changesCount,
        fixDescription: string `Inlined and removed conflicting schema '${conflictingSchemaName}' (${changesCount} changes)`,
        errorMessage: ()
    };
}

# Add field documentation to fix undocumented field warnings
#
# + fieldName - Name of the undocumented field
# + specFilePath - Path to flattened spec file (used to derive aligned spec path)
# + return - FixResult with changes made
function applyAddFieldDocumentationFix(string fieldName, string specFilePath) returns FixResult|ErrorRegistryError {
    log:printInfo(string `Adding documentation for field '${fieldName}'`);

    // Derive aligned spec path from flattened spec path
    string alignedSpecPath = getAlignedSpecPathFromFlattenedPath(specFilePath);

    // Step 1: Try to extract description from aligned OpenAPI spec
    string description = "";
    string|ErrorRegistryError specDescription = extractFieldDescriptionFromSpec(fieldName, alignedSpecPath);
    if (specDescription is string) {
        description = specDescription;
        log:printInfo(string `Found description in aligned spec for field '${fieldName}': ${description}`);
    } else {
        // Step 2: Generate pattern-based description if not found in spec
        description = generatePatternBasedDescription(fieldName);
        log:printInfo(string `Generated pattern-based description for field '${fieldName}': ${description}`);
    }

    // Step 3: Add description to aligned spec field properties
    FixResult|ErrorRegistryError result = addDescriptionToAlignedSpecField(fieldName, description, alignedSpecPath);
    if (result is FixResult) {
        return result;
    } else {
        return result;
    }
}

# Extract target symbol from error message
#
# + errorMessage - The error message to parse
# + return - Extracted symbol name or empty string
public function extractTargetSymbol(string errorMessage) returns string {
    // Extract the conflicting property name from error message
    if (errorMessage.includes("'") && errorMessage.includes("'")) {
        int? startQuote = errorMessage.indexOf("'");
        int? endQuote = errorMessage.indexOf("'", (startQuote ?: 0) + 1);

        if (startQuote is int && endQuote is int) {
            return errorMessage.substring(startQuote + 1, endQuote);
        }
    }
    return "";
}

# Identify the conflicting schema name from a single compilation error
# This function analyzes the generated types.bal and maps the error to a schema name
#
# + err - A single compilation error with file/line information
# + generatedTypesFile - Path to the generated types.bal file
# + return - Schema name that's causing the conflict
function identifyConflictingSchemaFromSingleError(command_executor:CompilationError err, string generatedTypesFile) returns string|ErrorRegistryError {
    // Read the types.bal file to analyze the error location
    string|error typesContent = io:fileReadString(generatedTypesFile);
    if (typesContent is error) {
        return error ErrorRegistryError("Failed to read types.bal file", typesContent);
    }

    // For undocumented field errors, extract the actual type name from the field declaration
    if (err.message.includes("undocumented field")) {
        string fieldTypeName = extractFieldTypeFromLine(typesContent, err.line);
        if (fieldTypeName != "") {
            log:printInfo(string `Found field type '${fieldTypeName}' at line ${err.line} in types.bal`);
            return fieldTypeName;
        }
    }

    // For other errors, find the record type name at the specific error line
    string recordName = extractRecordNameFromLine(typesContent, err.line);
    if (recordName != "") {
        log:printInfo(string `Found record name '${recordName}' at line ${err.line} in types.bal`);
        return recordName;
    }

    return error ErrorRegistryError(string `Could not identify conflicting schema from error at line ${err.line}`);
}

# Identify the conflicting schema name from compilation errors
# This function analyzes the generated types.bal and maps errors to schema names
#
# + errors - Array of compilation errors with file/line information
# + generatedTypesFile - Path to the generated types.bal file
# + return - Schema name that's causing the conflicts
function identifyConflictingSchema(command_executor:CompilationError[] errors, string generatedTypesFile) returns string|ErrorRegistryError {
    // Read the types.bal file to analyze the error locations
    string|error typesContent = io:fileReadString(generatedTypesFile);
    if (typesContent is error) {
        return error ErrorRegistryError("Failed to read types.bal file", typesContent);
    }

    // For each error, find the record type name at that line
    foreach command_executor:CompilationError err in errors {
        string recordName = extractRecordNameFromLine(typesContent, err.line);
        if (recordName != "") {
            log:printInfo(string `Found record name '${recordName}' at line ${err.line} in types.bal`);
            return recordName;
        }
    }

    return error ErrorRegistryError("Could not identify conflicting schema from compilation errors");
}

# Extract the record type name from a specific line in types.bal
#
# + content - Content of types.bal file
# + lineNumber - Line number where error occurred
# + return - Record type name or empty string if not found
function extractRecordNameFromLine(string content, int lineNumber) returns string {
    string[] lines = regex:split(content, "\\n");

    if (lineNumber <= 0 || lineNumber > lines.length()) {
        return "";
    }

    // Get the specific error line
    string errorLine = lines[lineNumber - 1]; // Arrays are 0-indexed
    log:printInfo(string `Error line ${lineNumber}: ${errorLine.trim()}`);

    // Check if the error line itself contains a schema reference like "*DiscussionCreateAllOf2;"
    if (errorLine.includes("*") && errorLine.includes(";")) {
        // Extract schema name from pattern like "*SchemaName;"
        string trimmedLine = errorLine.trim();
        if (trimmedLine.startsWith("*") && trimmedLine.endsWith(";")) {
            string schemaName = trimmedLine.substring(1, trimmedLine.length() - 1); // Remove * and ;
            log:printInfo(string `Found schema reference in error line: ${schemaName}`);
            return schemaName;
        }
    }

    // Look backwards from the error line to find the record definition
    int searchStart = lineNumber - 1;
    foreach int i in 0 ..< searchStart {
        int lineIndex = searchStart - i - 1; // Search backwards
        if (lineIndex < 0) {
            break;
        }

        string line = lines[lineIndex];

        // Look for record type definition pattern like "public type RecordName record {|"
        if (line.includes("public type") && line.includes("record {|")) {
            // Extract record name from pattern "public type RecordName record {|"
            string[] parts = regex:split(line.trim(), "\\s+");
            foreach int j in 0 ..< parts.length() {
                if (parts[j] == "type" && j + 1 < parts.length()) {
                    string recordName = parts[j + 1];
                    log:printInfo(string `Extracted record name: ${recordName} from line ${lineIndex + 1}: ${line.trim()}`);
                    return recordName;
                }
            }
        }
    }

    return "";
}

# Extract the field type from a specific line in types.bal (for undocumented field errors)
#
# + content - Content of types.bal file
# + lineNumber - Line number where undocumented field error occurred
# + return - Field type name or empty string if not found
function extractFieldTypeFromLine(string content, int lineNumber) returns string {
    string[] lines = regex:split(content, "\\n");

    if (lineNumber <= 0 || lineNumber > lines.length()) {
        return "";
    }

    // Get the specific error line
    string errorLine = lines[lineNumber - 1]; // Arrays are 0-indexed
    log:printInfo(string `Error line ${lineNumber}: ${errorLine.trim()}`);

    // Parse field declaration line like "    WebhookStats stats?;"
    // Pattern: [indentation] [type] [fieldName] [?] [;]
    string trimmedLine = errorLine.trim();

    // Split by whitespace to get tokens
    string[] tokens = regex:split(trimmedLine, "\\s+");

    if (tokens.length() >= 2) {
        // First token should be the type, second should be field name with ? and ;
        string fieldType = tokens[0];
        string fieldDeclaration = tokens[1];

        // Verify this looks like a field declaration (ends with ?; or ;)
        if (fieldDeclaration.endsWith("?;") || fieldDeclaration.endsWith(";")) {
            log:printInfo(string `Extracted field type: ${fieldType}`);
            return fieldType;
        }
    }

    return "";
}

# Derive types.bal file path from spec file path
#
# + specFilePath - Path to the flattened OpenAPI spec
# + return - Path to the corresponding types.bal file
function getTypesFilePathFromSpecPath(string specFilePath) returns string {
    // For path like "/path/to/flattened_openapi.json"
    // Return "/path/to/ballerina/types.bal"
    string directoryPath = getDirectoryPathFromFilePath(specFilePath);
    return directoryPath + "/ballerina/types.bal";
}

# Helper function to extract directory path from file path
#
# + filePath - Full file path
# + return - Directory path
function getDirectoryPathFromFilePath(string filePath) returns string {
    int? lastSlashIndex = filePath.lastIndexOf("/");
    if (lastSlashIndex is int) {
        return filePath.substring(0, lastSlashIndex);
    }
    return "."; // Current directory
}

# Get error pattern by ID
#
# + patternId - Pattern identifier to find  
# + return - ErrorPattern if found, null otherwise
function getPatternById(string patternId) returns ErrorPattern? {
    foreach ErrorPattern pattern in ERROR_PATTERNS {
        if (pattern.patternId == patternId) {
            return pattern;
        }
    }
    return ();
}

# Get all available error patterns
#
# + return - Array of all registered error patterns
public function getAvailablePatterns() returns ErrorPattern[] {
    return ERROR_PATTERNS;
}

# Get statistics about error patterns
#
# + errors - Array of compilation errors to analyze
# + return - Map of pattern IDs to occurrence counts
public function getErrorPatternStats(command_executor:CompilationError[] errors) returns map<int> {
    map<int> stats = {};

    foreach command_executor:CompilationError err in errors {
        ErrorPattern? pattern = matchErrorPattern(err);
        if (pattern is ErrorPattern) {
            int currentCount = stats[pattern.patternId] ?: 0;
            stats[pattern.patternId] = currentCount + 1;
        } else {
            int unknownCount = stats["UNKNOWN"] ?: 0;
            stats["UNKNOWN"] = unknownCount + 1;
        }
    }

    return stats;
}

# Recursively find and inline schema references
#
# + schemasObject - The schemas object to search through
# + targetRef - The reference to find and replace (e.g., "#/components/schemas/DiscussionCreateAllOf2")
# + inlineContent - The schema definition to inline
# + return - Number of references inlined
function inlineSchemaReferences(map<json> schemasObject, string targetRef, json inlineContent) returns int {
    int inlineCount = 0;

    // Search through all schemas for allOf compositions containing the target reference
    foreach string schemaName in schemasObject.keys() {
        json schema = schemasObject[schemaName];
        if (schema is map<json>) {
            // Check if this schema has allOf array
            json allOfArray = schema["allOf"];
            if (allOfArray is json[]) {
                // Check each item in allOf for the target reference
                foreach int i in 0 ..< allOfArray.length() {
                    json allOfItem = allOfArray[i];
                    if (allOfItem is map<json>) {
                        json refValue = allOfItem["$ref"];
                        if (refValue is string && refValue == targetRef) {
                            // Found a reference to inline!
                            json inlinedSchema = createInlinedSchema(inlineContent);
                            allOfArray[i] = inlinedSchema;
                            inlineCount += 1;
                            log:printInfo(string `Inlined reference '${targetRef}' in schema '${schemaName}'`);
                        }
                    }
                }
            }
        }
    }

    return inlineCount;
}

# Create an inlined schema by moving the complete schema definition
#
# + originalSchema - The original schema definition to inline
# + return - The complete inlined schema (moved intact, not filtered)
function createInlinedSchema(json originalSchema) returns json {
    // Move the schema completely intact - no property filtering
    // This is the correct approach: we inline the entire schema definition
    // exactly as it was defined in components/schemas

    log:printInfo("Inlining complete schema definition (no properties removed)");
    return originalSchema;
}

# Remove orphaned schema references from generated types.bal file
#
# + orphanedSchemaName - Name of schema that doesn't exist but is referenced
# + specFilePath - Path to spec file (used to derive types.bal path)
# + return - FixResult indicating success/failure and changes made
function removeOrphanedSchemaReferences(string orphanedSchemaName, string specFilePath) returns FixResult|ErrorRegistryError {
    // Derive types.bal path from specFilePath
    string typesFilePath = getTypesFilePathFromSpecPath(specFilePath);

    string|error typesContent = io:fileReadString(typesFilePath);
    if (typesContent is error) {
        return error ErrorRegistryError("Failed to read types.bal file", typesContent);
    }

    // Remove lines that reference the orphaned schema like "*AccountBulkUpdateAllOf2;"
    string orphanedReference = string `*${orphanedSchemaName};`;
    string[] lines = regex:split(typesContent, "\\n");
    string[] filteredLines = [];
    int removedCount = 0;

    foreach string line in lines {
        if (line.trim() == orphanedReference) {
            log:printInfo(string `Removing orphaned reference line: ${line.trim()}`);
            removedCount += 1;
        } else {
            filteredLines.push(line);
        }
    }

    if (removedCount > 0) {
        // Write back the modified types.bal
        string modifiedContent = string:'join("\\n", ...filteredLines);
        error? writeResult = io:fileWriteString(typesFilePath, modifiedContent);
        if (writeResult is error) {
            return error ErrorRegistryError("Failed to write modified types.bal", writeResult);
        }

        return {
            success: true,
            changesApplied: removedCount,
            fixDescription: string `Removed ${removedCount} orphaned references to '${orphanedSchemaName}' from types.bal`,
            errorMessage: ()
        };
    }

    return {
        success: false,
        changesApplied: 0,
        fixDescription: string `No orphaned references to '${orphanedSchemaName}' found in types.bal`,
        errorMessage: "No orphaned references found to remove"
    };
}

# Extract field description from OpenAPI spec and return both description and source info
#
# + fieldName - Name of the field to find description for
# + specFilePath - Path to the OpenAPI spec file
# + return - Tuple of (description, source_type, source_name) or ErrorRegistryError if not found
function extractFieldDescriptionWithSource(string fieldName, string specFilePath) returns [string, string, string]|ErrorRegistryError {
    string|error specContent = io:fileReadString(specFilePath);
    if (specContent is error) {
        return error ErrorRegistryError("Failed to read spec file", specContent);
    }

    json|error specJson = specContent.fromJsonString();
    if (specJson is error) {
        return error ErrorRegistryError("Invalid JSON in spec file", specJson);
    }

    if (specJson is map<json>) {
        json components = specJson["components"];
        if (components is map<json>) {
            json schemas = components["schemas"];
            if (schemas is map<json>) {
                // Strategy 1: Search for field property descriptions in all schemas
                foreach string schemaName in schemas.keys() {
                    json schema = schemas[schemaName];
                    if (schema is map<json>) {
                        json properties = schema["properties"];
                        if (properties is map<json>) {
                            json fieldProperty = properties[fieldName];
                            if (fieldProperty is map<json>) {
                                json description = fieldProperty["description"];
                                if (description is string) {
                                    return [description, "property", schemaName];
                                }
                            }
                        }
                    }
                }

                // Strategy 2: Search for type schema descriptions (capitalized field name)
                string capitalizedFieldName = fieldName.substring(0, 1).toUpperAscii() + fieldName.substring(1);
                json typeSchema = schemas[capitalizedFieldName];
                if (typeSchema is map<json>) {
                    json description = typeSchema["description"];
                    if (description is string) {
                        return [description, "type_schema", capitalizedFieldName];
                    }
                }

                // Strategy 3: Search for exact schema name match
                json exactSchema = schemas[fieldName];
                if (exactSchema is map<json>) {
                    json description = exactSchema["description"];
                    if (description is string) {
                        return [description, "exact_schema", fieldName];
                    }
                }
            }
        }
    }

    return error ErrorRegistryError(string `No description found for field '${fieldName}' in OpenAPI spec`);
}

# Extract field description from OpenAPI spec (backward compatibility wrapper)
#
# + fieldName - Name of the field to find description for
# + specFilePath - Path to the OpenAPI spec file
# + return - Description string or ErrorRegistryError if not found
function extractFieldDescriptionFromSpec(string fieldName, string specFilePath) returns string|ErrorRegistryError {
    [string, string, string]|ErrorRegistryError result = extractFieldDescriptionWithSource(fieldName, specFilePath);
    if (result is [string, string, string]) {
        return result[0]; // Return just the description
    } else {
        return result; // Return the error
    }
}

# Generate pattern-based description for common field names
#
# + fieldName - Name of the field to generate description for
# + return - Generated description string
function generatePatternBasedDescription(string fieldName) returns string {
    string lowerFieldName = fieldName.toLowerAscii();

    // ID patterns
    if (lowerFieldName == "id" || lowerFieldName.endsWith("id")) {
        return string `Unique identifier for the ${fieldName.substring(0, fieldName.length() - 2)}`;
    }

    // Name patterns  
    if (lowerFieldName == "name" || lowerFieldName.endsWith("name")) {
        return string `Name of the ${fieldName.substring(0, fieldName.length() - 4)}`;
    }

    // Title patterns
    if (lowerFieldName == "title" || lowerFieldName.endsWith("title")) {
        return string `Title of the ${fieldName.substring(0, fieldName.length() - 5)}`;
    }

    // Created/Updated timestamp patterns
    if (lowerFieldName.startsWith("created") || lowerFieldName.startsWith("updated")) {
        return string `Timestamp when the item was ${lowerFieldName.startsWith("created") ? "created" : "updated"}`;
    }

    // Boolean flag patterns
    if (lowerFieldName.startsWith("is") || lowerFieldName.startsWith("has") || lowerFieldName.startsWith("can")) {
        return string `Boolean flag indicating ${fieldName}`;
    }

    // Count/Number patterns
    if (lowerFieldName.endsWith("count") || lowerFieldName.endsWith("total")) {
        return string `Number of ${fieldName.substring(0, fieldName.length() - 5)}`;
    }

    // URL/Link patterns
    if (lowerFieldName.endsWith("url") || lowerFieldName.endsWith("link")) {
        return string `URL link for ${fieldName.substring(0, fieldName.length() - 3)}`;
    }

    // Status patterns
    if (lowerFieldName.endsWith("status") || lowerFieldName.endsWith("state")) {
        return string `Current status or state of the ${fieldName.substring(0, fieldName.length() - 6)}`;
    }

    // Type patterns
    if (lowerFieldName.endsWith("type")) {
        return string `Type of ${fieldName.substring(0, fieldName.length() - 4)}`;
    }

    // Common business field patterns
    match lowerFieldName {
        "email" => {
            return "Email address";
        }
        "phone" => {
            return "Phone number";
        }
        "address" => {
            return "Physical address";
        }
        "description" => {
            return "Description of the item";
        }
        "version" => {
            return "Version number";
        }
        "size" => {
            return "Size of the item";
        }
        "length" => {
            return "Length of the item";
        }
        "width" => {
            return "Width of the item";
        }
        "height" => {
            return "Height of the item";
        }
        "color" => {
            return "Color of the item";
        }
        "tags" => {
            return "Tags associated with the item";
        }
        "categories" => {
            return "Categories for the item";
        }
        "reports" => {
            return "List of reports";
        }
        "sheets" => {
            return "List of sheets";
        }
        "folders" => {
            return "List of folders";
        }
        "sights" => {
            return "List of dashboards/sights";
        }
        "workingdays" => {
            return "Working days configuration";
        }
        _ => {
            // Generic fallback
            return string `The ${fieldName} property`;
        }
    }
}

# Add documentation comment to a field in types.bal file
#
# + fieldName - Name of the field to document
# + description - Description to add as comment
# + typesFilePath - Path to the types.bal file
# + return - FixResult indicating success/failure and changes made
function addDocumentationToField(string fieldName, string description, string typesFilePath) returns FixResult|ErrorRegistryError {
    string|error typesContent = io:fileReadString(typesFilePath);
    if (typesContent is error) {
        return error ErrorRegistryError("Failed to read types.bal file", typesContent);
    }

    string[] lines = regex:split(typesContent, "\\n");
    string[] modifiedLines = [];
    int changesCount = 0;

    foreach int i in 0 ..< lines.length() {
        string line = lines[i];

        // Look for field declarations like "    string fieldName?;"
        if (line.includes(fieldName) && (line.includes("?;") || line.includes(";")) && !line.trim().startsWith("#")) {
            // Check if this line already has documentation (previous line starts with #)
            boolean hasDocumentation = false;
            if (i > 0) {
                string previousLine = lines[i - 1].trim();
                if (previousLine.startsWith("#")) {
                    hasDocumentation = true;
                }
            }

            if (!hasDocumentation) {
                // Extract indentation from the field line
                string indentation = "";
                foreach int j in 0 ..< line.length() {
                    string char = line.substring(j, j + 1);
                    if (char == " " || char == "\t") {
                        indentation += char;
                    } else {
                        break;
                    }
                }

                // Add documentation comment with same indentation
                string docComment = indentation + "# " + description;
                modifiedLines.push(docComment);
                changesCount += 1;
                log:printInfo(string `Added documentation for field '${fieldName}': ${description}`);
            }
        }

        modifiedLines.push(line);
    }

    if (changesCount > 0) {
        // Write back the modified content
        string modifiedContent = string:'join("\\n", ...modifiedLines);
        error? writeResult = io:fileWriteString(typesFilePath, modifiedContent);
        if (writeResult is error) {
            return error ErrorRegistryError("Failed to write modified types.bal", writeResult);
        }

        return {
            success: true,
            changesApplied: changesCount,
            fixDescription: string `Added documentation for field '${fieldName}': ${description}`,
            errorMessage: ()
        };
    }

    return {
        success: false,
        changesApplied: 0,
        fixDescription: string `Field '${fieldName}' not found or already documented`,
        errorMessage: "Field not found or already has documentation"
    };
}

# Derive aligned spec path from flattened spec path
#
# + flattenedSpecPath - Path to the flattened OpenAPI spec
# + return - Path to the aligned OpenAPI spec
function getAlignedSpecPathFromFlattenedPath(string flattenedSpecPath) returns string {
    // For path like "/path/to/generated/flattened_openapi.json"
    // Return "/path/to/generated/aligned_ballerina_openapi.json"
    string directoryPath = getDirectoryPathFromFilePath(flattenedSpecPath);
    return directoryPath + "/aligned_ballerina_openapi.json";
}

# Add description to a field property in the aligned OpenAPI spec
#
# + fieldName - Name of the field to add description to
# + description - Description to add to the field
# + alignedSpecPath - Path to the aligned OpenAPI spec file
# + return - FixResult indicating success/failure and changes made
function addDescriptionToAlignedSpecField(string fieldName, string description, string alignedSpecPath) returns FixResult|ErrorRegistryError {
    string|error specContent = io:fileReadString(alignedSpecPath);
    if (specContent is error) {
        return error ErrorRegistryError("Failed to read aligned spec file", specContent);
    }

    json|error specJson = specContent.fromJsonString();
    if (specJson is error) {
        return error ErrorRegistryError("Invalid JSON in aligned spec file", specJson);
    }

    int changesCount = 0;

    if (specJson is map<json>) {
        json components = specJson["components"];
        if (components is map<json>) {
            json schemas = components["schemas"];
            if (schemas is map<json>) {
                // Strategy 1: Search through all schemas for field properties and add description
                foreach string schemaName in schemas.keys() {
                    json schema = schemas[schemaName];
                    if (schema is map<json>) {
                        // Search in direct properties
                        json properties = schema["properties"];
                        if (properties is map<json>) {
                            // Check if this schema has the field we're looking for
                            if (properties.hasKey(fieldName)) {
                                log:printInfo(string `Found field '${fieldName}' in schema '${schemaName}' direct properties`);
                            }
                            json fieldProperty = properties[fieldName];
                            if (fieldProperty is map<json>) {
                                // Check if field has $ref - need to transform structure for Ballerina
                                if (fieldProperty.hasKey("$ref")) {
                                    json refValue = fieldProperty["$ref"];
                                    // Transform: {"$ref": "...", "description": "..."} 
                                    // to: {"description": "...", "allOf": [{"$ref": "..."}]}
                                    fieldProperty.removeAll();
                                    fieldProperty["description"] = description;
                                    fieldProperty["allOf"] = [{"$ref": refValue}];
                                    changesCount += 1;
                                    log:printInfo(string `Transformed $ref structure and added description to field '${fieldName}' in schema '${schemaName}': ${description}`);
                                } else if (fieldProperty.hasKey("allOf") && !fieldProperty.hasKey("description")) {
                                    // Field already has allOf structure but missing description - just add description
                                    fieldProperty["description"] = description;
                                    changesCount += 1;
                                    log:printInfo(string `Added description to existing allOf field '${fieldName}' in schema '${schemaName}': ${description}`);
                                } else if (!fieldProperty.hasKey("description")) {
                                    // Simple field property - just add description
                                    fieldProperty["description"] = description;
                                    changesCount += 1;
                                    log:printInfo(string `Added description to field '${fieldName}' in schema '${schemaName}': ${description}`);
                                }
                            } else if (fieldProperty is string && fieldProperty.startsWith("#/components/schemas/")) {
                                // Handle direct string $ref like "createdAt": "#/components/schemas/Timestamp"
                                string refValue = fieldProperty;
                                // Transform to allOf structure
                                properties[fieldName] = {
                                    "description": description,
                                    "allOf": [{"$ref": refValue}]
                                };
                                changesCount += 1;
                                log:printInfo(string `Transformed direct $ref and added description to field '${fieldName}' in schema '${schemaName}': ${description}`);
                            }
                        }

                        // Search in allOf structures for nested properties
                        json allOfArray = schema["allOf"];
                        if (allOfArray is json[]) {
                            foreach json allOfItem in allOfArray {
                                if (allOfItem is map<json>) {
                                    json nestedProperties = allOfItem["properties"];
                                    if (nestedProperties is map<json>) {
                                        if (nestedProperties.hasKey(fieldName)) {
                                            log:printInfo(string `Found field '${fieldName}' in schema '${schemaName}' allOf properties`);
                                        }
                                        json nestedFieldProperty = nestedProperties[fieldName];
                                        if (nestedFieldProperty is map<json>) {
                                            // Check if field has $ref - need to transform structure for Ballerina
                                            if (nestedFieldProperty.hasKey("$ref")) {
                                                json refValue = nestedFieldProperty["$ref"];
                                                // Transform: {"$ref": "...", "description": "..."} 
                                                // to: {"description": "...", "allOf": [{"$ref": "..."}]}
                                                nestedFieldProperty.removeAll();
                                                nestedFieldProperty["description"] = description;
                                                nestedFieldProperty["allOf"] = [{"$ref": refValue}];
                                                changesCount += 1;
                                                log:printInfo(string `Transformed $ref structure and added description to field '${fieldName}' in allOf schema '${schemaName}': ${description}`);
                                            } else if (nestedFieldProperty.hasKey("allOf") && !nestedFieldProperty.hasKey("description")) {
                                                // Field already has allOf structure but missing description - just add description
                                                nestedFieldProperty["description"] = description;
                                                changesCount += 1;
                                                log:printInfo(string `Added description to existing allOf field '${fieldName}' in allOf schema '${schemaName}': ${description}`);
                                            } else if (!nestedFieldProperty.hasKey("description")) {
                                                // Simple field property - just add description
                                                nestedFieldProperty["description"] = description;
                                                changesCount += 1;
                                                log:printInfo(string `Added description to field '${fieldName}' in allOf schema '${schemaName}': ${description}`);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Strategy 2: Check if there's a type schema that needs description (capitalized field name)
                string capitalizedFieldName = fieldName.substring(0, 1).toUpperAscii() + fieldName.substring(1);
                json typeSchema = schemas[capitalizedFieldName];
                if (typeSchema is map<json>) {
                    // Check if description already exists for the type schema
                    if (!typeSchema.hasKey("description") || typeSchema["description"] is ()) {
                        // Add description to the type schema
                        typeSchema["description"] = description;
                        changesCount += 1;
                        log:printInfo(string `Added description to type schema '${capitalizedFieldName}': ${description}`);
                    } else {
                        log:printInfo(string `Type schema '${capitalizedFieldName}' already has description`);
                    }
                } else {
                    log:printInfo(string `Type schema '${capitalizedFieldName}' not found in schemas`);
                }

                // Strategy 3: Check if there's an exact schema name match
                json exactSchema = schemas[fieldName];
                if (exactSchema is map<json>) {
                    // Check if description already exists for the exact schema
                    if (!exactSchema.hasKey("description") || exactSchema["description"] is ()) {
                        // Add description to the exact schema
                        exactSchema["description"] = description;
                        changesCount += 1;
                        log:printInfo(string `Added description to exact schema '${fieldName}': ${description}`);
                    }
                }
            }
        }
    }

    if (changesCount > 0) {
        // Write back the modified aligned spec
        string modifiedSpec = specJson.toJsonString();
        error? writeResult = io:fileWriteString(alignedSpecPath, modifiedSpec);
        if (writeResult is error) {
            return error ErrorRegistryError("Failed to write modified aligned spec", writeResult);
        }

        return {
            success: true,
            changesApplied: changesCount,
            fixDescription: string `Added description to '${fieldName}' in ${changesCount} location(s) in aligned spec`,
            errorMessage: ()
        };
    }

    return {
        success: false,
        changesApplied: 0,
        fixDescription: string `Field '${fieldName}' not found or already has description in aligned spec`,
        errorMessage: "Field not found or already has description"
    };
}
