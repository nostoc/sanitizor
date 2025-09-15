import sanitizor.command_executor as commandExec;

import ballerina/file;
import ballerina/io;
import ballerina/time;

public type FileManagementError distinct error;

public type RenameResult record {|
    string originalBackupPath;
    string newSpecPath;
|};

public type WorkspaceConfig record {|
    string workspacePath;
    string originalSpec;
    string workingSPec;
    string[] tempFiles;
|};

# Backup the original OpenAPI spec file with timestamp
#
# + specPath - Path to the OpenAPI spec file to backup
# + return - Path to the backup file or error
public function backupSpec(string specPath) returns string|FileManagementError {
    boolean|error exists = file:test(specPath, file:EXISTS);
    if exists is error || !exists {
        return error FileManagementError("Source spec file doesnot exist.");
    }

    time:Utc currentTime = time:utcNow();
    string timeStamp = currentTime[0].toString();
    string backupPath = specPath + ".backup" + timeStamp;

    error? result = copySpecFile(specPath, backupPath);
    if result is error {
        return error FileManagementError("Failed to create backup", result);
    }
    return backupPath;
}

# Copy spec file from source to target
#
# + sourcePath - Source file path
# + targetPath - Target file path  
# + return - Error if copy fails
public function copySpecFile(string sourcePath, string targetPath) returns error? {
    boolean|error sourceExists = file:test(sourcePath, file:EXISTS);
    if sourceExists is error || !sourceExists {
        return error FileManagementError("Source file does not exist.");
    }

    string targetDir = commandExec:getDirectoryPath(targetPath);
    if (targetDir != "") {
        boolean|error dirExists = file:test(targetDir, file:EXISTS);
        if (dirExists is error || !dirExists) {
            check file:createDir(targetDir, file:RECURSIVE);
        }
    }

    // Copy file content
    string content = check io:fileReadString(sourcePath);
    check io:fileWriteString(targetPath, content);
}

