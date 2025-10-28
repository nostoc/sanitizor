import ballerina/ai;
import ballerina/io;
import ballerina/log;
import ballerinax/ai.anthropic;

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

    // 
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
    io:println(prompt);
    ai:ChatAssistantMessage|error response = modelProvider->chat(messages);
    //messages.push({role: "assistant", content: response is ai:ChatAssistantMessage ? response.content : ""});
    //io:println(messages);
    if response is error {
        return error("AI generation failed: " + response.message());
    }
    string? content = response.content;
    if content is string {
        io:println(content);
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
    return callAI(prompt);
}
