
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

Now, generate a new overview for the following connector. DONT include any follow up questions or your opinions or any thing other than the given format. Follow these rules meticulously:

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
    string connectorName = metadata.connectorName;
    string backtick = "`";
    return string `
You are a technical writer creating the "Setup guide" section for a Ballerina connector's README.md file. Your task is to explain how a user can get the necessary API credentials from the third-party service.

Your goal is to generate a guide that is **structurally and tonally identical** to the perfect example provided below.

---
**PERFECT OUTPUT EXAMPLE (for Smartsheet):**

## Setup guide

To use the Smartsheet connector, you must have access to the Smartsheet API through a [Smartsheet developer account](${backtick}https://developers.smartsheet.com/${backtick}) and obtain an API access token. If you do not have a Smartsheet account, you can sign up for one [here](${backtick}https://www.smartsheet.com/try-it${backtick}).

### Step 1: Create a Smartsheet Account

1. Navigate to the [Smartsheet website](${backtick}https://www.smartsheet.com/${backtick}) and sign up for an account or log in if you already have one.

2. Ensure you have a Business or Enterprise plan, as the Smartsheet API is restricted to users on these plans.

### Step 2: Generate an API Access Token

1. Log in to your Smartsheet account.

2. On the left Navigation Bar at the bottom, select Account (your profile image), then Personal Settings.

3. In the new window, navigate to the API Access tab and select Generate new access token.

> **Tip:** You must copy and store this key somewhere safe. It won't be visible again in your account settings for security reasons.

---

**TASK INSTRUCTIONS:**

Now, generate a new "Setup guide" section for the ${connectorName} connector specified below. You must adhere to these rules strictly:

1.  **Perform Web Research:** You MUST search the web to find the following for the service:
    * The main website / sign-up page.
    * The developer portal or API documentation homepage.
    * An official guide or help article on how to generate API keys/access tokens.

2.  **Follow the Exact Structure:** Use the ${backtick}## Setup guide${backtick}, ${backtick}### Step 1${backtick}, and ${backtick}### Step 2${backtick} headers precisely as shown in the example.

3.  **Introductory Paragraph:** Write a paragraph explaining the need for an account and API token. It must include a Markdown link to the developer portal and the main sign-up page you found.

4.  **Step 1 (Create Account):**
    * Provide a link to the main website.
    * **Crucially, research and mention if the API access is limited to specific subscription plans** (e.g., "Business or Enterprise plan", "Pro plan or higher").

5.  **Step 2 (Generate Token):**
    * Provide clear, step-by-step instructions on how to find the API key generation page within the service's user interface.
    * **Use the official guide you researched to make these steps accurate.** (e.g., "Navigate to Settings > Developer > API Keys").

6.  **Include the Tip:** End the section with the exact "> **Tip:** ..." blockquote about saving the key securely.

**CONNECTOR INFORMATION TO USE:**
connector name: ${connectorName}

Generate the "Setup guide" section now.
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

// prompt generation functions for main README

function createHeaderAndBadges(ConnectorMetadata metadata) returns string {
    string connectorName = metadata.connectorName;
    string lowercaseConnectorName = connectorName.toLowerAscii();
    string githubRepoUrl = string `https://github.com/ballerina-platform/module-ballerinax-${lowercaseConnectorName}`;
    string githubOrgAndRepo = string `ballerina-platform/module-ballerinax-${lowercaseConnectorName}`;

    return string `
# Ballerina ${metadata.connectorName} connector

[![Build](${githubRepoUrl}/actions/workflows/ci.yml/badge.svg)](${githubRepoUrl}/actions/workflows/ci.yml)
[![Trivy](${githubRepoUrl}/actions/workflows/trivy-scan.yml/badge.svg)](${githubRepoUrl}/actions/workflows/trivy-scan.yml)
[![GraalVM Check](${githubRepoUrl}/actions/workflows/build-with-bal-test-graalvm.yml/badge.svg)](${githubRepoUrl}/actions/workflows/build-with-bal-test-graalvm.yml)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/${githubOrgAndRepo}.svg)](https://github.com/${githubOrgAndRepo}/commits/master)
[![GitHub Issues](https://img.shields.io/github/issues/ballerina-platform/ballerina-library/module/${lowercaseConnectorName}.svg?label=Open%20Issues)](https://github.com/ballerina-platform/ballerina-library/labels/module%${lowercaseConnectorName})
`;
}

function createUsefulLinksSection(ConnectorMetadata metadata) returns string {
    string backtick = "`";
    string lowercaseName = metadata.connectorName.toLowerAscii();
    return string `
## Useful links

* For more information go to the [${backtick}${lowercaseName}${backtick} package](https://central.ballerina.io/ballerinax/${lowercaseName}/latest).
* For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/learn/by-example/).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
`;
}

