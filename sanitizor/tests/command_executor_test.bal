import sanitizor.command_executor;

import ballerina/file;
import ballerina/io;
import ballerina/test;

@test:Config {groups: ["command_execute"]}
function testFlattenCommand() returns error? {
    // Create test workspace
    string workspace = "test_workspace_cmd";
    check file:createDir(workspace, file:RECURSIVE);

    string inputFile = workspace + "/test_openapi.json";
    string testSpec = string `{
    "openapi": "3.0.1",
    "info": {"title": "Test", "version": "1.0"},
    "paths": {}
}`;

    check io:fileWriteString(inputFile, testSpec);

    // Test flatten command construction
    command_executor:CommandResult result = command_executor:executeBalFlatten(inputFile, workspace);

    // Should return command details even if execution fails in test environment
    test:assertTrue(result.command.includes("bal openapi flatten"));
    test:assertTrue(result.command.includes(inputFile));
    test:assertTrue(result.command.includes(workspace));

    // Cleanup
    _ = check file:remove(inputFile);
    _ = check file:remove(workspace);
}

@test:Config {groups: ["command_execute"]}
function testAlignCommand() returns error? {
    string workspace = "test_workspace_align";
    check file:createDir(workspace, file:RECURSIVE);

    string inputFile = workspace + "/flattened_openapi.json";
    string testSpec = string `{
    "openapi": "3.0.1",
    "info": {"title": "Test", "version": "1.0"},
    "paths": {}
}`;

    check io:fileWriteString(inputFile, testSpec);

    // Test align command construction
    command_executor:CommandResult result = command_executor:executeBalAlign(inputFile, workspace);

    test:assertTrue(result.command.includes("bal openapi align"));
    test:assertTrue(result.command.includes(inputFile));

    // Cleanup
    _ = check file:remove(inputFile);
    _ = check file:remove(workspace);
}

@test:Config {groups: ["command_execute"]}
function testClientGenerateCommand() returns error? {
    string workspace = "test_workspace_gen";
    check file:createDir(workspace, file:RECURSIVE);

    string inputFile = workspace + "/aligned_openapi.json";
    string outputDir = workspace + "/generated";
    string testSpec = string `{
    "openapi": "3.0.1",
    "info": {"title": "Test", "version": "1.0"},
    "paths": {}
}`;

    check io:fileWriteString(inputFile, testSpec);

    // Test client generation command
    command_executor:CommandResult result = command_executor:executeBalClientGenerate(inputFile, outputDir);

    test:assertTrue(result.command.includes("bal openapi"));
    test:assertTrue(result.command.includes("--mode client"));
    test:assertTrue(result.command.includes(inputFile));
    test:assertTrue(result.command.includes(outputDir));

    // Cleanup
    _ = check file:remove(inputFile);
    _ = check file:remove(workspace);
}

@test:Config {groups: ["command_execute"]}
function testBuildCommand() returns error? {
    string workspace = "test_workspace_build";
    check file:createDir(workspace, file:RECURSIVE);

    // Test build command
    command_executor:CommandResult result = command_executor:executeBalBuild(workspace);

    test:assertTrue(result.command.includes("bal build"));

    // Cleanup
    _ = check file:remove(workspace);
}

@test:Config {groups: ["command_execute"]}
function testParseCompilationErrors() returns error? {
    string sampleOutput = string `Compiling source
	test/package:1.0.0
ERROR [types.bal:(14:6,14:28)] redeclared symbol 'action'
ERROR [types.bal:(15:6,15:30)] redeclared symbol 'objectType'
WARNING [client.bal:(19:7,19:7)] missing hash token
ERROR [utils.bal:(25:10,25:15)] undefined symbol 'invalid'`;

    command_executor:CompilationError[] errors = command_executor:parseCompilationErrors(sampleOutput);

    test:assertEquals(errors.length(), 3); // Only errors, not warnings

    // Check first error
    test:assertEquals(errors[0].fileName, "types.bal");
    test:assertEquals(errors[0].line, 14);
    test:assertEquals(errors[0].column, 6);
    test:assertEquals(errors[0].message, "redeclared symbol 'action'");
    test:assertEquals(errors[0].errorType, "ERROR");

    // Check last error
    test:assertEquals(errors[2].fileName, "utils.bal");
    test:assertEquals(errors[2].line, 25);
    test:assertEquals(errors[2].message, "undefined symbol 'invalid'");
}

@test:Config {groups: ["command_execute"]}
function testCommandResultSuccess() returns error? {
    command_executor:CommandResult successResult = {
        command: "bal build",
        success: true,
        exitCode: 0,
        stdout: "Build completed successfully",
        stderr: "",
        compilationErrors: [],
        executionTime: 5
    };

    test:assertTrue(successResult.success);
    test:assertEquals(successResult.exitCode, 0);
    test:assertEquals(successResult.compilationErrors.length(), 0);
}

@test:Config {groups: ["command_execute"]}
function testCommandResultFailure() returns error? {
    string errorOutput = "ERROR [client.bal:(10:5,10:10)] syntax error";
    command_executor:CompilationError[] errors = command_executor:parseCompilationErrors(errorOutput);

    command_executor:CommandResult failureResult = {
        command: "bal build",
        success: false,
        exitCode: 1,
        stdout: "",
        stderr: errorOutput,
        compilationErrors: errors,
        executionTime: 8
    };

    test:assertFalse(failureResult.success);
    test:assertEquals(failureResult.exitCode, 1);
    test:assertEquals(failureResult.compilationErrors.length(), 1);
}
