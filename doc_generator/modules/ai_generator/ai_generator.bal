import ballerina/ai;
import ballerina/file;
import ballerina/io;
import ballerina/log;
//import ballerina/lang.'string as strings;
import ballerinax/ai.anthropic;

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
        return error("Failed to initialize Anthropic model provider", modelProvider);
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
    content["testing_approach"] = check callAI(createTestReadmePrompt(metadata));
    io:println(content);
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
    string backtick = "`";
    string tripleBacktick = "```";
    return string `
You are a senior Ballerina developer and technical writer creating the "Quickstart" section for a Ballerina connector's README.md file.

Your goal is to generate a guide that is **structurally identical** to the perfect example provided below.

---
**PERFECT OUTPUT EXAMPLE (for Smartsheet):**

## Quickstart

To use the ${backtick}Smartsheet${backtick} connector in your Ballerina application, update the ${backtick}.bal${backtick} file as follows:

### Step 1: Import the module

Import the ${backtick}smartsheet${backtick} module.

${tripleBacktick}ballerina
import ballerinax/smartsheet;
${tripleBacktick}

### Step 2: Instantiate a new connector

1. Create a ${backtick}Config.toml${backtick} file and configure the obtained access token as follows:

${tripleBacktick}toml
token = "<Your_Smartsheet_Access_Token>"
${tripleBacktick}

2. Create a ${backtick}smartsheet:ConnectionConfig${backtick} with the obtained access token and initialize the connector with it.

${tripleBacktick}ballerina
configurable string token = ?;

final smartsheet:Client smartsheet = check new({
    auth: {
        token
    }
});
${tripleBacktick}

### Step 3: Invoke the connector operation

Now, utilize the available connector operations.

#### Create a new sheet

${tripleBacktick}ballerina
public function main() returns error? {
    smartsheet:SheetsBody newSheet = {
        name: "New Project Sheet",
        columns: [
            {
                title: "Task Name",
                type: "TEXT_NUMBER",
                primary: true
            },
            {
                title: "Status",
                type: "PICKLIST",
                options: ["Not Started", "In Progress", "Complete"]
            },
            {
                title: "Due Date",
                type: "DATE"
            }
        ]
    };

    smartsheet:WebhookResponse response = check smartsheet->/sheets.post(newSheet);
}
${tripleBacktick}

### Step 4: Run the Ballerina application

${tripleBacktick}bash
bal run
${tripleBacktick}

---

**TASK INSTRUCTIONS:**

Now, generate a new Quickstart section for the connector specified below. Adhere to these rules strictly:

1.  **Follow the Exact Structure:** Use the ${backtick}## Quickstart${backtick} title, the introductory sentence, and the ${backtick}### Step 1${backtick}, ${backtick}### Step 2${backtick}, ${backtick}### Step 3${backtick}, and ${backtick}### Step 4${backtick} markdown headers precisely as shown in the example.

2.  **Step 1 (Import):** Use the format ${backtick}import ballerinax/[connector_lowercase_name];${backtick}.

3.  **Step 2 (Instantiate):**
    * Show the ${backtick}Config.toml${backtick} file for configuring an access token. Use the placeholder ${backtick}<Your_[ConnectorDisplayName]_Access_Token>${backtick}.
    * Show the Ballerina code for initializing the client using ${backtick}configurable string token = ?;${backtick} and ${backtick}final [connector_lowercase_name]:Client ...${backtick}.

4.  **Step 3 (Invoke):**
    * **Choose ONE simple, representative operation** from the list of available methods. **Prioritize a "create", "add", or "post" operation.** If none are suitable, choose a simple "list" or "get all" operation.
    * Create a ${backtick}####${backtick} sub-heading for the operation (e.g., ${backtick}#### Create a new issue${backtick}, ${backtick}#### List all users${backtick}).
    * Write a complete, copy-pastable Ballerina code block inside a ${backtick}public function main() returns error? { ... }${backtick}.
    * The code must demonstrate how to build the necessary request payload and how to call the chosen operation. Use realistic and simple data for the payload.

5.  **Step 4 (Run):** Include the command to run the application, ${backtick}bal run${backtick}, within a ${backtick}bash${backtick} code block exactly as shown in the example.


**CONNECTOR INFORMATION TO USE:**
${getConnectorSummary(metadata)}
Available client methods: ${metadata.clientMethods.toString()}

Generate the "Quickstart" section now.
`;
}

