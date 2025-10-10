import ballerina/ai;
import ballerinax/ai.anthropic;
import ballerina/io;
import ballerina/file;

public class DocumentationGenerator {
    private ai:ModelProvider anthropicModel;
    private ConnectorAnalyzer analyzer;
    private TemplateEngine templateEngine;
    
    public function init(string apiKey) returns error? {
        self.anthropicModel = check new anthropic:ModelProvider(
            apiKey,
            anthropic:CLAUDE_3_7_SONNET_20250219,
            "2023-06-01"
        );
        self.analyzer = new ConnectorAnalyzer();
        self.templateEngine = new TemplateEngine();
    }
    
    public function generateAllDocumentation(string connectorPath) returns error? {
        io:println("📋 Analyzing connector structure...");
        
        io:println("📝 Generating documentation...");
        check self.generateBallerinaReadme(connectorPath);
        check self.generateTestsReadme(connectorPath);
        check self.generateExamplesReadme(connectorPath);
        check self.generateMainReadme(connectorPath);
        
        io:println("✅ All documentation generated successfully!");
    }
    
    public function generateBallerinaReadme(string connectorPath) returns error? {
        io:println("📋 Analyzing connector for Ballerina README...");
        ConnectorMetadata metadata = check self.analyzer.analyzeConnector(connectorPath);
        
        io:println("🤖 Generating AI content...");
        map<string> aiContent = check self.generateBallerinaContent(metadata);
        
        io:println("📄 Processing template...");
        TemplateData templateData = self.templateEngine.createTemplateData(metadata);
        TemplateData finalData = self.templateEngine.mergeAIContent(templateData, aiContent);
        
        string content = check self.templateEngine.processTemplate("ballerina_readme_template.md", finalData);
        
        string outputPath = connectorPath + "/ballerina/README.md";
        check self.ensureDirectoryExists(connectorPath + "/ballerina");
        check self.templateEngine.writeOutput(content, outputPath);
        
        io:println("✅ Ballerina README generated: " + outputPath);
    }
    
    public function generateTestsReadme(string connectorPath) returns error? {
        io:println("📋 Analyzing tests for README...");
        ConnectorMetadata metadata = check self.analyzer.analyzeConnector(connectorPath);
        
        io:println("🤖 Generating AI content...");
        map<string> aiContent = check self.generateTestsContent(metadata);
        
        io:println("📄 Processing template...");
        TemplateData templateData = self.templateEngine.createTemplateData(metadata);
        TemplateData finalData = self.templateEngine.mergeAIContent(templateData, aiContent);
        
        string content = check self.templateEngine.processTemplate("tests_readme_template.md", finalData);
        
        string outputPath = connectorPath + "/ballerina/tests/README.md";
        check self.ensureDirectoryExists(connectorPath + "/ballerina/tests");
        check self.templateEngine.writeOutput(content, outputPath);
        
        io:println("✅ Tests README generated: " + outputPath);
    }
    
    public function generateExamplesReadme(string connectorPath) returns error? {
        io:println("📋 Analyzing examples for README...");
        ConnectorMetadata metadata = check self.analyzer.analyzeConnector(connectorPath);
        
        io:println("🤖 Generating AI content...");
        map<string> aiContent = check self.generateExamplesContent(metadata);
        
        io:println("📄 Processing template...");
        TemplateData templateData = self.templateEngine.createTemplateData(metadata);
        TemplateData finalData = self.templateEngine.mergeAIContent(templateData, aiContent);
        
        string content = check self.templateEngine.processTemplate("examples_readme_template.md", finalData);
        
        string outputPath = connectorPath + "/examples/README.md";
        check self.ensureDirectoryExists(connectorPath + "/examples");
        check self.templateEngine.writeOutput(content, outputPath);
        
        io:println("✅ Examples README generated: " + outputPath);
    }
    
    public function generateMainReadme(string connectorPath) returns error? {
        io:println("📋 Analyzing connector for Main README...");
        ConnectorMetadata metadata = check self.analyzer.analyzeConnector(connectorPath);
        
        io:println("🤖 Generating AI content...");
        map<string> aiContent = check self.generateMainContent(metadata);
        
        io:println("📄 Processing template...");
        TemplateData templateData = self.templateEngine.createTemplateData(metadata);
        TemplateData finalData = self.templateEngine.mergeAIContent(templateData, aiContent);
        
        string content = check self.templateEngine.processTemplate("main_readme_template.md", finalData);
        
        string outputPath = connectorPath + "/README.md";
        check self.templateEngine.writeOutput(content, outputPath);
        
        io:println("✅ Main README generated: " + outputPath);
    }
    
    private function generateBallerinaContent(ConnectorMetadata metadata) returns map<string>|error {
        map<string> content = {};
        
        // Generate Overview
        string overviewPrompt = self.createBallerinaOverviewPrompt(metadata);
        content["overview"] = check self.callAI(overviewPrompt);
        
        // Generate Setup Guide
        string setupPrompt = self.createBallerinaSetupPrompt(metadata);
        content["setup"] = check self.callAI(setupPrompt);
        
        // Generate Quick Start
        string quickstartPrompt = self.createBallerinaQuickstartPrompt(metadata);
        content["quickstart"] = check self.callAI(quickstartPrompt);
        
        // Generate Examples
        string examplesPrompt = self.createBallerinaExamplesPrompt(metadata);
        content["examples"] = check self.callAI(examplesPrompt);
        
        return content;
    }
    
