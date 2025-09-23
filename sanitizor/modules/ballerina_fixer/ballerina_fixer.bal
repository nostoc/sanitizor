import sanitizor.command_executor;

import ballerina/ai;
import ballerina/file;
import ballerina/io;
import ballerina/lang.regexp;
import ballerina/log;
import ballerina/regex;
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
        log:printInfo("STarting iteration: ", iteration = iteration);

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
    string[] lines = regex:split(stderr, "\n");

    foreach string line in lines {
        if line.trim().length() == 0 {
            continue;
        }

        // parse ballerina error format: ERROR [file.bal:(line,column)] message
        string pattern = "(ERROR|WARNING)\\s+\\[([^:]+):?\\((\\d+),(\\d+)\\)\\]\\s+(.+)";
        regex:Match? matches = regex:search(line, pattern);

        if matches is regex:Match {
            CompilationError err = {
                severity: matches.groups[0].substring,
                filePath: matches.groups[1].substring,
                line: check int:fromString(matches.groups[2].substring),
                column: check int:fromString(matches.groups[3].substring),
                message: matches.groups[4].substring
            };

            errors.push(err);
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
    string prompt = createFixPrompt(codeToFix, errorContext, filePath);

    FixResponse|error llmResponse = model->generate(prompt);
    if llmResponse is error {
        log:printError("LLM failed to generate a fix", 'error = llmResponse);
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
        io:Error? backedUp = io:fileWriteString(filePath, originalContent);
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
    string[] lines = regex:split(fullCode, "\n");

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

function (CompilationError err) returns string {
    return string `${err.severity} at ${err.filePath}:${err.line}:${err.column} - ${err.message}`;

}
