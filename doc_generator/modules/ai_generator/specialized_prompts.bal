import doc_generator.doc_analyzer;

// Specialized prompts for different README types
public function createMainReadmePrompt(doc_analyzer:ConnectorAnalysis analysis) returns string {
    string operationsSummary = buildOperationsSummary(analysis.operations);
    string examplesSummary = buildExamplesSummary(analysis.examples);
    string keywordsContext = string:'join(", ", ...analysis.keywords);
    
    return string `You are an expert technical writer creating the MAIN README.md for a Ballerina connector repository on GitHub. This is the primary documentation file that users will see first.

CONNECTOR DETAILS:
- Name: ${analysis.connectorName}
- Version: ${analysis.version}
- Description: ${analysis.description}
- Operations: ${analysis.operations.length()}
- Examples: ${analysis.examples.length()}
- Keywords: ${keywordsContext}

OPERATIONS AVAILABLE:
${operationsSummary}

EXAMPLES AVAILABLE:
${examplesSummary}

Create a comprehensive MAIN README following the official Ballerina connector format. The README should include:

1. **Title with badges**: Use the connector name and include standard GitHub action badges
2. **Overview**: 2-3 sentences explaining what the service does and the connector's value
3. **Setup Guide**: Detailed step-by-step instructions for:
   - Creating an account with the service
   - Generating API credentials/tokens
   - Account requirements or plan limitations
4. **Quickstart**: Complete working example with:
   - Module import
   - Config.toml setup
   - Client initialization
   - Sample operation usage
   - How to run the application
5. **Examples**: Description of available examples with links
6. **Build from source**: Standard Ballerina build instructions
7. **Contributing**: Standard Ballerina contribution guidelines
8. **Useful links**: Links to package documentation, examples, community

FORMAT REQUIREMENTS:
- Use proper markdown with code blocks
- Include badges for CI/CD status
- Provide complete, runnable code examples
- Use the exact connector name "${analysis.connectorName}" throughout
- Make it professional and comprehensive like official Ballerina connectors

Return ONLY the complete README content, no explanations or metadata.`;
}

public function createBallerinaModulePrompt(doc_analyzer:ConnectorAnalysis analysis) returns string {
    string operationsSummary = buildOperationsSummary(analysis.operations);
    string keywordsContext = string:'join(", ", ...analysis.keywords);
    
    return string `Create the ballerina/README.md file for the ${analysis.connectorName} connector module. This is the module-specific documentation.

CONNECTOR DETAILS:
- Name: ${analysis.connectorName}
- Version: ${analysis.version}
- Operations: ${analysis.operations.length()}
- Keywords: ${keywordsContext}

OPERATIONS SUMMARY:
${operationsSummary}

The module README should be concise and focused on:

1. **Overview**: Brief description of the module's purpose
2. **Module Overview**: What developers can do with this module (list key capabilities)
3. **Setup Guide**: Essential setup steps (more concise than main README)
4. **Usage**: Quick usage example with basic client initialization and one operation
5. **Examples**: Reference to examples with brief description
6. **Compatibility**: Supported Ballerina versions and API version

Keep it concise but informative. This is for developers who have already decided to use the connector.

Return ONLY the README content, no explanations.`;
}

public function createExamplesReadmePrompt(doc_analyzer:ConnectorAnalysis analysis) returns string {
    string examplesList = "";
    int index = 1;
    foreach doc_analyzer:ExampleProject example in analysis.examples {
        examplesList += string `${index}. ${example.name} - ${example.description}\n`;
        index += 1;
    }
    
    return string `Create the examples/README.md file for the ${analysis.connectorName} connector examples directory.

CONNECTOR: ${analysis.connectorName}
EXAMPLES FOUND:
${examplesList}

The examples README should include:

1. **Title**: Clear title indicating these are examples for the connector
2. **Introduction**: Brief explanation of what the examples demonstrate
3. **Available Examples**: List all examples with descriptions and links to their directories
4. **Prerequisites**: What users need to run the examples (credentials, setup)
5. **Running Examples**: Clear instructions on how to run an example
6. **Building Examples**: Instructions for building examples from source

Make it practical and user-friendly. Focus on helping developers quickly understand and run the examples.

Return ONLY the README content, no explanations.`;
}

public function createTestsReadmePrompt(doc_analyzer:ConnectorAnalysis analysis) returns string {
    return string `Create the ballerina/tests/README.md file for the ${analysis.connectorName} connector test suite.

CONNECTOR: ${analysis.connectorName}
OPERATIONS COUNT: ${analysis.operations.length()}

The tests README should cover:

1. **Title**: "Running Tests" for the connector
2. **Prerequisites**: What's needed to run tests (credentials, setup)
3. **Test Configuration**: How to set up Config.toml for tests
4. **Running Tests**: Command to execute tests (bal test)
5. **Test Coverage**: What the tests cover (operations, auth, error handling, etc.)
6. **Test Data**: Explain that tests use mock data to avoid production impact

Keep it technical but clear. This is for developers who want to run or contribute to tests.

Return ONLY the README content, no explanations.`;
}

// Helper functions (reuse from ai_generator.bal)
function buildOperationsSummary(doc_analyzer:Operation[] operations) returns string {
    if operations.length() == 0 {
        return "No operations detected.";
    }
    
    // Group operations by HTTP method
    string[] getOps = [];
    string[] postOps = [];
    string[] putOps = [];
    string[] deleteOps = [];
    
    foreach doc_analyzer:Operation op in operations {
        string opSummary = string `${op.name} - ${op.description}`;
        match op.httpMethod {
            "GET" => getOps.push(opSummary);
            "POST" => postOps.push(opSummary);
            "PUT" => putOps.push(opSummary);
            "DELETE" => deleteOps.push(opSummary);
        }
    }
    
    string[] summary = [];
    if getOps.length() > 0 {
        summary.push(string `GET Operations (${getOps.length()}): ${string:'join(", ", ...getOps.slice(0, 5))}${getOps.length() > 5 ? "..." : ""}`);
    }
    if postOps.length() > 0 {
        summary.push(string `POST Operations (${postOps.length()}): ${string:'join(", ", ...postOps.slice(0, 5))}${postOps.length() > 5 ? "..." : ""}`);
    }
    if putOps.length() > 0 {
        summary.push(string `PUT Operations (${putOps.length()}): ${string:'join(", ", ...putOps.slice(0, 3))}${putOps.length() > 3 ? "..." : ""}`);
    }
    if deleteOps.length() > 0 {
        summary.push(string `DELETE Operations (${deleteOps.length()}): ${string:'join(", ", ...deleteOps.slice(0, 3))}${deleteOps.length() > 3 ? "..." : ""}`);
    }
    
    return string:'join("\n", ...summary);
}

function buildExamplesSummary(doc_analyzer:ExampleProject[] examples) returns string {
    if examples.length() == 0 {
        return "No examples available.";
    }
    
    string[] summary = [];
    foreach doc_analyzer:ExampleProject example in examples {
        summary.push(string `- ${example.name}: ${example.description} (Config: ${example.hasConfiguration ? "Yes" : "No"})`);
    }
    
    return string:'join("\n", ...summary);
}