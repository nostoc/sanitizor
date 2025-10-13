import ballerina/ai;
import ballerina/file;
import ballerina/io;
//import ballerina/lang.'string as strings;
import ballerinax/ai.anthropic;
import ballerina/log;

// Module-level variable for AI model
ai:ModelProvider? anthropicModel = ();
configurable string apiKey = ?;

// Template path for templates
const string TEMPLATES_PATH = "modules/templates";

// Initialize the documentation generator with API key


public function initDocumentationGenerator() returns error? {

    ai:ModelProvider|error modelProvider = new anthropic:ModelProvider(
        apiKey,
        anthropic:CLAUDE_SONNET_4_20250514,
        maxTokens = 60000,
        timeout = 300
    );

    if modelProvider is error {
        return error ("Failed to initialize Anthropic model provider", modelProvider);
    }

    anthropicModel = modelProvider;
    
        log:printInfo("LLM service initialized successfully");
    
}

public function generateAllDocumentation(string connectorPath) returns error? {
    io:println("📋 Analyzing connector structure...");

    io:println("📝 Generating documentation...");
    check generateBallerinaReadme(connectorPath);
    check generateTestsReadme(connectorPath);
    check generateExamplesReadme(connectorPath);
    check generateMainReadme(connectorPath);

    io:println("✅ All documentation generated successfully!");
}

public function generateBallerinaReadme(string connectorPath) returns error? {
    ConnectorMetadata metadata = check analyzeConnector(connectorPath);
    map<string> aiContent = check generateBallerinaContent(metadata);

    TemplateData data = createTemplateData(metadata);
    data = mergeAIContent(data, aiContent);

    string content = check processTemplate("ballerina_readme_template.md", data);

    string outputPath = connectorPath + "/ballerina/README.md";
    if !check file:test(connectorPath + "/ballerina", file:EXISTS) {
        outputPath = connectorPath + "/README.md";
    }

    string? parentPath = check file:parentPath(outputPath);
    if parentPath is string {
        check ensureDirectoryExists(parentPath);
    }
    check writeOutput(content, outputPath);
    io:println("✅ Generated: " + outputPath);
}

public function generateTestsReadme(string connectorPath) returns error? {
    ConnectorMetadata metadata = check analyzeConnector(connectorPath);
    map<string> aiContent = check generateTestsContent(metadata);

    TemplateData data = createTemplateData(metadata);
    data = mergeAIContent(data, aiContent);

    string content = check processTemplate("tests_readme_template.md", data);

    string outputPath = connectorPath + "/tests/README.md";
    if !check file:test(connectorPath + "/tests", file:EXISTS) {
        outputPath = connectorPath + "/ballerina/tests/README.md";
    }

    string? parentPath = check file:parentPath(outputPath);
    if parentPath is string {
        check ensureDirectoryExists(parentPath);
    }
    check writeOutput(content, outputPath);
    io:println("✅ Generated: " + outputPath);
}

public function generateExamplesReadme(string connectorPath) returns error? {
    ConnectorMetadata metadata = check analyzeConnector(connectorPath);
    map<string> aiContent = check generateExamplesContent(metadata);

    TemplateData data = createTemplateData(metadata);
    data = mergeAIContent(data, aiContent);

    string content = check processTemplate("examples_readme_template.md", data);

    string outputPath = connectorPath + "/examples/README.md";

    string? parentPath = check file:parentPath(outputPath);
    if parentPath is string {
        check ensureDirectoryExists(parentPath);
    }
    check writeOutput(content, outputPath);
    io:println("✅ Generated: " + outputPath);
}

public function generateMainReadme(string connectorPath) returns error? {
    ConnectorMetadata metadata = check analyzeConnector(connectorPath);
    map<string> aiContent = check generateMainContent(metadata);

    TemplateData data = createTemplateData(metadata);
    data = mergeAIContent(data, aiContent);

    string content = check processTemplate("main_readme_template.md", data);

    string outputPath = connectorPath + "/README.md";

    string? parentPath = check file:parentPath(outputPath);
    if parentPath is string {
        check ensureDirectoryExists(parentPath);
    }
    check writeOutput(content, outputPath);
    io:println("✅ Generated: " + outputPath);
}

function generateBallerinaContent(ConnectorMetadata metadata) returns map<string>|error {
    map<string> content = {};

    io:println("  🤖 Generating overview...");
    content["overview"] = check callAI(createBallerinaOverviewPrompt(metadata));

    io:println("  🤖 Generating setup guide...");
    content["setup"] = check callAI(createBallerinaSetupPrompt(metadata));

    io:println("  🤖 Generating quickstart...");
    content["quickstart"] = check callAI(createBallerinaQuickstartPrompt(metadata));

    io:println("  🤖 Generating examples section...");
    content["examples"] = check callAI(createBallerinaExamplesPrompt(metadata));

    return content;
}

