import example_generator.analyzer;

string backTick = "`";
string tripleBackTick = "```";

function getExampleCodegenerationPrompt(analyzer:ConnectorDetails details, string useCase) returns string {
    return string `
You are an expert Ballerina developer. Write a complete, error-free Ballerina example code for the following use case.

**Use Case:**
${useCase}

**Instructions:**
- Generate a single, complete ${backTick}main.bal${backTick} file.
- The code must be ready to compile and run.
- Include necessary imports (e.g., ${backTick}ballerina/io${backTick}, ${backTick}ballerinax/${details.connectorName}${backTick}).
- Initialize the client using configurable variables for credentials.
- Implement the use case logic inside a ${backTick}public function main() returns error?${backTick}.
- Print the results of each step to the console using ${backTick}io:println()${backTick}.
- Do NOT include any explanations, markdown, or code fences. Only return raw Ballerina code.

**client.bal:**
${details.clientBalContent}

**types.bal:**
${details.typesBalContent}
`;
}

function getUsecasePrompt(analyzer:ConnectorDetails details) returns string {
    return string `
You are a Ballerina software architect. Based on the provided Ballerina connector's client.bal and types.bal, propose a realistic, multi-step use case for a developer. The use case should involve calling 2-3 of the available functions in a logical sequence.

Describe the use case in a single paragraph. For example: "First, create a new user profile. Then, fetch that user's ID to retrieve their recent activity. Finally, post a summary of that activity to a project channel."

**conncetor name** : ${details.connectorName}

${backTick}**client.bal:**${backTick}
${details.clientBalContent}

${backTick}**types.bal:**${backTick}
${details.typesBalContent}
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