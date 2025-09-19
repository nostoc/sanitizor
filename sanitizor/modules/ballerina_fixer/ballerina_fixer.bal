import sanitizor.command_executor;
import sanitizor.llm_service;

import ballerina/io;
import ballerina/log;
import ballerina/regex;

public type BallerinaFixerError distinct error;

public type BallerinaFixResult record {|
    boolean success;
    int errorsFixed;
    int errorsRemaining;
    string[] appliedFixes;
    string? errorMessage;
|};

public type FileFixResult record {|
    boolean success;
    int errorsFixed;
    string[] appliedFixes;
    string? errorMessage;
|};

# Fix errors iteratively until all are resolved or max attempts reached
#
# + projectPath - Path to the Ballerina project
# + maxAttempts - Maximum number of fixing attempts (default: 3)
# + return - Result of fixing operation
public function fixAllBallerinaErrorsIteratively(string projectPath, int maxAttempts = 1) returns BallerinaFixResult|BallerinaFixerError {
    int attempt = 1;
    string[] allAppliedFixes = [];
    int totalFixed = 0;
    
    while attempt <= maxAttempts {
        log:printInfo("Starting fix attempt", attempt = attempt, maxAttempts = maxAttempts);
        
        command_executor:CommandResult buildResult = command_executor:executeBalBuild(projectPath);
        
        if buildResult.compilationErrors.length() == 0 {
            log:printInfo("All errors fixed successfully", attempt = attempt);
            return {
                success: true,
                errorsFixed: totalFixed,
                errorsRemaining: 0,
                appliedFixes: allAppliedFixes,
                errorMessage: ()
            };
        }
        
        // Try to fix current errors
        BallerinaFixResult|BallerinaFixerError fixResult = fixAllBallerinaErrors(projectPath);
        
        if fixResult is BallerinaFixResult {
            totalFixed += fixResult.errorsFixed;
            allAppliedFixes.push(...fixResult.appliedFixes);
            
            if fixResult.success {
                return {
                    success: true,
                    errorsFixed: totalFixed,
                    errorsRemaining: 0,
                    appliedFixes: allAppliedFixes,
                    errorMessage: ()
                };
            }
        } else {
            return fixResult;
        }
        
        attempt += 1;
    }
    
    // Final build to get remaining errors
    command_executor:CommandResult finalBuild = command_executor:executeBalBuild(projectPath);
    
    return {
        success: false,
        errorsFixed: totalFixed,
        errorsRemaining: finalBuild.compilationErrors.length(),
        appliedFixes: allAppliedFixes,
        errorMessage: ()
    };
}