function generateTestsContent(ConnectorMetadata metadata) returns map<string>|error {
    map<string> content = {};

    io:println("  🤖 Generating testing approach...");
    content["testing_approach"] = check callAI(createTestingApproachPrompt(metadata));

    io:println("  🤖 Generating test scenarios...");
    content["test_scenarios"] = check callAI(createTestScenariosPrompt(metadata));

    return content;
}

function generateExamplesContent(ConnectorMetadata metadata) returns map<string>|error {
    map<string> content = {};

    io:println("  🤖 Generating example descriptions...");
    content["example_descriptions"] = check callAI(createExampleDescriptionsPrompt(metadata));

    io:println("  🤖 Generating getting started guide...");
    content["getting_started"] = check callAI(createGettingStartedPrompt(metadata));

    return content;
}

function generateMainContent(ConnectorMetadata metadata) returns map<string>|error {
    map<string> content = {};

    io:println("  🤖 Generating main overview...");
    content["overview"] = check callAI(createMainOverviewPrompt(metadata));

    io:println("  🤖 Generating usage section...");
    content["usage"] = check callAI(createMainUsagePrompt(metadata));

    return content;
}

function callAI(string prompt) returns string|error {
    ai:ModelProvider? model = anthropicModel;

    if model is () {
        return error("AI model not initialized. Please call initDocumentationGenerator() first.");
    }
    io:println("    Prompt: " + prompt);
    ai:ChatMessage[] messages = [{role: "user", content: prompt}];
    ai:ChatAssistantMessage|error response = model->chat(messages);
    if response is error {
        io:println(response);
        return error("AI generation failed: " + response.message());
    }
    string? content = response.content;
    if content is string {
        return content;
    } else {
        return error("AI response content is empty.");
    }

}

function ensureDirectoryExists(string dirPath) returns error? {
    if !check file:test(dirPath, file:EXISTS) {
        check file:createDir(dirPath, file:RECURSIVE);
    }
}

// Prompt generation functions for Ballerina README
function createBallerinaOverviewPrompt(ConnectorMetadata metadata) returns string {
    string backtick = "`";
    return string `
You are a professional technical writer creating the "Overview" section for a Ballerina connector's README.md file. Your task is to generate a concise, two-paragraph overview that is perfectly structured and contains accurate, verified hyperlinks.

**Your Goal:** Generate an overview that precisely matches the style, tone, and format of the example below.
--- 
**PERFECT OUTPUT EXAMPLE (for Smartsheet):**

## Overview

[Smartsheet](https://www.smartsheet.com/) is a cloud-based platform that enables teams to plan, capture, manage, automate, and report on work at scale, empowering you to move from idea to impact, fast.

The ${backtick}ballerinax/smartsheet${backtick} package offers APIs to connect and interact with [Smartsheet API](https://developers.smartsheet.com/api/smartsheet/introduction) endpoints, specifically based on [Smartsheet API v2.0](https://developers.smartsheet.com/api/smartsheet/openapi).
---


**TASK INSTRUCTIONS:**

Now, generate a new overview for the following connector. Follow these rules meticulously:

1.  **Research:** You MUST perform a web search to find the official homepage and the developer API documentation for the service.
2.  **Paragraph 1 (The Service):**
    * Write a single, compelling sentence describing what the service is and its primary value.
    * The very first mention of the service name MUST be a Markdown link to its official homepage.
3.  **Paragraph 2 (The Connector):**
    * The paragraph must start with "The ${backtick}ballerinax/[connector_lowercase_name]${backtick} package offers APIs to connect and interact with...".
    * It must include a Markdown link for the phrase "[Service Name] API" that points to the main developer portal or API documentation page you found.
    * **Crucially:** End the sentence by specifying the API version. Search for the specific API version number (e.g., v3, v2.0, 2024-04). If you can find a link to that specific version's documentation (like an OpenAPI spec), link to it.
    * **Fallback:** If you cannot find a specific, stable version number, you may state that it is based on "a recent version of the API" and use the general API documentation link again. Do not invent a version number.


Connector Information:
${getConnectorSummary(metadata)}
`;
}

function createBallerinaSetupPrompt(ConnectorMetadata metadata) returns string {
    return string `
You are writing the Setup Guide section for a Ballerina connector's README.md file.

Connector Information:
${getConnectorSummary(metadata)}

Create a setup guide that includes:
1. Prerequisites (Ballerina version, dependencies)
2. Installation steps using Ballerina Central
3. Configuration requirements (API keys, endpoints, etc.)
4. Authentication setup if applicable
5. Basic project structure recommendations

Use proper Ballerina syntax and follow Ballerina conventions.
Format as markdown with code blocks for configuration examples.
`;
}