function createBallerinaExamplesPrompt(ConnectorMetadata metadata) returns string {
    string backtick = "`";
    return string `

You are a technical writer tasked with creating the "Examples" section for a Ballerina connector's README.md file.

Your goal is to generate a section that is **structurally identical** to the perfect example provided below, including the exact introductory paragraph and the formatted list.

---
**PERFECT OUTPUT EXAMPLE (for Smartsheet):**

## Examples

The ${backtick}Smartsheet${backtick} connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-smartsheet/tree/main/examples), covering the following use cases:

1. [Project task management](https://github.com/ballerina-platform/module-ballerinax-smartsheet/tree/main/examples/project_task_management) - Demonstrates how to automate project task creation using Ballerina connector for Smartsheet.
2. [Basic sheet operations](https://github.com/ballerina-platform/module-ballerinax-smartsheet/tree/main/examples/basic_sheet_operations) - Illustrates creating, retrieving, and deleting sheets.

---

**TASK INSTRUCTIONS:**

Now, generate a new "Examples" section for the connector specified below. You must follow these rules precisely:

1.  **Replicate the Header and Intro:** Start with the ${backtick}## Examples${backtick} header. Use the exact introductory paragraph from the example, replacing the connector name and the main examples URL with the information provided. The main examples URL is the GitHub Repo URL followed by ${backtick}/tree/main/examples${backtick}.

2.  **Create an Ordered List:** For each example directory name provided in the "Connector Information", create one item in an ordered list (1., 2., 3., etc.).

3.  **Format Each List Item:** Each item in the list MUST follow this exact format:
    ${backtick}[Example Title](URL_to_example) - One-sentence description.${backtick}
    * **Example Title:** Convert the snake_case directory name (e.g., ${backtick}project_task_management${backtick}) into a human-readable, lowercase title (e.g., "project task management").
    * **URL_to_example:** Construct the full URL to the specific example's directory. This will be ${backtick}[GitHub_Repo_URL]/tree/main/examples/[example_directory_name]${backtick}.
    * **One-sentence description:** Write a single, concise sentence that summarizes the purpose of the example based on its name.

**CONNECTOR INFORMATION TO USE:**
${getConnectorSummary(metadata)}
Available Examples: ${metadata.examples.toString()}
`;
}

// prompt generation functions for tests README

function createTestReadmePrompt(ConnectorMetadata metadata) returns string {
    string backtick = "`";
    string tripleBacktick = "```";
    string conectorName = metadata.connectorName;
    string lowerCaseConnectorName = conectorName.toLowerAscii();

    return string `
    You are a senior Ballerina developer creating the README.md file for the tests directory of a Ballerina connector.

Your goal is to generate a complete "Running Tests" guide that is **structurally and textually identical** to the perfect example provided below, only replacing the service-specific placeholders.

---
**PERFECT OUTPUT EXAMPLE (for Smartsheet):**

# Running Tests

## Prerequisites
You need an API Access token from Smartsheet developer account.

To do this, refer to [Ballerina Smartsheet Connector](${backtick}https://github.com/ballerina-platform/module-ballerinax-smartsheet/blob/main/ballerina/README.md${backtick}).

## Running Tests

There are two test environments for running the Smartsheet connector tests. The default test environment is the mock server for Smartsheet API. The other test environment is the actual Smartsheet API.

You can run the tests in either of these environments and each has its own compatible set of tests.

 Test Groups | Environment
-------------|---------------------------------------------------
 mock_tests  | Mock server for Smartsheet API (Default Environment)
 live_tests  | Smartsheet API

## Running Tests in the Mock Server

To execute the tests on the mock server, ensure that the ${backtick}IS_LIVE_SERVER${backtick} environment variable is either set to ${backtick}false${backtick} or unset before initiating the tests.

This environment variable can be configured within the ${backtick}Config.toml${backtick} file located in the tests directory or specified as an environmental variable.

#### Using a Config.toml File

Create a ${backtick}Config.toml${backtick} file in the tests directory and the following content:

${tripleBacktick}toml
isLiveServer = false
${tripleBacktick}

#### Using Environment Variables

Alternatively, you can set your authentication credentials as environment variables:
If you are using linux or mac, you can use following method:
${tripleBacktick}bash
   export IS_LIVE_SERVER=false
${tripleBacktick}
If you are using Windows you can use following method:
${tripleBacktick}bash
   setx IS_LIVE_SERVER false
${tripleBacktick}
Then, run the following command to run the tests:

${tripleBacktick}bash
   ./gradlew clean test
${tripleBacktick}

## Running Tests Against Smartsheet Live API

#### Using a Config.toml File

Create a ${backtick}Config.toml${backtick} file in the tests directory and add your authentication credentials:

${tripleBacktick}toml
   isLiveServer = true
   token = "<your-smartsheet-access-token>"
${tripleBacktick}

#### Using Environment Variables

Alternatively, you can set your authentication credentials as environment variables:
If you are using linux or mac, you can use following method:
${tripleBacktick}bash
   export IS_LIVE_SERVER=true
   export SMARTSHEET_TOKEN="<your-smartsheet-access-token>"
${tripleBacktick}

If you are using Windows you can use following method:
${tripleBacktick}bash
   setx IS_LIVE_SERVER true
   setx SMARTSHEET_TOKEN <your-smartsheet-access-token>
${tripleBacktick}
Then, run the following command to run the tests:

${tripleBacktick}bash
   ./gradlew clean test
${tripleBacktick}
---

**TASK INSTRUCTIONS:**

Now, generate a new "Running Tests" README for the connector specified below. You must use the example above as a strict template and replace the placeholders as follows:

1.  Replace every instance of **"Smartsheet"** with **"${conectorName}"**.
2.  Replace every instance of **"smartsheet"** (in lowercase) with **"${lowerCaseConnectorName}"**. This applies to URLs and token placeholders like ${backtick}<your-smartsheet-access-token>${backtick}.
3.  Replace the link to the main README with the link matching the provided GitHub Repo URL, specifically pointing to ${backtick}/ballerina/README.md${backtick}.
4.  In the final "Environment Variables" section for the live API, replace **"SMARTSHEET_TOKEN"** with **"[CONNECTOR_UPPERCASE_NAME]_TOKEN"**.
5.  All other text, formatting, code blocks, and commands must be kept exactly the same.

Generate the complete "Running Tests" README now.
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
