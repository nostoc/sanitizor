import sanitizor.command_executor;

import ballerina/ai;
import ballerina/io;
import ballerina/lang.regexp;
import ballerina/log;
import ballerinax/ai.anthropic;

configurable string apiKey = ?;
configurable int maxIterations = ?;

const int MAX_CODE_LENGTH = 1000;

public type BallerinaFixResult record {|
    boolean success;
    int errorsFixed;
    int errorsRemaining;
    string[] appliedFixes;
    string[] remainingFixes;
|};

type CompilationError record {|
    string filePath;
    int line;
    int column;
    string message;
    string severity;
    string code?;
|};

public type BallerinaFixerError error;

public function fixAllBallerinaErrors(string projectPath) returns BallerinaFixerError|BallerinaFixResult {
    log:printInfo("Starting ballerina error fixing process", projectPath = projectPath);

    BallerinaFixResult result = {
        success: false,
        errorsFixed: 0,
        errorsRemaining: 0,
        appliedFixes: [],
        remainingFixes: []
    };

    ai:ModelProvider anthropicModel = check new anthropic:ModelProvider(apiKey, anthropic:CLAUDE_SONNET_4_20250514, maxTokens = 400000);

    int iteration = 0;

    while iteration < maxIterations {
        iteration += 1;
        log:printInfo("Starting iteration: ", iteration = iteration);

        // build the project and get diagnostics

        command_executor:CommandResult buildResult = command_executor:executeBalBuild(projectPath);

        if command_executor:isCommandSuccessfull(buildResult) {
            log:printInfo("Build successfull!. All errors fiexed.");
            result.success = true;
            return result;
        }

        // Parse errors from build output
        CompilationError[] errors = parseCompilationErrors(buildResult.stderr);
        result.errorsRemaining = errors.length();

        if errors.length() == 0 {
            log:printInfo("No compilation errors found, but build failed", stderr = buildResult.stderr);
            break;
        }
        log:printInfo("Found compilation errors", count = errors.length());

        //group errors by file 
        map<CompilationError[]> errosByFile = groupErrorsByFile(errors);

        boolean anyErrorFixed = false;
        foreach string filePath in errosByFile.keys() {
            CompilationError[] fileErrors = errosByFile.get(filePath);

            //try to fix errors in this file
            boolean|error fixResult = fixErrorsInFile(anthropicModel, filePath, fileErrors);
            if fixResult is boolean && fixResult {
                anyErrorFixed = true;
                result.errorsFixed += fileErrors.length();
                result.appliedFixes.push(string `Fixed ${fileErrors.length()} in ${filePath}`);
            } else if fixResult is error {
                log:printError("Failed to fix errors in file: ", filePath = filePath, 'error = fixResult);
            }
        }
        if !anyErrorFixed {
            log:printWarn("No errors were fixed in this ieteration :(");
            break;
        }

    }
    // final check 

    command_executor:CommandResult finalBuildResult = command_executor:executeBalBuild(projectPath);
    if command_executor:isCommandSuccessfull(finalBuildResult) {
        result.success = true;
        result.errorsRemaining = 0;
    } else {
        CompilationError[] remainingErrors = parseCompilationErrors(finalBuildResult.stderr);
        result.errorsRemaining = remainingErrors.length();
    }

    return result;
}

function groupErrorsByFile(CompilationError[] errors) returns map<CompilationError[]> {
    map<CompilationError[]> grouped = {};

    foreach CompilationError err in errors {
        if !grouped.hasKey(err.filePath) {
            grouped[err.filePath] = [];
        }
        grouped.get(err.filePath).push(err);
    }
    return grouped;
}

function parseCompilationErrors(string stderr) returns CompilationError[] {
    CompilationError[] errors = [];
    string[] lines = regexp:split(re `\n`, stderr);

    foreach string line in lines {
        if line.trim().length() == 0 {
            continue;
        }

        // parse ballerina error format: ERROR [file.bal:(line,column)] message
        regexp:RegExp pattern = re `(ERROR|WARNING)\s+\[([^:]+):?\((\d+),(\d+)\)\]\s+(.+)`;
        regexp:Groups? groups = pattern.findGroups(line);

        if groups is regexp:Groups {
            var group1 = groups[1];
            var group2 = groups[2];
            var group3 = groups[3];
            var group4 = groups[4];
            var group5 = groups[5];
            
            if group1 is regexp:Span && group2 is regexp:Span && 
               group3 is regexp:Span && group4 is regexp:Span && 
               group5 is regexp:Span {
                
                int|error lineNum = int:fromString(group3.substring());
                int|error colNum = int:fromString(group4.substring());
                
                if lineNum is int && colNum is int {
                    CompilationError err = {
                        severity: group1.substring(),
                        filePath: group2.substring(),
                        line: lineNum,
                        column: colNum,
                        message: group5.substring()
                    };

                    errors.push(err);
                }
            }
        }
    }

    return errors;
}

function fixErrorsInFile(ai:ModelProvider model, string filePath, CompilationError[] errors) returns boolean|error {
    log:printInfo("Attempting to fix errors in file: ", filePath = filePath, errorCount = errors.length());

    // read file 
    string fileContent = check io:fileReadString(filePath);

    // if file is too large extract relevant sections
    string codeToFix = extractRelevantCode(fileContent, errors);

    // prepare error context
    string errorContext = prepareErrorContext(errors);

    //Get fix from LLM
    string promptText = createFixPrompt(codeToFix, errorContext, filePath);

    ai:ChatMessage[] messages = [
        {role: "user", content: promptText}
    ];

    ai:ChatAssistantMessage|error response = model->chat(messages);
    if response is error {
        log:printError("LLM failed to generate a fix", 'error = response);
        return response;
    }

    // Parse the JSON response
    string? content = response.content;
    if content is () {
        return error("Empty response from LLM");
    }

    FixResponse|error llmResponse = parseFixResponse(content);
    if llmResponse is error {
        log:printError("Failed to parse LLM response", 'error = llmResponse);
        return llmResponse;
    }

    // Apply the fix
    boolean applied = applyFix(filePath, llmResponse, fileContent);
    return applied;

}

function applyFix(string filePath, FixResponse fix, string originalContent) returns boolean {
    if fix.confidence == "low" {
        log:printWarn("LLM has low confidence in fix, skipping", filePath = filePath);
        return false;
    }

    //create a backup
    string backupPath = filePath + ".backup";
    io:Error? backupResult = io:fileWriteString(backupPath, originalContent);
    if backupResult is error {
        log:printError("Failed to create backup", 'error = backupResult);
        return false;
    }

    // apply the fix
    io:Error? writeResult = io:fileWriteString(filePath, fix.fixedCode);
    if writeResult is error {
        log:printError("Failed to write fixed code", 'error = writeResult);
        io:Error? restoreResult = io:fileWriteString(filePath, originalContent);
        if restoreResult is error {
            log:printError("Failed to restore original content", 'error = restoreResult);
        }
        return false;
    }

    log:printInfo("Applied fix to file", filePath = filePath, explanation = fix.explanation);
    return true;
}

function createFixPrompt(string code, string errorContext, string filePath) returns string {
    return string `You are an expert ballerina programmer. I need you to fix compilation errors in the following ballerina code.
    FIle: ${filePath}

    Compilation Errors: ${errorContext}
    
    Code to fix: ${code}
    
    Please provide the corrected code. Your response must be in the follwoing JSON format:

    {
    "fixedCode": "the complete corrected code",
    "explanation": "brief explanation of what was fixed",
    "confidence": "high|medium|low"
    }

    Important guidelines:
    1. Only fix the specific compilation errors mentioned
    2. Preserve the original code structure and logic as much as possible
    3. Ensure the fixed code follows Ballerina best practices
    4. If you're not confident about a fix, indicate low confidence
    5. Return the complete code section, not just the changed parts`;
}

function prepareErrorContext(CompilationError[] errors) returns string {
    string[] errorStrings = errors.'map(function(CompilationError err) returns string {
        return string `Line ${err.line}, Column ${err.column}: ${err.message}`;
    });
    return string:'join("\n", ...errorStrings);
}

function extractRelevantCode(string fullCode, CompilationError[] errors) returns string {
    if fullCode.length() <= MAX_CODE_LENGTH {
        return fullCode;
    }

    // find the range of lines that contain 
    int minLine = errors.reduce(function(int acc, CompilationError err) returns int {
        return int:min(acc, err.line);
    }, int:MAX_VALUE);

    int maxLine = errors.reduce(function(int acc, CompilationError err) returns int {
        return int:max(acc, err.line);
    }, 0);

    // add some context around the error lines
    int contextLines = 10;
    string[] lines = regexp:split(re `\n`, fullCode);

    int startLine = int:max(0, minLine - contextLines - 1);
    int endLine = int:min(lines.length() - 1, maxLine + contextLines - 1);

    string[] relevantLines = lines.slice(startLine, endLine + 1);

    return string:'join("\n", ...relevantLines);

}

type FixResponse record {|
    string fixedCode;
    string explanation;
    string confidence;
|};

function parseFixResponse(string content) returns FixResponse|error {
    // Try to parse as JSON
    json|error jsonResult = content.fromJsonString();
    if jsonResult is error {
        // If JSON parsing fails, treat the entire content as fixed code with medium confidence
        return {
            fixedCode: content,
            explanation: "LLM provided direct code fix",
            confidence: "medium"
        };
    }

    json jsonData = jsonResult;
    if jsonData is map<json> {
        string? fixedCode = jsonData["fixedCode"] is string ? <string>jsonData["fixedCode"] : ();
        string? explanation = jsonData["explanation"] is string ? <string>jsonData["explanation"] : ();
        string? confidence = jsonData["confidence"] is string ? <string>jsonData["confidence"] : ();

        if fixedCode is () {
            return error("Missing 'fixedCode' field in LLM response");
        }

        return {
            fixedCode: fixedCode,
            explanation: explanation ?: "No explanation provided",
            confidence: confidence ?: "medium"
        };
    }

    return error("Invalid JSON structure in LLM response");
}

function errorToString(CompilationError err) returns string {
    return string `${err.severity} at ${err.filePath}:${err.line}:${err.column} - ${err.message}`;
}
