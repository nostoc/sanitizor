import example_generator.analyzer;

string backTick = "`";
string tripleBackTick = "```";

function getExampleCodegenerationPrompt(analyzer:ConnectorDetails details, string useCase, string targetedContext) returns string {
    return string `
You are an expert Ballerina developer. Write a complete, error-free Ballerina example code for the following use case for the connector ${details.connectorName}. using ONLY the provided code definitions.

**Use Case:**
${useCase}

**Instructions:**
- Generate a single, complete ${backTick}main.bal${backTick} file.
- Use the provided **Relevant Code Definitions** as your only reference.
- The code must be ready to compile and run.
- Include necessary imports (e.g., ${backTick}ballerina/io${backTick}, ${backTick}ballerinax/${details.connectorName}${backTick}).
- Initialize the client using configurable variables for credentials.
- Implement the use case logic inside a ${backTick}public function main() returns error?${backTick}.
- Print the results of each step to the console using ${backTick}io:println()${backTick}.
- Do NOT include any explanations, markdown, or code fences. Only return raw Ballerina code.

**Relevant Code Definitions:**
${targetedContext}
`;
}

function getUsecasePrompt(analyzer:ConnectorDetails details) returns string {
    return string `
You are a Ballerina software architect. Your task is to design a realistic, multi-step use case for a developer using the provided connector.

**Instructions:**
1.  Analyze the provided function signatures to understand the connector's capabilities.
2.  Devise a logical workflow that uses 2-3 functions in a sequence.
3.  Describe this workflow in a concise 'useCase' paragraph.The generated usecase should be unique.
4.  For the 'requiredFunctions' array, extract key descriptive words from the function signatures that identify the functionality (e.g., if you see "resource isolated function get advisories", include "get advisories" as keywords).
5.  Your final output MUST be a single, valid JSON object with the keys "useCase" and "requiredFunctions". Do not include any other text or markdown.

**Available Function Signatures:**
${details.functionSignatures}

**Required JSON Output Format:**
{
  "useCase": "A paragraph describing the multi-step workflow. For example: 'First, retrieve all security advisories to understand threats. Then, get scanning alerts for the organization. Finally, examine details of a specific advisory.'",
  "requiredFunctions": ["get advisories", "get scanning alerts", "get advisory details"]
}

**Important:** For requiredFunctions, use descriptive keywords that capture the main functionality, not exact function names.
`;
}

function getExampleNamePrompt(string useCase) returns string {
    return string `
Generate a concise, descriptive example name for the following use case. The name should be 3-4 words maximum, use kebab-case (lowercase with hyphens), and clearly describe what the example demonstrates.

**Use Case:**
${useCase}

**Requirements:**
- Exactly 3-4 words
- Use kebab-case (e.g., "send-slack-message", "user-profile-management")
- Be descriptive and professional
- Focus on the main action or workflow

**Examples of good names:**
- "channel-message-posting"
- "user-profile-creation" 
- "file-upload-workflow"
- "team-member-invitation"

Return ONLY the example name, no explanations or additional text.
`;
}