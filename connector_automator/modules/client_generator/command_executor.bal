import ballerina/file;
import ballerina/io;
import ballerina/log;
import ballerina/os;
import ballerina/regex;
import ballerina/time;

# Execute shell commands and capture results
#
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
            // Create temporary files for stdout and stderr
            string tempDir = "/tmp";
            int timestamp = <int>time:utcNow()[0];
            string stdoutFile = string `${tempDir}/bal_stdout_${timestamp}.txt`;
            string stderrFile = string `${tempDir}/bal_stderr_${timestamp}.txt`;

            // Parse command into executable and arguments
            string[] commandParts = regex:split(command, " ");
            if commandParts.length() == 0 {
                stderr = "Empty command";
                exitCode = 1;
            } else {
                // Modify command to redirect stdout and stderr to files
                // Use shell to execute: command > stdout.txt 2> stderr.txt
                string redirectedCommand = string `cd "${workingDir}" && ${command} > "${stdoutFile}" 2> "${stderrFile}"`;

                os:Command cmd = {
                    value: "sh",
                    arguments: ["-c", redirectedCommand]
                };

                os:Process|error proc = os:exec(cmd);
                if proc is os:Process {
                    // Wait for process to finish and get exit code
                    int|error exitResult = proc.waitForExit();
                    if exitResult is int {
                        exitCode = exitResult;
                        success = exitCode == 0;

                        // Read stdout from file
                        string|io:Error stdoutContent = io:fileReadString(stdoutFile);
                        if stdoutContent is string {
                            stdout = stdoutContent;
                        } else {
                            stdout = "";
                            log:printWarn("Failed to read stdout file", 'error = stdoutContent);
                        }

                        // Read stderr from file
                        string|io:Error stderrContent = io:fileReadString(stderrFile);
                        if stderrContent is string {
                            stderr = stderrContent;
                        } else {
                            stderr = "";
                            log:printWarn("Failed to read stderr file", 'error = stderrContent);
                        }

                        // Clean up temporary files
                        file:Error? stdoutDeleteResult = file:remove(stdoutFile);
                        if stdoutDeleteResult is file:Error {
                            log:printWarn("Failed to delete stdout temp file", path = stdoutFile);
                        }

                        file:Error? stderrDeleteResult = file:remove(stderrFile);
                        if stderrDeleteResult is file:Error {
                            log:printWarn("Failed to delete stderr temp file", path = stderrFile);
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
    }
    time:Utc endTime = time:utcNow();
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

# Execute bal openapi client generation command
#
# + inputPath - Path to aligned openAPI spec file
# + outputPath - Path to output directory for generated ballerina client
# + customOptions - Optional custom options to override defaults
# + return - `CommandResult` with execution details
public function executeBalClientGenerate(string inputPath, string outputPath, OpenAPIToolOptions? customOptions = ()) returns CommandResult {
    // Use custom options if provided, otherwise use configurable options
    OpenAPIToolOptions toolOptions = customOptions ?: options;

    // Build the base command
    string command = string `bal openapi -i ${inputPath} --mode client -o ${outputPath}`;

    // Add optional flags based on configuration
    if toolOptions.license is string {
        string licensePath = toolOptions.license;
        
        // If it's a relative path, resolve it relative to the working directory (parent of output)
        if !licensePath.startsWith("/") {
            // Get the working directory (parent directory of output path)
            string workingDir = getDirectoryPath(outputPath);
            licensePath = string `${workingDir}/${licensePath}`;
        }
        
        // Check if license file exists before adding to command
        boolean|file:Error licenseExists = file:test(licensePath, file:EXISTS);
        if licenseExists is boolean && licenseExists {
            command += string ` --license ${licensePath}`;
        } else {
            log:printWarn("License file not found, skipping license option", licensePath = licensePath);
        }
    }

    if toolOptions.tags is string[] {
        string tagsList = string:'join(",", ...toolOptions.tags ?: []);
        command += string ` --tags ${tagsList}`;
    }

    if toolOptions.operations is string[] {
        string operationsList = string:'join(",", ...toolOptions.operations ?: []);
        command += string ` --operations ${operationsList}`;
    }

    command += string ` --client-methods ${toolOptions.clientMethod}`;

    return executeCommand(command, getDirectoryPath(outputPath));
}