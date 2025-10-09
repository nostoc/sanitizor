import ballerinax/ai;
import ballerina/log;
import ballerina/regex;
import ballerinax/ai.anthropic;
import doc_generator.doc_analyzer;

// AI service configuration
configurable string apiKey = ?;
configurable boolean enableAI = true;
configurable string model = "claude-3-5-sonnet-20241022";
configurable int maxRetries = 3;
configurable int timeoutSeconds = 30;

// AI model provider
ai:ModelProvider? anthropicModel = ();

// AI-enhanced documentation content
public type AIEnhancedContent record {
    string description;
    string features;
    string setupGuide;
    string quickstart;
    string examples;
    string apiOverview;
};

// Initialize the AI service
public function initAIService() returns error? {
    if !enableAI {
        log:printInfo("AI enhancement disabled, using template-based generation");
        return;
    }
    
    ai:ModelProvider|error modelProvider = new anthropic:ModelProvider(
        apiKey: apiKey,
        model: model,
        timeout: timeoutSeconds
    );
    
    if modelProvider is error {
        log:printError("Failed to initialize AI service", modelProvider);
        return modelProvider;
    }
    
    anthropicModel = modelProvider;
    log:printInfo("✅ AI service initialized successfully");
    return;
}

// Generate AI-enhanced documentation content
public function generateAIEnhancedContent(doc_analyzer:ConnectorAnalysis analysis) returns AIEnhancedContent|error {
    if anthropicModel is () {
        return error("AI service not initialized. Call initAIService() first.");
    }
    
    log:printInfo("🤖 Generating AI-enhanced documentation content...");
    
    // Create comprehensive prompt based on real Smartsheet connector style
    string prompt = createDocumentationPrompt(analysis);
    
    // Generate content using AI
    ai:GenerateResponse|error response = anthropicModel.generate(prompt);
    
    if response is error {
        log:printError("AI generation failed", response);
        return response;
    }
    
    // Parse AI response into structured content
    AIEnhancedContent|error content = parseAIResponse(response.output);
    
    if content is error {
        log:printError("Failed to parse AI response", content);
        return content;
    }
    
    log:printInfo("✅ AI-enhanced content generated successfully");
    return content;
}

// Create comprehensive prompt for documentation generation
function createDocumentationPrompt(doc_analyzer:ConnectorAnalysis analysis) returns string {
    // Build operations summary
    string operationsSummary = buildOperationsSummary(analysis.operations);
    
    // Build examples summary
    string examplesSummary = buildExamplesSummary(analysis.examples);
    
    // Build keywords context
    string keywordsContext = string:'join(", ", ...analysis.keywords);
    
    return string `You are an expert technical writer creating professional documentation for Ballerina connectors. 

CONNECTOR ANALYSIS:
- Name: ${analysis.connectorName}
- Version: ${analysis.version}
- Operations Count: ${analysis.operations.length()}
- Examples Count: ${analysis.examples.length()}
- Keywords: ${keywordsContext}

OPERATIONS SUMMARY:
${operationsSummary}

EXAMPLES AVAILABLE:
${examplesSummary}

SETUP REQUIREMENTS:
${buildSetupRequirementsSummary(analysis.setupRequirements)}

TASK: Create professional Ballerina connector documentation that matches the quality and style of official Ballerina connectors (like the Smartsheet connector). The documentation should be:

1. **Professional & Clear**: Use the same tone and structure as official Ballerina connectors
2. **Comprehensive**: Cover all essential sections for a production-ready connector
3. **Developer-Focused**: Include practical examples and clear instructions
4. **API-Aware**: Highlight key operations and capabilities intelligently

Generate the following sections as separate blocks:

[DESCRIPTION]
Write a compelling 2-3 sentence description of what this connector does and its main value proposition. Focus on real-world use cases.

[FEATURES]
List 4-6 key features in bullet points. Focus on capabilities that developers care about (operation types, authentication, key functionalities).

[SETUP_GUIDE]
Write a comprehensive setup guide with numbered steps. Include account setup, API key generation, and any prerequisites. Be specific and actionable.

[QUICKSTART]
Create a complete quickstart section with:
- Module import
- Configuration setup (Config.toml)
- Basic client initialization
- 1-2 practical code examples using actual operations from the analysis

[EXAMPLES]
Describe the available examples and their purposes. Make it engaging and show the value of each example.

[API_OVERVIEW]
Provide an overview of the API capabilities, organizing operations into logical groups (e.g., "User Management", "Data Operations", etc.).

Format each section clearly with appropriate markdown headers and code blocks. Use the connector name "${analysis.connectorName}" throughout.`;
}

// Build operations summary for AI prompt
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

// Build examples summary for AI prompt
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

// Build setup requirements summary
function buildSetupRequirementsSummary(doc_analyzer:SetupRequirement[] requirements) returns string {
    if requirements.length() == 0 {
        return "Standard Ballerina setup required.";
    }
    
    string[] summary = [];
    foreach doc_analyzer:SetupRequirement req in requirements {
        string marker = req.required ? "Required" : "Optional";
        summary.push(string `- ${marker}: ${req.description}`);
    }
    
    return string:'join("\n", ...summary);
}

// Parse AI response into structured content
function parseAIResponse(string response) returns AIEnhancedContent|error {
    // Extract sections using regex patterns
    string description = extractSection(response, "\\[DESCRIPTION\\]", "\\[FEATURES\\]") ?: "Professional connector for seamless integration.";
    string features = extractSection(response, "\\[FEATURES\\]", "\\[SETUP_GUIDE\\]") ?: "- Comprehensive API integration\n- Easy-to-use interface";
    string setupGuide = extractSection(response, "\\[SETUP_GUIDE\\]", "\\[QUICKSTART\\]") ?: "1. Install Ballerina\n2. Configure your credentials";
    string quickstart = extractSection(response, "\\[QUICKSTART\\]", "\\[EXAMPLES\\]") ?: "Import the module and create a client instance.";
    string examples = extractSection(response, "\\[EXAMPLES\\]", "\\[API_OVERVIEW\\]") ?: "Practical examples are available in the examples directory.";
    string apiOverview = extractSection(response, "\\[API_OVERVIEW\\]", "") ?: "Comprehensive API operations for full functionality.";
    
    return {
        description: description.trim(),
        features: features.trim(),
        setupGuide: setupGuide.trim(),
        quickstart: quickstart.trim(),
        examples: examples.trim(),
        apiOverview: apiOverview.trim()
    };
}

// Extract section content between markers
function extractSection(string text, string startMarker, string endMarker) returns string? {
    string[] startMatches = regex:findAll(text, startMarker);
    if startMatches.length() == 0 {
        return ();
    }
    
    int startIndex = text.indexOf(startMarker) ?: -1;
    if startIndex == -1 {
        return ();
    }
    
    startIndex += startMarker.length();
    
    int endIndex = text.length();
    if endMarker.length() > 0 {
        int? foundEndIndex = text.indexOf(endMarker, startIndex);
        if foundEndIndex is int {
            endIndex = foundEndIndex;
        }
    }
    
    if startIndex >= endIndex {
        return ();
    }
    
    return text.substring(startIndex, endIndex);
}