function createBallerinaQuickstartPrompt(ConnectorMetadata metadata) returns string {
    return string `
You are writing the Quick Start section for a Ballerina connector's README.md file.

Connector Information:
${getConnectorSummary(metadata)}

Create a quick start guide that shows:
1. A simple, working code example
2. How to import and initialize the connector
3. One or two basic operations using the available methods
4. Expected output or response

Available client methods: ${metadata.clientMethods.toString()}

Use realistic but simple examples. Code should be copy-pastable and functional.
Format as markdown with proper code blocks and syntax highlighting.
`;
}

function createBallerinaExamplesPrompt(ConnectorMetadata metadata) returns string {
    return string `
You are writing the Examples section for a Ballerina connector's README.md file.

Connector Information:
${getConnectorSummary(metadata)}

Available Examples: ${metadata.examples.toString()}

Create an examples section that:
1. Lists and describes each available example
2. Explains what each example demonstrates
3. Provides links to the example files
4. Suggests which examples to try first

Keep descriptions brief but informative. Focus on the learning value of each example.
Format as markdown with appropriate headers and links.
`;
}

function createTestingApproachPrompt(ConnectorMetadata metadata) returns string {
    return string `
You are writing the Testing Approach section for a Ballerina connector's tests README.md file.

Connector Information:
${getConnectorSummary(metadata)}

Explain the testing strategy including:
1. Types of tests implemented (unit, integration, etc.)
2. Mock service usage and approach
3. Test data management
4. How to run the tests
5. What the tests validate

Be specific about Ballerina testing conventions and tools used.
Format as markdown with code examples where helpful.
`;
}

function createTestScenariosPrompt(ConnectorMetadata metadata) returns string {
    return string `
You are writing the Test Scenarios section for a Ballerina connector's tests README.md file.

Connector Information:
${getConnectorSummary(metadata)}

Available client methods: ${metadata.clientMethods.toString()}

List and describe the test scenarios that cover:
1. Happy path scenarios for each main operation
2. Error handling and edge cases
3. Authentication and authorization tests
4. Data validation tests
5. Performance and reliability tests

Organize by functionality and explain what each scenario validates.
Format as markdown with clear categorization.
`;
}

function createExampleDescriptionsPrompt(ConnectorMetadata metadata) returns string {
    return string `
You are writing detailed descriptions for examples in a Ballerina connector's examples README.md file.

Connector Information:
${getConnectorSummary(metadata)}

Available Examples: ${metadata.examples.toString()}

For each example, provide:
1. A clear title and one-line description
2. What problem it solves or demonstrates
3. Key concepts or features it showcases
4. Prerequisites or setup required
5. Expected outcomes

Make it easy for developers to choose the right example for their needs.
Format as markdown with consistent structure for each example.
`;
}

function createGettingStartedPrompt(ConnectorMetadata metadata) returns string {
    return string `
You are writing a Getting Started section for a Ballerina connector's examples README.md file.

Connector Information:
${getConnectorSummary(metadata)}

Create guidance that includes:
1. Which example to start with first
2. How to run the examples
3. Common configuration steps
4. Troubleshooting tips for beginners
5. Next steps after trying the examples

Focus on helping new users succeed quickly with their first example.
Format as markdown with step-by-step instructions.
`;
}

function createMainOverviewPrompt(ConnectorMetadata metadata) returns string {
    return string `
You are writing the main overview for a Ballerina connector's root README.md file.

Connector Information:
${getConnectorSummary(metadata)}

Create a compelling overview that:
1. Introduces the connector and its purpose
2. Highlights key benefits and features
3. Shows who should use this connector
4. Provides a high-level architecture overview
5. Links to detailed documentation sections

This is the first thing users see, so make it engaging and informative.
Format as markdown with good visual hierarchy.
`;
}

function createMainUsagePrompt(ConnectorMetadata metadata) returns string {
    return string `
You are writing the Usage section for a Ballerina connector's root README.md file.

Connector Information:
${getConnectorSummary(metadata)}

Create a usage section that covers:
1. Installation and setup summary
2. Basic usage patterns
3. Key configuration options
4. Common use cases with brief examples
5. Links to detailed guides and examples

Keep code examples minimal but representative of typical usage.
Format as markdown with clear sections and code blocks.
`;
}