function createIndividualExampleDescriptionPrompt(ExampleData exampleData, ConnectorMetadata connectorMetadata) returns string {
    return string `
You are writing a detailed description for a specific Ballerina connector example.

Example Information:
- Name: ${exampleData.exampleName}
- Directory: ${exampleData.exampleDirName}
- Connector: ${connectorMetadata.connectorName}
- Directory: ${exampleData.exampleDirName}
- Connector: ${connectorMetadata.connectorName}

Ballerina Code Files:
${string:'join("\n\n---\n\n", ...exampleData.balFileContents)}

Write a comprehensive description that explains:
1. What this example demonstrates
2. The main use case it addresses
3. Key features of the ${connectorMetadata.connectorName} API it uses
4. Why someone would use this example

Keep it concise but informative, 2-3 paragraphs maximum.
Use markdown formatting.
`;
}

function createConfigExamplePrompt(ExampleData exampleMetadata, ConnectorMetadata connectorMetadata) returns string {
    return string `
Based on the Ballerina code below, generate a Config.toml example that shows what configuration is needed.

Ballerina Code:
${exampleMetadata.mainBalContent}

Connector: ${connectorMetadata.connectorName}

Provide a realistic Config.toml example with:
1. All required configuration fields
2. Placeholder values that clearly indicate what the user needs to provide
3. Comments explaining any complex fields

Format as a TOML code block.
`;
}

function createExpectedOutputPrompt(ExampleData exampleData) returns string {
    return string `
Based on this Ballerina example code, describe what output the user should expect when running this example:

${exampleData.mainBalContent}

Provide:
1. A brief description of what happens when the code runs
2. Example output format (if applicable)
3. Success indicators the user should look for

Keep it concise and practical.
`;
}

function createKeyConceptsPrompt(ExampleData exampleData) returns string {
    return string `
Analyze this Ballerina example code and identify the key concepts it demonstrates:

${exampleData.mainBalContent}

List the main programming concepts, API patterns, or Ballerina features showcased in this example.
Format as a bulleted list with brief explanations.
Focus on what developers can learn from this example.
`;
}

function createNextStepsPrompt(ExampleData exampleData, ConnectorMetadata connectorMetadata) returns string {
    return string `
Based on this example for ${connectorMetadata.connectorName}, suggest practical next steps for developers:

Example: ${exampleData.exampleName}
Code: ${exampleData.mainBalContent}

Provide 3-4 actionable next steps that help developers:
1. Extend or modify this example
2. Explore related ${connectorMetadata.connectorName} features
3. Build upon this example for real-world use

Keep suggestions practical and specific.
`;
}

public function createIndividualExamplePrompt(ExampleData exampleData, ConnectorMetadata connectorMetadata) returns string {
    string backtick = "`";
    string tripleBacktick = "```";
    return string `
    You are a senior Ballerina developer and technical writer creating a complete, self-contained README.md file for a single Ballerina example.

Your goal is to generate a guide that is **structurally identical** to the perfect example provided below, based on the Ballerina code you are given.

---
**PERFECT OUTPUT EXAMPLE (for Smartsheet + Slack):**

# Project Task Management Integration

This example demonstrates how to automate project task creation using Ballerina connector for Smartsheet. When a new project is created, the system automatically creates initial tasks in Smartsheet and sends a summary notification message to Slack.

## Prerequisites

1. **Smartsheet Setup**
   - Create a Smartsheet account (Business/Enterprise plan required)
   - Generate an API access token
   - Create two sheets:
     - "Projects" sheet with columns: Project Name, Start Date, Status
     - "Tasks" sheet with columns: Task Name, Assigned To, Due Date, Project Name

   > Refer the [Smartsheet setup guide](${backtick}https://github.com/ballerina-platform/module-ballerinax-smartsheet/blob/main/ballerina/README.md${backtick}) here.

2. **Slack Setup**
   - Refer the [Slack setup guide](${backtick}https://github.com/ballerina-platform/module-ballerinax-slack/blob/main/ballerina/README.md${backtick}) here.

3. For this example, create a ${backtick}Config.toml${backtick} file with your credentials. Here's an example of how your ${backtick}Config.toml${backtick} file should look:

${tripleBacktick}toml
smartsheetToken = "SMARTSHEET_ACCESS_TOKEN"
projectsSheetName = "PROJECT_SHEET_NAME"
tasksSheetName = "TASK_SHEET_NAME"
slackToken = "SLACK_TOKEN"
slackChannel = "SLACK_CHANNEL"
${tripleBacktick}

## Run the Example

1. Execute the following command to run the example:

${tripleBacktick}bash
bal run
${tripleBacktick}

2. The service will start on port 8080. You can test the integration by sending a POST request to create a new project:

${tripleBacktick}bash
curl -X POST http://localhost:8080/projects \
  -H "Content-Type: application/json" \
  -d '{
    "projectName": "Website Redesign",
    "startDate": "2025-08-25",
    "status" : "ACTIVE",
    "assignedTo": "developer@example.com"
  }'
${tripleBacktick}

---

**TASK INSTRUCTIONS:**

Now, generate a new, complete README for the following Ballerina example. You must analyze the provided Ballerina code and adhere to these rules strictly:

1.  **Analyze the Code:** Thoroughly read the provided Ballerina code to understand its purpose, what services it connects to, its configurable variables, and its HTTP endpoints.

2.  **Title:** Create a human-readable title from the example's directory name (e.g., from "${exampleData.exampleDirName}", create "${exampleData.exampleName}").

3.  **Introduction:** Write a single, concise paragraph describing what the example does.

4.  **Prerequisites Section:**
    * **Identify External Services:** From the ${backtick}import ballerinax/...${backtick} statements, identify all external connectors used (e.g., Smartsheet, Slack, etc.).
    * **Create Service Setup Steps:** For each service, create a numbered list item (e.g., "1. Smartsheet Setup").
    * **Add Setup Guide Links:** For each service, construct a link to its standard setup guide using the pattern: ${backtick}https://github.com/ballerina-platform/module-ballerinax-[SERVICE_NAME]/blob/main/ballerina/README.md${backtick}.
    * **Generate Config.toml:** Analyze the ${backtick}configurable${backtick} variables in the Ballerina code and create a complete ${backtick}Config.toml${backtick} example block. Use descriptive placeholder values (e.g., "YOUR_API_KEY").

5.  **Run the Example Section:**
    * Always include the ${backtick}bal run${backtick} command.
    * If the code defines an HTTP listener (${backtick}http:Listener${backtick}), analyze the service path and resource functions to construct a sample ${backtick}curl${backtick} command to test it. Infer a realistic JSON payload from the record types used in the function signatures. Assume the default port is 8080 unless specified otherwise.

**EXAMPLE CODE TO ANALYZE:**
- **Connector:** ${connectorMetadata.connectorName}
- **Example Name:** ${exampleData.exampleName}
- **Main Ballerina File Content:**
${exampleData.mainBalContent}

Generate the complete README.md now.
`;
}

