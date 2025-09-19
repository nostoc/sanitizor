import sanitizor.ballerina_fixer;
import sanitizor.command_executor;
import sanitizor.llm_service;

import ballerina/test;
import ballerina/io;
import ballerina/log;

@test:Config {}
function testAIBallerinaFixer() returns error? {
    // Initialize LLM service
    llm_service:LLMServiceError? initResult = llm_service:initLLMService();
    if initResult is llm_service:LLMServiceError {
        test:assertFail("Failed to initialize LLM service: " + initResult.message());
    }
    
    string testProjectPath = "/home/hansika/dev/sanitizor/temp-workspace/ballerina";
    
    // Check if there are compilation errors
    command_executor:CommandResult buildResult = command_executor:executeBalBuild(testProjectPath);
    
    if buildResult.compilationErrors.length() > 0 {
        log:printInfo("Found compilation errors, testing AI fixer", errorCount = buildResult.compilationErrors.length());
        
        ballerina_fixer:BallerinaFixResult result = check ballerina_fixer:fixAllBallerinaErrorsIteratively(testProjectPath);
        
        io:println(string `Fix result: Success=${result.success}, Fixed=${result.errorsFixed}, Remaining=${result.errorsRemaining}`);
        
        test:assertTrue(result.errorsFixed > 0, "Should fix at least some errors");
        
        // Verify that errors were actually reduced
        command_executor:CommandResult verifyResult = command_executor:executeBalBuild(testProjectPath);
        test:assertTrue(verifyResult.compilationErrors.length() <= buildResult.compilationErrors.length(), 
                       "Should not increase error count");
    } else {
        io:println("No compilation errors found - skipping AI fixer test");
    }
}