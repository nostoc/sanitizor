string backTick = "`";
string tripleBackTick = "```";

function getExampleCodegenerationPrompt(ConnectorDetails details, string useCase, string targetedContext) returns string {
    return string `
You are an expert Ballerina developer.
Write a complete, error-free Ballerina example code for the following use case for the connector ${details.connectorName}.

**CRITICAL INSTRUCTION: You MUST use the exact function and type names provided in the "Relevant Code Definitions" below. Do NOT shorten, simplify, invent, or modify any names. The provided names may be long and auto-generated; you MUST use them verbatim for the code to be correct.**

**Use Case:**
${useCase}

**Instructions:**
- Generate a single, complete ${backTick}main.bal${backTick} file.
- **Your ONLY source for function and type names is the "Relevant Code Definitions" section.** Every function call in your code must exactly match a signature from this section.
- The code must be ready to compile and run.
- Include necessary imports (e.g., ${backTick}ballerina/io${backTick}, ${backTick}ballerinax/${details.connectorName}${backTick}). 
- **Initialize the client using the exact init function signature provided in the "Client Initialization" section.** Use configurable variables for credentials and follow the ConnectionConfig structure exactly.
- When using the types of the ${details.connectorName}, import them using ${backTick}${details.connectorName}:relevantTypeName${backTick}. Don't define the types again in the example code.
- Implement the use case logic inside a ${backTick}public function main() returns error?${backTick}.
- Print the results of each step to the console using ${backTick}io:println()${backTick}.
- Do NOT include any explanations, markdown, or code fences. Only return raw Ballerina code.

**Relevant Code Definitions:**
${targetedContext}
`;
}

function getUsecasePrompt(ConnectorDetails details, string[] usedFunctions) returns string {
    string previouslyUsedSection = "";
    if usedFunctions.length() > 0 {
        string[] formattedUsedFunctions = from string func in usedFunctions
            select string `- '${func}'`;
        previouslyUsedSection = string `
**IMPORTANT: Previously Used Functions (Avoid these):**
You have already generated examples using the functions below.
To ensure variety, create a NEW and DISTINCT use case that does NOT use these functions.
${string:'join("\n", ...formattedUsedFunctions)}
`;
    }

    return string `
You are a Ballerina software architect.
Your task is to design a realistic, unique, and multi-step use case for a developer.

**Instructions:**
1.  Analyze the provided function signatures to understand the connector's capabilities.
2.  Devise a logical workflow that uses 2-3 functions in a sequence.
3.  Describe this workflow in a concise 'useCase' paragraph. The use case MUST be unique and different from any previous ones.
4.  For the 'requiredFunctions' array, extract the function identifiers based on these **strict rules**:
    - For a **resource** function, use the format **"METHOD function.path"** (e.g., "get admin.apps.approved.list").
    - For a **remote** function, use only the **function name** (e.g., "createRepository").
5.  Your final output MUST be a single, valid JSON object. Don't inlcude code  fences in the response. 

${previouslyUsedSection}

**Available Function Signatures:**
${details.functionSignatures}

**Required JSON Output Format:**
{
  "useCase": "A unique, multi-step workflow description.",
  "requiredFunctions": ["get admin.teams.list", "post admin.teams.create"]
}

**CRITICAL:** Follow the function format rules and create a distinct use case.
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
