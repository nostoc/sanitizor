import example_generator.ai_generator;
import example_generator.analyzer;

import ballerina/io;

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
        string|error useCase = ai_generator:generateuseCase(details);
        if useCase is error {
            io:println("Failed to generate use case: ", useCase.message());
            continue;
        }
        io:println("Use Case ", i.toString(), ": ", useCase);

        io:println("Generating example name for use case ", i.toString(), "...");
        string|error exampleName = ai_generator:generateExampleName(useCase);
        if exampleName is error {
            io:println("Failed to generate example name: ", exampleName.message());
            continue;
        }
        io:println("Example Name ", i.toString(), ": ", exampleName);

        io:println("Generating example code for use case ", i.toString(), "...");
        string|error exampleCode = ai_generator:generateExampleCode(details, useCase);
        if exampleCode is error {
            io:println("Failed to generate example code: ", exampleCode.message());
            continue;
        }
        io:println("Generated Example Code for Use Case ", i.toString(), ":\n", exampleCode);

        // Write the generated example to file
        io:println("Writing example ", i.toString(), " to file...");
        error? writeResult = analyzer:writeExampleToFile(connectorPath, exampleName, useCase, exampleCode);
        if writeResult is error {
            io:println("Failed to write example to file: ", writeResult.message());
            continue;
        }
        io:println("Successfully wrote example ", i.toString(), " to file system.");

        // Fix compilation errors in the generated example
         string exampleDir = connectorPath + "/examples/" + exampleName;
        error? fixResult = analyzer:fixExampleCode(exampleDir, exampleName);
        if fixResult is error {
            io:println("Warning: Failed to fix compilation errors for example ", i.toString(), ": ", fixResult.message());
            io:println("Example may require manual intervention.");
            // Continue with other examples even if one fails to fix
        }
        
        io:println(string `✓ Example ${i} (${exampleName}) completed successfully!`);
    }

    io:println("Example generation completed successfully!");
}
