import example_generator.ai_generator;
import example_generator.analyzer;

import ballerina/io;
import ballerina/log;

public function main(string... args) returns error? {
    if args.length() < 1 {
        io:println("Please provide the path to the connector module.");
        return;
    }

    string connectorPath = args[0];
    // 1. analyze the connector
    analyzer:ConnectorDetails|error details = analyzer:analyzeConnector(connectorPath);
    if details is error {
        io:println("Failed to analyze connector: ", details.message());
        return;
    }

    // Initialize ai ai_generator
    error? initResult = ai_generator:initExampleGenerator();
    if initResult is error {

        io:println("Error initializing AI generator: " + initResult.message());

        return error("AI generator initialization failed: " + initResult.message());
    }

    // 2. Determine the number of examples

    int numberOfExamples = analyzer:numberOfExamples(details.apiCount);
    io:println("Number of Examples to generate: ", numberOfExamples.toString());

    // 3. Loop to generate each example
    foreach int i in 1 ... numberOfExamples {
        io:println("Generating use case ", i.toString(), "...");
                io:println("Generating example name for use case ", i.toString(), "...");

        json|error useCaseResponse = ai_generator:generateUseCaseAndFunctions(details);
        if useCaseResponse is error {
            log:printError("Failed to generate use case", useCaseResponse);
            continue;
        }

        string useCase = check useCaseResponse.useCase.ensureType();
        json functionNamesJson = check useCaseResponse.requiredFunctions.ensureType();
        string[] functionNames = [];
        
        // Convert json array to string array
        if functionNamesJson is json[] {
            foreach json item in functionNamesJson {
                if item is string {
                    functionNames.push(item);
                }
            }
        } else {
            log:printError("requiredFunctions is not a JSON array");
            continue;
        }
        io:println("Generated use case: " + useCase);
        io:println("Required functions: " + functionNames.toString());


        // Step 2: Extract the targeted context based on the required functions
        string|error targetedContext = analyzer:extractTargetedContext(details, functionNames);
        io:Error? writeText = io:fileWriteString("extracted.bal",check targetedContext);
        if targetedContext is error {
            log:printError("Failed to extract targeted context", targetedContext);
            continue;
        }
        
        // io:println("\n", "=========TARGETED CONTEXT==========",targetedContext);
        // string|error generatedCode = ai_generator:generateExampleCode(details, useCase, targetedContext);
        // if generatedCode is error {
        //     log:printError("Failed to generate example code", generatedCode);
        //     continue;
        // }
        // // Generate AI-powered example name
        // string|error exampleNameResult = ai_generator:generateExampleName(useCase);
        // string exampleName;
        // if exampleNameResult is error {
        //     log:printError("Failed to generate example name, using fallback", exampleNameResult);
        //     exampleName = "example_" + i.toString();
        // } else {
        //     exampleName = exampleNameResult;
        // }
        
        // io:println("Generated example name: ", exampleName);
        // io:println("Generating example code for use case ", i.toString(), "...");
        // io:println("Generated Example Code for Use Case ", i.toString(), ":\n", generatedCode);

        // // Write the generated example to file
        // io:println("Writing example ", i.toString(), " to file...");
        // error? writeResult = analyzer:writeExampleToFile(connectorPath, exampleName, useCase, generatedCode);
        // if writeResult is error {
        //     io:println("Failed to write example to file: ", writeResult.message());
        //     continue;
        // }
        // io:println("Successfully wrote example ", i.toString(), " to file system.");



        // // Fix compilation errors in the generated example
        //  string exampleDir = connectorPath + "/examples/" + exampleName;
        // error? fixResult = analyzer:fixExampleCode(exampleDir, exampleName);
        // if fixResult is error {
        //     io:println("Warning: Failed to fix compilation errors for example ", i.toString(), ": ", fixResult.message());
        //     io:println("Example may require manual intervention.");
        //     // Continue with other examples even if one fails to fix
        // }
        
        // io:println(string `✓ Example ${i} (${exampleName}) completed successfully!`);
    }

    // io:println("Example generation completed successfully!");
}