    private function generateTestsContent(ConnectorMetadata metadata) returns map<string>|error {
        map<string> content = {};
        
        string testingApproachPrompt = self.createTestingApproachPrompt(metadata);
        content["testing_approach"] = check self.callAI(testingApproachPrompt);
        
        string testScenariosPrompt = self.createTestScenariosPrompt(metadata);
        content["test_scenarios"] = check self.callAI(testScenariosPrompt);
        
        return content;
    }
    
    private function generateExamplesContent(ConnectorMetadata metadata) returns map<string>|error {
        map<string> content = {};
        
        string exampleDescPrompt = self.createExampleDescriptionsPrompt(metadata);
        content["example_descriptions"] = check self.callAI(exampleDescPrompt);
        
        string gettingStartedPrompt = self.createGettingStartedPrompt(metadata);
        content["getting_started"] = check self.callAI(gettingStartedPrompt);
        
        return content;
    }
    
    private function generateMainContent(ConnectorMetadata metadata) returns map<string>|error {
        map<string> content = {};
        
        string overviewPrompt = self.createMainOverviewPrompt(metadata);
        content["overview"] = check self.callAI(overviewPrompt);
        
        string usagePrompt = self.createMainUsagePrompt(metadata);
        content["usage"] = check self.callAI(usagePrompt);
        
        return content;
    }
    
    private function callAI(string prompt) returns string|error {
        ai:ChatMessage[] messages = [{role: "user", content: prompt}];
        ai:ChatAssistantMessage response = check self.anthropicModel->chat(messages, tools = []);
        string? content = response.content;
        if content is string {
            return content;
        }
        return "";
    }
    
    private function ensureDirectoryExists(string dirPath) returns error? {
        if !check file:test(dirPath, file:EXISTS) {
            check file:createDir(dirPath, file:RECURSIVE);
        }
    }
    
    // Prompt generation methods for Ballerina README
    private function createBallerinaOverviewPrompt(ConnectorMetadata metadata) returns string {
        return string `
You are writing the Overview section for a Ballerina connector's README.md file.

Connector Information:
${self.analyzer.getConnectorSummary(metadata)}

Write a comprehensive overview section that:
1. Explains what this connector does in 2-3 sentences
2. Lists the key features and capabilities
3. Mentions the service/API it connects to
4. Highlights the main use cases

Keep it professional, concise, and focused on the connector's value proposition.
Format the response in markdown with appropriate headers and bullet points.
`;
    }
    
    private function createBallerinaSetupPrompt(ConnectorMetadata metadata) returns string {
        return string `
You are writing the Setup Guide section for a Ballerina connector's README.md file.

Connector Information:
${self.analyzer.getConnectorSummary(metadata)}

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
    
    private function createBallerinaQuickstartPrompt(ConnectorMetadata metadata) returns string {
        return string `
You are writing the Quick Start section for a Ballerina connector's README.md file.

Connector Information:
${self.analyzer.getConnectorSummary(metadata)}

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
    
    private function createBallerinaExamplesPrompt(ConnectorMetadata metadata) returns string {
        return string `
You are writing the Examples section for a Ballerina connector's README.md file.

Connector Information:
${self.analyzer.getConnectorSummary(metadata)}

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
    
    private function createTestingApproachPrompt(ConnectorMetadata metadata) returns string {
        return string `
You are writing the Testing Approach section for a Ballerina connector's tests README.md file.

Connector Information:
${self.analyzer.getConnectorSummary(metadata)}

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
    
    private function createTestScenariosPrompt(ConnectorMetadata metadata) returns string {
        return string `
You are writing the Test Scenarios section for a Ballerina connector's tests README.md file.

Connector Information:
${self.analyzer.getConnectorSummary(metadata)}

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
    
    private function createExampleDescriptionsPrompt(ConnectorMetadata metadata) returns string {
        return string `
You are writing detailed descriptions for examples in a Ballerina connector's examples README.md file.

Connector Information:
${self.analyzer.getConnectorSummary(metadata)}

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
    
    private function createGettingStartedPrompt(ConnectorMetadata metadata) returns string {
        return string `
You are writing a Getting Started section for a Ballerina connector's examples README.md file.

Connector Information:
${self.analyzer.getConnectorSummary(metadata)}

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
    
    private function createMainOverviewPrompt(ConnectorMetadata metadata) returns string {
        return string `
You are writing the main overview for a Ballerina connector's root README.md file.

Connector Information:
${self.analyzer.getConnectorSummary(metadata)}

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
    
    private function createMainUsagePrompt(ConnectorMetadata metadata) returns string {
        return string `
You are writing the Usage section for a Ballerina connector's root README.md file.

Connector Information:
${self.analyzer.getConnectorSummary(metadata)}

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
}