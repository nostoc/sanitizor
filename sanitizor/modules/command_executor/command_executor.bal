import ballerina/file;
import ballerina/io;
import ballerina/log;
import ballerina/os;
import ballerina/regex;
import ballerina/time;

public type CommandExecutorError distinct error;

# Compilation error from a `bal build` output
public type CompilationError record {|
    # name of the file where error occured
    string fileName;
    # Line number of the error
    int line;
    # Column number of the error
    int column;
    # Error message description
    string message;
    # Type of error (ERROR, WARNING)
    string errorType;
|};

# result of executing a `bal` command
public type CommandResult record {|
    # The command that was executed
    string command;
    # Whether the command executed successfully
    boolean success;
    # Exit code returned by the command
    int exitCode;
    # Standard output from the command
    string stdout;
    # Standard error output from the command
    string stderr;
    # Parsed compilation errors from the output
    CompilationError[] compilationErrors;
    # Execution time 
    decimal executionTime;
|};

# Execute shell commands and capture results
# + command - Command to execute
# + workingDir - working directory for command execution
# + return - `CommandResult` with all execution details
function executeCommand(string command, string workingDir) returns CommandResult {
    time:Utc startTime = time:utcNow();

    log:printInfo("Executing", command = command, workingDirectory = workingDir);

    string stdout = "";
    string stderr = "";
    int exitCode = -1;
    boolean success = false;

    if command.trim().length() == 0 {
        stderr = "Empty command string";
        exitCode = 1;
    } else {
        // Create working directory if it doesn't exist
        if workingDir.trim().length() > 0 {
            boolean|error dirExists = file:test(workingDir, file:EXISTS);
            if dirExists is error || !dirExists {
                error? createResult = file:createDir(workingDir, file:RECURSIVE);
                if createResult is error {
                    stderr = string `Failed to create working directory: ${createResult.toString()}`;
                    exitCode = 1;
                    success = false;
                } else {
                    log:printInfo("Created working directory", workingDir = workingDir);
                }
            }
        }

        if stderr == "" { // Only execute if directory creation succeeded
            // Parse command into executable and arguments
            string[] commandParts = regex:split(command, " ");
            if commandParts.length() == 0 {
                stderr = "Empty command";
                exitCode = 1;
            } else {
                string executable = commandParts[0];
                string[] arguments = commandParts.slice(1);
                
                os:Command cmd = {
                    value: executable,
                    arguments: arguments
                };
                
                os:Process|error proc = os:exec(cmd, env = {}, dir = workingDir);
                if proc is os:Process {
                    // Wait for process to finish and get exit code
                    int|error exitResult = proc.waitForExit();
                    if exitResult is int {
                        exitCode = exitResult;
                        success = exitCode == 0;
                        
                        // Get stdout
                        byte[]|error stdoutBytes = proc.output();
                        if stdoutBytes is byte[] {
                            string|error stdoutResult = string:fromBytes(stdoutBytes);
                            stdout = stdoutResult is string ? stdoutResult : stdoutResult.toString();
                        } else {
                            stdout = "";
                        }
                        
                        // Get stderr  
                        byte[]|error stderrBytes = proc.output(io:stderr);
                        if stderrBytes is byte[] {
                            string|error stderrResult = string:fromBytes(stderrBytes);
                            stderr = stderrResult is string ? stderrResult : stderrResult.toString();
                        } else {
                            stderr = "";
                        }
                    } else {
                        stderr = exitResult.toString();
                        exitCode = 1;
                    }
                } else {
                    stderr = proc.toString();
                    exitCode = 1;
                }
            }
        }
    }    time:Utc endTime = time:utcNow();
    decimal executionTime = <decimal>(endTime[0] - startTime[0]);

    if (!success) {
        log:printWarn("Command failed", exitCode = exitCode, stderr = stderr);
    }

    // Parse compilation errors from stderr if it contains error messages
    CompilationError[] compilationErrors = [];
    if stderr.includes("ERROR [") || stderr.includes("WARNING [") {
        compilationErrors = parseCompilationErrors(stderr);
    }

    return {
        command: command,
        success: success,
        exitCode: exitCode,
        stdout: stdout,
        stderr: stderr,
        compilationErrors: compilationErrors,
        executionTime: executionTime
    };
}

# Helper function to extract directory path from file path
#
# + filePath - Full file path
# + return - DIrectory path or current directory
public function getDirectoryPath(string filePath) returns string {
    int? lastSlashIndex = filePath.lastIndexOf("/");
    if lastSlashIndex is int {
        return filePath.substring(0, lastSlashIndex);
    }
    return ".";
}

