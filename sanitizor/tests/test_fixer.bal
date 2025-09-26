import ballerina/test;
import ballerina/file;
import ballerina/io;
import sanitizor.fixer;

@test:Config {}
function testParseErrors() {
    string sampleStderr = "ERROR [client.bal:(18:5,18:18)] undeclared symbol 'undefinedVar'\nWARNING [types.bal:(25:1,25:10)] unused import for module 'ballerina/lang.array'\nERROR [main.bal:(10:15,10:25)] incompatible types: expected 'string', found 'int'";

    fixer:CompilationError[] errors = fixer:parseCompilationErrors(sampleStderr);
    
    test:assertEquals(errors.length(), 3);
    
    // Test first error
    test:assertEquals(errors[0].filePath, "client.bal");
    test:assertEquals(errors[0].line, 18);
    test:assertEquals(errors[0].column, 5);
    test:assertEquals(errors[0].severity, "ERROR");
    test:assertEquals(errors[0].message, "undeclared symbol 'undefinedVar'");
    
    // Test warning
    test:assertEquals(errors[1].severity, "WARNING");
    test:assertEquals(errors[1].filePath, "types.bal");
    
    // Test third error
    test:assertEquals(errors[2].filePath, "main.bal");
    test:assertEquals(errors[2].line, 10);
}

@test:Config {}
function testCreatePrompt() {
    string code = "import ballerina/io;\npublic function main() {\n    io:println(undefinedVar);\n}";
    
    fixer:CompilationError[] errors = [
        {
            filePath: "main.bal",
            line: 3,
            column: 16,
            message: "undeclared symbol 'undefinedVar'",
            severity: "ERROR"
        }
    ];
    
    string prompt = fixer:createFixPrompt(code, errors, "main.bal");
    
    test:assertTrue(prompt.includes("undeclared symbol 'undefinedVar'"));
    test:assertTrue(prompt.includes("main.bal"));
    test:assertTrue(prompt.includes("public function main()"));
}

@test:Config {}
function testFixCodeWithLLM() returns error? {
    // This test will be skipped in CI but can be run locally with actual LLM
    string testProjectPath = "/home/hansika/dev/sanitizor/temp-workspace/ballerina";
    
    // Create a simple file with error
    string problemCode = "import ballerina/io;\n\npublic function main() {\n    string message = undefinedVariable;\n    io:println(message);\n}";
    
    check io:fileWriteString(testProjectPath + "/problem.bal", problemCode);
    
    // Test would call actual fixer here - but for now just verify file creation
    boolean exists = check file:test(testProjectPath + "/problem.bal", file:EXISTS);
    test:assertTrue(exists);
}

@test:Config {}
function testGroupErrors() {
    fixer:CompilationError[] errors = [
        {filePath: "main.bal", line: 1, column: 1, message: "error1", severity: "ERROR"},
        {filePath: "client.bal", line: 2, column: 2, message: "error2", severity: "ERROR"},
        {filePath: "main.bal", line: 3, column: 3, message: "error3", severity: "WARNING"}
    ];
    
    map<fixer:CompilationError[]> grouped = fixer:groupErrorsByFile(errors);
    
    test:assertEquals(grouped.keys().length(), 2);
    test:assertTrue(grouped.hasKey("main.bal"));
    test:assertTrue(grouped.hasKey("client.bal"));
    test:assertEquals(grouped.get("main.bal").length(), 2);
    test:assertEquals(grouped.get("client.bal").length(), 1);
}