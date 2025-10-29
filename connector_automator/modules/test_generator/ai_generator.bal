import ballerina/ai;
import ballerina/io;
import ballerina/log;
import ballerinax/ai.anthropic;
import connector_automator.code_fixer;
import ballerina/file;

ai:ModelProvider? anthropicModel = ();
configurable string apiKey = ?;

function completeMockServer(string mockServerPath, string typesPath) returns error? {
    // Read the generated mock server template
    string mockServerContent = check io:fileReadString(mockServerPath);
    string typesContent = check io:fileReadString(typesPath);

    // generate completed mock server using LLM
    string prompt = createMockServerPrompt(mockServerContent, typesContent);
    string completeMockServer = check callAI(prompt);

    check io:fileWriteString(mockServerPath, completeMockServer);
}

function callAI(string prompt) returns string|error {

    ai:ModelProvider|error modelProvider = new anthropic:ModelProvider(
        apiKey,
        anthropic:CLAUDE_SONNET_4_20250514,
        maxTokens = 64000,
        timeout = 300
    );
    if modelProvider is error {
        return error("Failed to initialize model provider");
    }
    anthropicModel = modelProvider;
    log:printInfo("LLM service initialized successfully");

    ai:ChatMessage[] messages = [{role: "user", content: prompt}];
    //io:println(prompt);
    ai:ChatAssistantMessage|error response = modelProvider->chat(messages);
    //messages.push({role: "assistant", content: response is ai:ChatAssistantMessage ? response.content : ""});
    //io:println(messages);
    io:println(response);
    if response is error {
        return error("AI generation failed: " + response.message());
        
    }
    
    string? content = response.content;
    if content is string {
        //io:println(content);
        return content;
    } else {
        return error("AI response content is empty.");
    }
}

function generateTestFile(string connectorPath) returns error? {
    // Simplified analysis - only get package name and mock server content
    ConnectorAnalysis analysis = check analyzeConnectorForTests(connectorPath);

    // Generate test content using AI
    string testContent = check generateTestsWithAI(analysis);

    // Write test file
    string testFilePath = connectorPath + "/ballerina/tests/test.bal";
    check io:fileWriteString(testFilePath, testContent);

    io:println("✓ Test file generated successfully");
    return;
}

function generateTestsWithAI(ConnectorAnalysis analysis) returns string|error {
    string prompt = createTestGenerationPrompt(analysis);
    // io:println(analysis.initMethodSignature);
    // io:println(analysis.referencedTypeDefinitions);
    return callAI(prompt);
}

function fixTestFileErrors(string connectorPath) returns error? {
    io:println("Checking and fixing compilation errors in the entire project...");

    string ballerinaDir = connectorPath + "/ballerina";

    // Use the fixer to fix all compilation errors related to tests, (There won't be any errors in other files, because if the client is not compiled succsesfully we won't come this far in the workflow)
    code_fixer:FixResult|code_fixer:BallerinaFixerError fixResult = code_fixer:fixAllErrors(ballerinaDir, autoYes = true, quietMode = true);

    if fixResult is code_fixer:FixResult {
        if fixResult.success {
            io:println("✓ All files compile successfully!");
            if fixResult.errorsFixed > 0 {
                io:println(string `  Fixed ${fixResult.errorsFixed} compilation errors`);
                if fixResult.appliedFixes.length() > 0 {
                    io:println("  Applied fixes:");
                    foreach string fix in fixResult.appliedFixes {
                        io:println(string `    • ${fix}`);
                    }
                }
            }
        } else {
            io:println("⚠ Project partially fixed:");
            io:println(string `  Fixed ${fixResult.errorsFixed} errors`);
            io:println(string `  ${fixResult.errorsRemaining} errors remain`);
            if fixResult.appliedFixes.length() > 0 {
                io:println("  Applied fixes:");
                foreach string fix in fixResult.appliedFixes {
                    io:println(string `    • ${fix}`);
                }
            }
            io:println("  Some errors may require manual intervention");
        }
    } else {
        io:println(string `✗ Failed to fix project: ${fixResult.message()}`);
        return error("Failed to fix compilation errors in the project", fixResult);
    }

    return;
}

function createTestConfig(string connectorPath) returns error? {
    string testsDir = connectorPath + "/ballerina/tests";
    
    // Create tests directory if it doesn't exist
    if !(check file:test(testsDir, file:EXISTS)) {
        check file:createDir(testsDir, file:RECURSIVE);
        io:println("Created tests directory");
    }
    
    // Create Config.toml content
    string configContent = string `# Test configuration
# Set to false to use mock server (default for testing)
# Set to true to test against live API (requires valid credentials)
isLiveServer = false`;
    
    string configFilePath = testsDir + "/Config.toml";
    check io:fileWriteString(configFilePath, configContent);
    
    io:println("✓ Test Config.toml created successfully");
    return;
}