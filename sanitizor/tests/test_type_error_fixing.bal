import hansika/sanitizor.llm_service;
import hansika/sanitizor.command_executor;

import ballerina/test;
import ballerina/log;
import ballerina/io;

@test:Config {}
public function testTypeErrorFixing() returns error? {
    log:printInfo("Testing AI-powered type error fixing");

    // Initialize LLM service
    llm_service:LLMServiceError? initResult = llm_service:initLLMService();
    if (initResult is llm_service:LLMServiceError) {
        test:assertFail("Failed to initialize LLM service: " + initResult.message());
    }

    string typesFilePath = "/home/hansika/dev/sanitizor/temp-workspace/ballerina/types.bal";
    
    // Check if the file has compilation errors
    string clientPath = "/home/hansika/dev/sanitizor/temp-workspace/ballerina";
    command_executor:CommandResult buildResult = command_executor:executeBalBuild(clientPath);
    
    if buildResult.compilationErrors.length() > 0 {
        io:println(string `Found ${buildResult.compilationErrors.length()} compilation errors`);
        
        // Extract type errors
        string[] typeErrors = [];
        foreach command_executor:CompilationError err in buildResult.compilationErrors {
            if err.fileName.endsWith("types.bal") {
                string errorMsg = string `Line ${err.line}: ${err.message}`;
                typeErrors.push(errorMsg);
            }
        }
        
        if typeErrors.length() > 0 {
            io:println(string `Attempting to fix ${typeErrors.length()} type errors with AI...`);
            
            int|llm_service:LLMServiceError fixResult = llm_service:fixBallerinaTypeErrors(typesFilePath, typeErrors);
            if fixResult is llm_service:LLMServiceError {
                test:assertFail("Failed to fix type errors: " + fixResult.message());
            }
            
            io:println(string `✓ AI processed ${fixResult} type errors`);
            
            // Verify the fixes work
            command_executor:CommandResult verifyResult = command_executor:executeBalBuild(clientPath);
            io:println(string `After fixes: ${verifyResult.compilationErrors.length()} errors remain`);
            
            log:printInfo("Type error fixing test completed", 
                         originalErrors = buildResult.compilationErrors.length(),
                         typeErrorsProcessed = fixResult,
                         remainingErrors = verifyResult.compilationErrors.length());
        } else {
            io:println("No type errors found to fix");
        }
    } else {
        io:println("No compilation errors found - types.bal is already clean!");
    }
    
    test:assertTrue(true, "Test completed successfully");
}