public function parseCompilationErrors(string output) returns CompilationError[] {
    CompilationError[] errors = [];

    string[] lines = regex:split(output, "\n");

    foreach string line in lines {
        // Handle both ERROR and WARNING messages
        if (line.includes("ERROR [") || line.includes("WARNING [")) && line.includes(")]") {
            string errorType = line.includes("ERROR [") ? "ERROR" : "WARNING";
            string prefix = errorType + " [";

            int? startBracket = line.indexOf(prefix);
            int? endBracket = line.indexOf(")]", startBracket ?: 0);

            if startBracket is int && endBracket is int {
                // Extract the part between prefix and ")]"
                string errorPart = line.substring(startBracket + prefix.length(), endBracket);

                // Find the last occurrence of ":(" to split filename from coordinates
                int? coordStart = errorPart.lastIndexOf(":(");

                if coordStart is int {
                    string fileName = errorPart.substring(0, coordStart);
                    string coordinates = errorPart.substring(coordStart + 2); // Skip ":("

                    // Parse coordinates - format can be (line:col) or (line:col,endLine:endCol)
                    string[] coordParts = regex:split(coordinates, ",");
                    if coordParts.length() > 0 {
                        // Get the first coordinate pair (line:col)
                        string[] lineCol = regex:split(coordParts[0], ":");
                        if lineCol.length() >= 2 {
                            int|error lineNum = int:fromString(lineCol[0]);
                            int|error col = int:fromString(lineCol[1]);

                            // Extract message - everything after ")]" plus 2 for ") "
                            string message = line.substring(endBracket + 2).trim();

                            if lineNum is int && col is int {
                                CompilationError compilationError = {
                                    fileName: fileName,
                                    line: lineNum,
                                    errorType: errorType,
                                    column: col,
                                    message: message
                                };
                                errors.push(compilationError);
                            }
                        }
                    }
                }
            }
        }
    }
    return errors;
}

# Check if a command result indicates success
#
# + result - CommandResult to check
# + return - true if command executed successfully, false otherwise
public function isCommandSuccessfull(CommandResult result) returns boolean {
    return result.success && result.exitCode == 0 && result.compilationErrors.length() == 0;
}

public function getErrorSummary(CompilationError[] errors) returns string {
    if errors.length() == 0 {
        return "No compilation errors";
    }

    map<int> errorByFile = {};

    foreach CompilationError err in errors {
        int currentCount = errorByFile[err.fileName] ?: 0;
        errorByFile[err.fileName] = currentCount + 1;
    }

    string[] summaryParts = [];
    foreach string fileName in errorByFile.keys() {
        int count = errorByFile[fileName] ?: 0;
        summaryParts.push(string `${count} errors in ${fileName}`);
    }

    return string `Found ${errors.length()} total compilation errors: ${string:'join(",", ...summaryParts)}`;

}

# Execute `bal openapi flatten` command
#
# + inputPath - Path to input openAPI spec file
# + outputPath - Path to output directory
# + return - `CommandResult` with execution details
public function executeBalFlatten(string inputPath, string outputPath) returns CommandResult {
    string command = string `bal openapi flatten -i ${inputPath} -o ${outputPath}`;
    return executeCommand(command, ".");
}

# Execute `bal openapi align` command
#
# + inputPath - Path to flattened openAPI spec file
# + outputPath - Path to output directory
# + return - `CommandResult` with execution details
public function executeBalAlign(string inputPath, string outputPath) returns CommandResult {
    string command = string `bal openapi align -i ${inputPath} -o ${outputPath}`;
    return executeCommand(command, ".");
}

# Execute bal openapi client generation command
#
# + inputPath - Path to aligned openAPI spec file
# + outputPath - Path to output directory for generated ballerina client
# + return - `CommandResult` with execution details
public function executeBalClientGenerate(string inputPath, string outputPath) returns CommandResult {
    string command = string `bal openapi -i ${inputPath} --mode client -o ${outputPath}`;
    return executeCommand(command, getDirectoryPath(outputPath));
}

# Execute bal build command
# + projectPath - Path to Ballerina project directory
# + return - CommandResult with execution details and compilation errors
public function executeBalBuild(string projectPath) returns CommandResult {
    string command = "bal build";
    CommandResult result = executeCommand(command, projectPath);

    // Parse compilation errors from output
    string combinedOutput = result.stdout + "\n" + result.stderr;
    result.compilationErrors = parseCompilationErrors(combinedOutput);

    return result;
}