# Main function to fix all Ballerina compilation errors using AI
#
# + projectPath - Path to the Ballerina project
# + return - Result of fixing operation
public function fixAllBallerinaErrors(string projectPath) returns BallerinaFixResult|BallerinaFixerError {
    log:printInfo("Starting AI-powered Ballerina error fixing", projectPath = projectPath);

    // 1. Build and get initial errors
    command_executor:CommandResult buildResult = command_executor:executeBalBuild(projectPath);

    if buildResult.compilationErrors.length() == 0 {
        return {
            success: true, 
            errorsFixed: 0, 
            errorsRemaining: 0, 
            appliedFixes: [],
            errorMessage: ()
        };
    }

    log:printInfo("Found compilation errors", errorCount = buildResult.compilationErrors.length());

    // 2. Group errors by file for targeted fixing
    map<command_executor:CompilationError[]> errorsByFile = groupErrorsByFile(buildResult.compilationErrors);

    string[] allAppliedFixes = [];
    int totalFixed = 0;

    // 3. Fix errors file by file using AI
    foreach string fileName in errorsByFile.keys() {
        command_executor:CompilationError[]? fileErrors = errorsByFile[fileName];
        if fileErrors is command_executor:CompilationError[] {
            string filePath = projectPath + "/" + fileName;
            log:printInfo("Fixing errors in file", fileName = fileName, errorCount = fileErrors.length());

            FileFixResult|BallerinaFixerError fileResult = fixFileErrors(filePath, fileErrors);

            if fileResult is FileFixResult && fileResult.success {
                totalFixed += fileResult.errorsFixed;
                allAppliedFixes.push(...fileResult.appliedFixes);
                log:printInfo("Successfully fixed errors in file", fileName = fileName, fixedCount = fileResult.errorsFixed);
            } else if fileResult is BallerinaFixerError {
                log:printError("Failed to fix errors in file", fileName = fileName, 'error = fileResult);
            }
        }
    }

    // 4. Verify fixes by building again
    command_executor:CommandResult verifyResult = command_executor:executeBalBuild(projectPath);

    return {
        success: verifyResult.compilationErrors.length() == 0,
        errorsFixed: totalFixed,
        errorsRemaining: verifyResult.compilationErrors.length(),
        appliedFixes: allAppliedFixes,
        errorMessage: ()
    };
}

# Fix errors in a specific Ballerina file using AI
#
# + filePath - Path to the Ballerina file
# + errors - Array of compilation errors for this file
# + return - Result of fixing operation
function fixFileErrors(string filePath, command_executor:CompilationError[] errors) returns FileFixResult|BallerinaFixerError {
    // Determine file type and use appropriate fixing strategy
    if filePath.endsWith("types.bal") {
        return fixTypesFileErrors(filePath, errors);
    }
    // } else if filePath.endsWith("client.bal") {
    //     return fixClientFileErrors(filePath, errors);
    // } else if filePath.endsWith("utils.bal") {
    //     return fixUtilsFileErrors(filePath, errors);
    // } 
    else {
        return fixGenericBallerinaFile(filePath, errors);
    }
}

# Group compilation errors by file name
#
# + errors - Array of all compilation errors
# + return - Map of file names to their errors
function groupErrorsByFile(command_executor:CompilationError[] errors) returns map<command_executor:CompilationError[]> {
    map<command_executor:CompilationError[]> grouped = {};

    foreach command_executor:CompilationError err in errors {
        command_executor:CompilationError[]? existing = grouped[err.fileName];
        if existing is command_executor:CompilationError[] {
            existing.push(err);
        } else {
            grouped[err.fileName] = [err];
        }
    }

    return grouped;
}

# Build detailed error context with line numbers and code snippets
#
# + errors - Array of compilation errors
# + fileContent - Content of the file being fixed
# + return - Formatted error context string
function buildDetailedErrorContext(command_executor:CompilationError[] errors, string fileContent) returns string {
    string[] errorDescriptions = [];
    string[] lines = regex:split(fileContent, "\\n");
    
    foreach command_executor:CompilationError err in errors {
        string contextLines = "";
        
        // Get context around the error line (2 lines before and after)
        int startLine = (err.line - 3) > 0 ? (err.line - 3) : 0;
        int endLine = (err.line + 2) < lines.length() ? (err.line + 2) : lines.length() - 1;
        
        foreach int i in startLine...endLine {
            if i < lines.length() {
                string lineMarker = (i + 1) == err.line ? " -> " : "    ";
                contextLines += string `${lineMarker}${i + 1}: ${lines[i]}\n`;
            }
        }
        
        string errorDesc = string `
ERROR: ${err.message}
File: ${err.fileName}
Line: ${err.line}, Column: ${err.column}
Type: ${err.errorType}
Context:
${contextLines}
`;
        errorDescriptions.push(errorDesc);
    }
    
    return string:'join("\n---\n", ...errorDescriptions);
}

# Fix errors in types.bal file using intelligent approach
#
# + filePath - Path to types.bal file
# + errors - Array of compilation errors
# + return - Result of fixing operation
function fixTypesFileErrors(string filePath, command_executor:CompilationError[] errors) returns FileFixResult|BallerinaFixerError {
    // Check if most errors are redeclared symbol errors
    int redeclaredSymbolCount = 0;
    foreach command_executor:CompilationError err in errors {
        if err.message.includes("redeclared symbol") {
            redeclaredSymbolCount += 1;
        }
    }
    
    // If majority are redeclared symbol errors, use programmatic fix first
    if redeclaredSymbolCount > (errors.length() * 2 / 3) {
        log:printInfo("Most errors are redeclared symbols, trying programmatic fix first", 
            redeclaredCount = redeclaredSymbolCount, 
            totalErrors = errors.length()
        );
        
        FileFixResult|BallerinaFixerError programmaticResult = fixRedeclaredSymbolsProgrammatically(filePath, errors);
        if programmaticResult is FileFixResult && programmaticResult.success && programmaticResult.errorsFixed > 0 {
            return programmaticResult;
        } else {
            log:printInfo("Programmatic fix didn't work, falling back to AI approach");
        }
    }
    
    // Fall back to AI-based intelligent approach
    return fixBallerinaFileIntelligently(filePath, errors, "types.bal");
}

# Fix redeclared symbol errors programmatically by removing conflicting record inclusions
#
# + filePath - Path to types.bal file
# + errors - Array of compilation errors
# + return - Result of fixing operation
function fixRedeclaredSymbolsProgrammatically(string filePath, command_executor:CompilationError[] errors) returns FileFixResult|BallerinaFixerError {
    string|error content = io:fileReadString(filePath);
    if content is error {
        return error BallerinaFixerError("Failed to read types.bal for programmatic fix", content);
    }
    
    string[] lines = regex:split(content, "\\n");
    string[] modifiedLines = lines.clone();
    int fixesApplied = 0;
    string[] appliedFixes = [];
    
    // Group errors by the record that contains them
    map<command_executor:CompilationError[]> errorsByRecord = {};
    foreach command_executor:CompilationError err in errors {
        if err.message.includes("redeclared symbol") {
            string recordName = findRecordContainingLine(err.line, lines);
            if recordName != "" {
                command_executor:CompilationError[]? existing = errorsByRecord[recordName];
                if existing is command_executor:CompilationError[] {
                    existing.push(err);
                } else {
                    errorsByRecord[recordName] = [err];
                }
            }
        }
    }
    
    log:printInfo("Found records with redeclared symbols", recordCount = errorsByRecord.length());
    
    // Fix each problematic record
    foreach string recordName in errorsByRecord.keys() {
        command_executor:CompilationError[]? recordErrors = errorsByRecord[recordName];
        if recordErrors is command_executor:CompilationError[] {
            log:printInfo("Fixing redeclared symbols in record", recordName = recordName, errorCount = recordErrors.length());
            
            int recordStartLine = findRecordStartLine(recordName, modifiedLines);
            if recordStartLine > 0 {
                int recordEndLine = findRecordEndLine(recordStartLine, modifiedLines);
                
                // Find and remove problematic "*RecordAllOf" inclusions
                foreach int i in recordStartLine..<recordEndLine {
                    if i < modifiedLines.length() {
                        string line = modifiedLines[i].trim();
                        
                        // Look for lines like "*DiscussionCreateAllOf2;" that cause conflicts
                        if line.startsWith("*") && line.includes("AllOf") && line.endsWith(";") {
                            log:printInfo("Removing conflicting record inclusion", line = line, recordName = recordName);
                            modifiedLines[i] = "    // " + modifiedLines[i] + " // Removed to fix redeclared symbol errors";
                            fixesApplied += 1;
                            appliedFixes.push(string `Removed ${line.trim()} from ${recordName}`);
                        }
                    }
                }
            }
        }
    }
    
    if fixesApplied > 0 {
        string newContent = string:'join("\n", ...modifiedLines);
        error? writeResult = io:fileWriteString(filePath, newContent);
        if writeResult is error {
            return error BallerinaFixerError("Failed to write programmatic fix", writeResult);
        }
        
        log:printInfo("Applied programmatic fixes", fixesApplied = fixesApplied);
        return {
            success: true,
            errorsFixed: fixesApplied,
            appliedFixes: appliedFixes,
            errorMessage: ()
        };
    }
    
    return {
        success: false,
        errorsFixed: 0,
        appliedFixes: [],
        errorMessage: "No programmatic fixes applied"
    };
}

# Find which record contains a specific line number
function findRecordContainingLine(int lineNumber, string[] lines) returns string {
    // Look backwards from the error line to find the record declaration
    foreach int i in 0..<lineNumber {
        int lineIdx = lineNumber - 1 - i;
        if lineIdx >= 0 && lineIdx < lines.length() {
            string line = lines[lineIdx].trim();
            if line.startsWith("public type ") && line.includes(" record {") {
                string[] parts = regex:split(line, "\\s+");
                if parts.length() >= 3 {
                    return parts[2]; // Return the record name
                }
            }
        }
    }
    return "";
}

# Find the starting line of a record definition
function findRecordStartLine(string recordName, string[] lines) returns int {
    foreach int i in 0..<lines.length() {
        string line = lines[i].trim();
        if line.startsWith("public type " + recordName + " ") && line.includes("record {") {
            return i;
        }
    }
    return -1;
}

# Find the ending line of a record definition
function findRecordEndLine(int startLine, string[] lines) returns int {
    int braceCount = 0;
    foreach int i in startLine..<lines.length() {
        string line = lines[i];
        foreach string char in line {
            if char == "{" {
                braceCount += 1;
            } else if char == "}" {
                braceCount -= 1;
                if braceCount == 0 {
                    return i;
                }
            }
        }
    }
    return lines.length() - 1;
}

# Intelligently fix any Ballerina file by choosing the best approach based on file size
#
# + filePath - Path to Ballerina file
# + errors - Array of compilation errors 
# + fileType - Type description for specialized prompting
# + return - Result of fixing operation
function fixBallerinaFileIntelligently(string filePath, command_executor:CompilationError[] errors, string fileType) returns FileFixResult|BallerinaFixerError {
    string|error content = io:fileReadString(filePath);
    if content is error {
        return error BallerinaFixerError("Failed to read " + fileType, content);
    }

    string[] lines = regex:split(content, "\\n");
    int fileSize = content.length();
    
    log:printInfo("Analyzing file for fixing strategy", 
        fileType = fileType, 
        lineCount = lines.length(), 
        sizeBytes = fileSize, 
        errorCount = errors.length()
    );

    // For small files (< 1000 lines or < 50KB), use single-pass approach
    if lines.length() < 1000 && fileSize < 50000 {
        log:printInfo("Using single-pass approach for small file");
        return fixBallerinaFileSinglePass(filePath, errors, content, fileType);
    }
    
    // For large files, use chunked approach
    log:printInfo("Using chunked approach for large file");
    return fixLargeBallerinaFileInChunks(filePath, errors, content, lines, fileType);
}

# Fix small Ballerina files in a single pass with full context
function fixBallerinaFileSinglePass(string filePath, command_executor:CompilationError[] errors, string content, string fileType) returns FileFixResult|BallerinaFixerError {
    string errorContext = buildDetailedErrorContext(errors, content);
    
    string prompt = string `You are an expert Ballerina developer. Fix ALL the following compilation errors in this ${fileType} file.

COMPILATION ERRORS TO FIX:
${errorContext}

CURRENT ${fileType.toUpperAscii()} FILE CONTENT:
${content}

CRITICAL INSTRUCTIONS:
1. Fix ALL errors listed above, not just the first few
2. For redeclared symbol errors: inline conflicting fields and remove duplicate record inclusions  
3. For type/syntax errors: fix annotations, imports, missing tokens, brackets
4. For constraint violations: fix constraint annotations and imports
5. Preserve all existing functionality, documentation, and structure
6. Make only the minimal necessary changes to fix compilation errors
7. Return the COMPLETE corrected file - do not truncate or omit any content

Return ONLY the complete corrected Ballerina code without explanations or markdown formatting.`;

    string|llm_service:LLMServiceError fixedCode = llm_service:fixBallerinaCode(prompt);
    if fixedCode is llm_service:LLMServiceError {
        return error BallerinaFixerError("AI failed to fix " + fileType, fixedCode);
    }

    error? writeResult = io:fileWriteString(filePath, fixedCode);
    if writeResult is error {
        return error BallerinaFixerError("Failed to write fixed " + fileType, writeResult);
    }

    return {
        success: true,
        errorsFixed: errors.length(),
        appliedFixes: ["AI_SINGLE_PASS_FIX"],
        errorMessage: ()
    };
}

# Fix large Ballerina files using targeted chunked approach
function fixLargeBallerinaFileInChunks(string filePath, command_executor:CompilationError[] errors, string content, string[] initialLines, string fileType) returns FileFixResult|BallerinaFixerError {
    int totalFixed = 0;
    string[] appliedFixes = [];
    string[] currentLines = initialLines; // Create a local copy we can modify
    
    // Group errors by their line location into logical chunks
    map<command_executor:CompilationError[]> errorChunks = groupErrorsByLogicalChunks(errors, currentLines);
    
    log:printInfo("Grouped errors into chunks", chunkCount = errorChunks.length());
    
    // Process each chunk of errors
    foreach string chunkKey in errorChunks.keys() {
        command_executor:CompilationError[]? chunkErrors = errorChunks[chunkKey];
        if chunkErrors is command_executor:CompilationError[] {
            log:printInfo("Processing error chunk", chunkKey = chunkKey, errorCount = chunkErrors.length());
            
            FileFixResult|BallerinaFixerError chunkResult = fixErrorChunkTargeted(filePath, chunkErrors, fileType);
            
            if chunkResult is FileFixResult && chunkResult.success {
                totalFixed += chunkResult.errorsFixed;
                appliedFixes.push(...chunkResult.appliedFixes);
                log:printInfo("Successfully fixed chunk", chunkKey = chunkKey, fixedCount = chunkResult.errorsFixed);
                
                // Re-read file for next iteration
                string|error updatedContent = io:fileReadString(filePath);
                if updatedContent is string {
                    currentLines = regex:split(updatedContent, "\\n");
                }
            } else if chunkResult is BallerinaFixerError {
                log:printError("Failed to fix chunk", chunkKey = chunkKey, 'error = chunkResult);
                // Continue with other chunks even if one fails
            }
        }
    }
    
    return {
        success: totalFixed > 0,
        errorsFixed: totalFixed,
        appliedFixes: appliedFixes,
        errorMessage: ()
    };
}

# Group errors into logical chunks based on code structure and proximity
function groupErrorsByLogicalChunks(command_executor:CompilationError[] errors, string[] lines) returns map<command_executor:CompilationError[]> {
    map<command_executor:CompilationError[]> chunks = {};
    
    foreach command_executor:CompilationError err in errors {
        // Find the record/type containing this error
        string chunkKey = findLogicalChunkForError(err, lines);
        
        command_executor:CompilationError[]? existing = chunks[chunkKey];
        if existing is command_executor:CompilationError[] {
            existing.push(err);
        } else {
            chunks[chunkKey] = [err];
        }
    }
    
    return chunks;
}

# Find which logical code block (record, type, etc.) contains an error
function findLogicalChunkForError(command_executor:CompilationError err, string[] lines) returns string {
    int errorLine = err.line - 1; // Convert to 0-based index
    
    // Look backwards from error line to find the containing record/type
    foreach int i in 0...errorLine {
        int lineIdx = errorLine - i;
        if lineIdx >= 0 && lineIdx < lines.length() {
            string line = lines[lineIdx].trim();
            
            // Look for record/type declarations
            if line.startsWith("public type ") || line.startsWith("type ") {
                string[] parts = regex:split(line, "\\s+");
                if parts.length() >= 3 {
                    string typeName = parts[2];
                    return string `type_${typeName}_line_${lineIdx + 1}`;
                }
            }
        }
    }
    
    // If no specific type found, group by line ranges
    int chunkIndex = errorLine / 50; // 50-line chunks
    return string `chunk_${chunkIndex}`;
}

# Fix a targeted chunk of errors in a specific code section  
function fixErrorChunkTargeted(string filePath, command_executor:CompilationError[] chunkErrors, string fileType) returns FileFixResult|BallerinaFixerError {
    string|error content = io:fileReadString(filePath);
    if content is error {
        return error BallerinaFixerError("Failed to read file for chunk fix", content);
    }
    
    string[] lines = regex:split(content, "\\n");
    
    // Find the range of lines we need to work with
    int minLine = chunkErrors[0].line;
    int maxLine = chunkErrors[0].line;
    
    foreach command_executor:CompilationError err in chunkErrors {
        if err.line < minLine {
            minLine = err.line;
        }
        if err.line > maxLine {
            maxLine = err.line;
        }
    }
    
    // Expand context (100 lines before and after to capture full record/type definitions)
    int contextStart = (minLine - 100) > 1 ? (minLine - 100) : 1;
    int contextEnd = (maxLine + 100) < lines.length() ? (maxLine + 100) : lines.length();
    
    // Extract the relevant code section
    string[] contextLines = [];
    foreach int i in (contextStart-1)..<(contextEnd) {
        if i >= 0 && i < lines.length() {
            contextLines.push(lines[i]);
        }
    }
    string contextCode = string:'join("\n", ...contextLines);
    
    string errorContext = buildDetailedErrorContext(chunkErrors, content);
    
    string prompt = string `You are an expert Ballerina developer. Fix the following compilation errors in this section of a ${fileType} file.

COMPILATION ERRORS TO FIX (lines ${minLine}-${maxLine}):
${errorContext}

CODE SECTION TO FIX (lines ${contextStart}-${contextEnd}):
${contextCode}

CRITICAL INSTRUCTIONS:
1. Fix ALL the listed errors in this code section
2. For redeclared symbol errors: inline conflicting record fields and remove duplicate inclusions
3. For syntax/type errors: fix all missing tokens, type mismatches, imports
4. Return ONLY the corrected code section that replaces lines ${contextStart}-${contextEnd}
5. Maintain exact line structure and preserve all documentation/comments
6. Do not add explanations or markdown - just the corrected code

Fixed code section:`;

    string|llm_service:LLMServiceError fixedChunk = llm_service:fixBallerinaCode(prompt);
    if fixedChunk is llm_service:LLMServiceError {
        return error BallerinaFixerError("AI failed to fix chunk", fixedChunk);
    }
    
    // Replace the relevant section in the file
    string[] fixedLines = regex:split(fixedChunk, "\\n");
    string[] newFileLines = [];
    
    // Add lines before the fixed section
    foreach int i in 0..<(contextStart-1) {
        if i < lines.length() {
            newFileLines.push(lines[i]);
        }
    }
    
    // Add the fixed lines  
    newFileLines.push(...fixedLines);
    
    // Add lines after the fixed section
    foreach int i in contextEnd..<lines.length() {
        newFileLines.push(lines[i]);
    }
    
    string newContent = string:'join("\n", ...newFileLines);
    
    error? writeResult = io:fileWriteString(filePath, newContent);
    if writeResult is error {
        return error BallerinaFixerError("Failed to write chunk fix", writeResult);
    }
    
    return {
        success: true,
        errorsFixed: chunkErrors.length(),
        appliedFixes: [string `CHUNK_FIX_${contextStart}-${contextEnd}`],
        errorMessage: ()
    };
}

# Fix errors in client.bal file using AI
#
# + filePath - Path to client.bal file
# + errors - Array of compilation errors
# + return - Result of fixing operation
function fixClientFileErrors(string filePath, command_executor:CompilationError[] errors) returns FileFixResult|BallerinaFixerError {
    string|error content = io:fileReadString(filePath);
    if content is error {
        return error BallerinaFixerError("Failed to read client.bal", content);
    }
    
    string errorContext = buildDetailedErrorContext(errors, content);
    
    string prompt = string `You are an expert Ballerina developer. Fix the following compilation errors in this Ballerina client.bal file.

COMPILATION ERRORS:
${errorContext}

CURRENT CLIENT.BAL CONTENT:
${content}

INSTRUCTIONS:
1. Analyze each compilation error in the context of Ballerina HTTP client generation
2. For HTTP client issues:
   - Fix resource function signatures and parameter types
   - Ensure proper HTTP method annotations
   - Fix path parameter and query parameter handling
   - Correct return type declarations
3. For type mismatches:
   - Ensure request/response types match the generated types.bal
   - Fix header and query parameter type conflicts
   - Use proper union types for optional parameters
4. For import errors:
   - Add missing imports (ballerina/http, ballerina/data.jsondata, etc.)
   - Remove unused imports
5. For syntax errors:
   - Fix resource function declarations
   - Correct annotation syntax (@http:ResourceConfig, etc.)
   - Fix missing semicolons and brackets
6. For constraint issues:
   - Ensure proper parameter validation
   - Fix constraint annotations
7. IMPORTANT:
   - Preserve the HTTP client class structure
   - Keep all resource functions functional
   - Maintain API endpoint mappings
   - Ensure proper error handling

Return ONLY the complete corrected Ballerina code without explanations or markdown formatting.`;

    string|llm_service:LLMServiceError fixedCode = llm_service:fixBallerinaCode(prompt);
    if fixedCode is llm_service:LLMServiceError {
        return error BallerinaFixerError("AI failed to fix client.bal", fixedCode);
    }
    
    error? writeResult = io:fileWriteString(filePath, fixedCode);
    if writeResult is error {
        return error BallerinaFixerError("Failed to write fixed client.bal", writeResult);
    }
    
    return {
        success: true,
        errorsFixed: errors.length(),
        appliedFixes: ["AI_CLIENT_FIX"],
        errorMessage: ()
    };
}

# Fix errors in utils.bal file using AI
#
# + filePath - Path to utils.bal file
# + errors - Array of compilation errors
# + return - Result of fixing operation
function fixUtilsFileErrors(string filePath, command_executor:CompilationError[] errors) returns FileFixResult|BallerinaFixerError {
    string|error content = io:fileReadString(filePath);
    if content is error {
        return error BallerinaFixerError("Failed to read utils.bal", content);
    }

    string errorContext = buildDetailedErrorContext(errors, content);

    string prompt = string `You are an expert Ballerina developer. Fix the following compilation errors in this Ballerina utils.bal file.

COMPILATION ERRORS:
${errorContext}

CURRENT UTILS.BAL CONTENT:
${content}

INSTRUCTIONS:
1. Analyze each compilation error in the context of utility functions
2. For URL encoding/decoding issues:
   - Fix parameter type mismatches in encoding functions
   - Ensure proper string handling and error handling
   - Fix URL parameter serialization logic
3. For HTTP utility functions:
   - Fix query parameter building functions
   - Correct form data serialization
   - Ensure proper header handling
4. For type conversion issues:
   - Fix type casting and conversion functions
   - Ensure proper handling of optional values
   - Use appropriate union types
5. For import errors:
   - Add missing imports (ballerina/http, ballerina/url, etc.)
   - Remove unused imports
6. For syntax errors:
   - Fix function signatures and return types
   - Correct variable declarations and assignments
   - Fix missing semicolons and brackets
7. IMPORTANT:
   - Preserve all utility function functionality
   - Maintain backward compatibility
   - Ensure proper error handling
   - Keep performance optimizations

Return ONLY the complete corrected Ballerina code without explanations or markdown formatting.`;

    string|llm_service:LLMServiceError fixedCode = llm_service:fixBallerinaCode(prompt);
    if fixedCode is llm_service:LLMServiceError {
        return error BallerinaFixerError("AI failed to fix utils.bal", fixedCode);
    }

    error? writeResult = io:fileWriteString(filePath, fixedCode);
    if writeResult is error {
        return error BallerinaFixerError("Failed to write fixed utils.bal", writeResult);
    }

    return {
        success: true,
        errorsFixed: errors.length(),
        appliedFixes: ["AI_UTILS_FIX"],
        errorMessage: ()
    };
}

# Fix errors in any generic Ballerina file using intelligent approach
#
# + filePath - Path to Ballerina file
# + errors - Array of compilation errors
# + return - Result of fixing operation
function fixGenericBallerinaFile(string filePath, command_executor:CompilationError[] errors) returns FileFixResult|BallerinaFixerError {
    // Extract file type from path for better prompting
    string[] pathParts = regex:split(filePath, "/");
    string fileName = pathParts[pathParts.length() - 1];
    
    return fixBallerinaFileIntelligently(filePath, errors, fileName);
}