// Template processing functions
function processTemplate(string templateName, TemplateData data) returns string|error {
    string templatePath = TEMPLATES_PATH + "/" + templateName;

    if !check file:test(templatePath, file:EXISTS) {
        return error("Template not found: " + templatePath);
    }

    string template = check io:fileReadString(templatePath);
    return substituteVariables(template, data);
}

function substituteVariables(string template, TemplateData data) returns string {
    string result = template;

    // Simple string replacement function
    string connectorName = data.CONNECTOR_NAME ?: "";
    if connectorName != "" {
        result = simpleReplace(result, "{{CONNECTOR_NAME}}", connectorName);
    }

    string version = data.VERSION ?: "";
    if version != "" {
        result = simpleReplace(result, "{{VERSION}}", version);
    }

    string description = data.DESCRIPTION ?: "";
    if description != "" {
        result = simpleReplace(result, "{{DESCRIPTION}}", description);
    }

    string overview = data.AI_GENERATED_OVERVIEW ?: "";
    if overview != "" {
        result = simpleReplace(result, "{{AI_GENERATED_OVERVIEW}}", overview);
    }

    string setup = data.AI_GENERATED_SETUP ?: "";
    if setup != "" {
        result = simpleReplace(result, "{{AI_GENERATED_SETUP}}", setup);
    }

    string quickstart = data.AI_GENERATED_QUICKSTART ?: "";
    if quickstart != "" {
        result = simpleReplace(result, "{{AI_GENERATED_QUICKSTART}}", quickstart);
    }

    string examples = data.AI_GENERATED_EXAMPLES ?: "";
    if examples != "" {
        result = simpleReplace(result, "{{AI_GENERATED_EXAMPLES}}", examples);
    }

    string usage = data.AI_GENERATED_USAGE ?: "";
    if usage != "" {
        result = simpleReplace(result, "{{AI_GENERATED_USAGE}}", usage);
    }

    string testingApproach = data.AI_GENERATED_TESTING_APPROACH ?: "";
    if testingApproach != "" {
        result = simpleReplace(result, "{{AI_GENERATED_TESTING_APPROACH}}", testingApproach);
    }

    string testScenarios = data.AI_GENERATED_TEST_SCENARIOS ?: "";
    if testScenarios != "" {
        result = simpleReplace(result, "{{AI_GENERATED_TEST_SCENARIOS}}", testScenarios);
    }

    string exampleDescriptions = data.AI_GENERATED_EXAMPLE_DESCRIPTIONS ?: "";
    if exampleDescriptions != "" {
        result = simpleReplace(result, "{{AI_GENERATED_EXAMPLE_DESCRIPTIONS}}", exampleDescriptions);
    }

    string gettingStarted = data.AI_GENERATED_GETTING_STARTED ?: "";
    if gettingStarted != "" {
        result = simpleReplace(result, "{{AI_GENERATED_GETTING_STARTED}}", gettingStarted);
    }

    return result;
}

function simpleReplace(string text, string searchFor, string replaceWith) returns string {
    string result = text;
    int? index = result.indexOf(searchFor);
    while index is int {
        string before = result.substring(0, index);
        string after = result.substring(index + searchFor.length());
        result = before + replaceWith + after;
        index = result.indexOf(searchFor);
    }
    return result;
}

function writeOutput(string content, string outputPath) returns error? {
    check io:fileWriteString(outputPath, content);
}

function createTemplateData(ConnectorMetadata metadata) returns TemplateData {
    return {
        CONNECTOR_NAME: metadata.connectorName,
        VERSION: metadata.version,
        DESCRIPTION: metadata.description
    };
}

function mergeAIContent(TemplateData baseData, map<string> aiContent) returns TemplateData {
    TemplateData merged = baseData.clone();

    foreach var [key, value] in aiContent.entries() {
        match key {
            "overview" => {
                merged.AI_GENERATED_OVERVIEW = value;
            }
            "setup" => {
                merged.AI_GENERATED_SETUP = value;
            }
            "quickstart" => {
                merged.AI_GENERATED_QUICKSTART = value;
            }
            "examples" => {
                merged.AI_GENERATED_EXAMPLES = value;
            }
            "usage" => {
                merged.AI_GENERATED_USAGE = value;
            }
            "testing_approach" => {
                merged.AI_GENERATED_TESTING_APPROACH = value;
            }
            "test_scenarios" => {
                merged.AI_GENERATED_TEST_SCENARIOS = value;
            }
            "example_descriptions" => {
                merged.AI_GENERATED_EXAMPLE_DESCRIPTIONS = value;
            }
            "getting_started" => {
                merged.AI_GENERATED_GETTING_STARTED = value;
            }
        }
    }

    return merged;
}