function createMainExampleReadmePrompt(ConnectorMetadata metadata) returns string {
    string backtick = "`";
    string tripleBacktick = "```";
    return string `
You are a senior technical writer creating the main README.md for a Ballerina connector's "examples" directory.

Your goal is to generate a complete guide that is **structurally and textually identical** to the perfect example provided below, filling in the dynamic content based on the connector information.

---
**PERFECT OUTPUT EXAMPLE (for Twitter):**

# Examples

The ${backtick}twitter${backtick} connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-twitter/tree/main/examples), covering use cases like Direct message company mentions, and tweet performance tracker.

1. [Direct message company mentions](https://github.com/ballerina-platform/module-ballerinax-twitter/tree/main/examples/DM-mentions) - Integrate Twitter to send direct messages to users who mention the company in tweets.

2. [Tweet performance tracker](https://github.com/ballerina-platform/module-ballerinax-twitter/tree/main/examples/tweet-performance-tracker) - Analyze the performance of tweets posted by a user over the past month.

## Prerequisites

1. Generate Twitter credentials to authenticate the connector as described in the [Setup guide](https://central.ballerina.io/ballerinax/twitter/latest#setup-guide).

2. For each example, create a ${backtick}Config.toml${backtick} file the related configuration. Here's an example of how your ${backtick}Config.toml${backtick} file should look:

    ${tripleBacktick}toml
    token = "<Access Token>"
    ${tripleBacktick}

## Running an Example

Execute the following commands to build an example from the source:

* To build an example:

    ${tripleBacktick}bash
    bal build
    ${tripleBacktick}

* To run an example:

    ${tripleBacktick}bash
    bal run
    ${tripleBacktick}
---

**TASK INSTRUCTIONS:**

Now, generate a new "Examples" README for the connector specified below. You must use the example above as a strict template and adhere to these rules:

1.  **Header and Introduction:**
    * Start with the ${backtick}# Examples${backtick} header.
    * Write the introductory paragraph, replacing the connector name and constructing the main examples URL from the GitHub Repo URL provided.
    * Based on the list of "Available Example Directories", infer and mention a few representative use cases at the end of the sentence.

2.  **Numbered Example List:**
    * For each directory name in "Available Example Directories", create one item in a numbered list (1., 2., 3., etc.).
    * Each list item MUST follow this format: ${backtick}[Example Title](URL_to_example) - One-sentence description.${backtick}
    * **Example Title:** Convert the directory name (e.g., "DM-mentions") into a human-readable title (e.g., "Direct message company mentions").
    * **URL_to_example:** Construct the full URL using the GitHub Repo URL and the example directory name.
    * **One-sentence description:** Write a single, concise sentence that summarizes the purpose of the example based on its name.

3.  **Static Sections:**
    * Append the ${backtick}## Prerequisites${backtick} section exactly as shown, but replace the service name ("Twitter") and the link to the setup guide.
    * Append the ${backtick}## Running an Example${backtick} section exactly as shown. **Do not change this section.**

**CONNECTOR INFORMATION TO USE:**
${getConnectorSummary(metadata)}
Available Example Directories: ${metadata.examples.toString()}

Generate the complete examples/README.md now.
`;
}
