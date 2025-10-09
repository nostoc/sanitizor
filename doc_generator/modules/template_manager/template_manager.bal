import ballerina/regex;
import doc_generator.doc_analyzer;

// Load template for a specific document type
public function loadTemplate(doc_analyzer:DocumentationType docType) returns doc_analyzer:TemplateContent|doc_analyzer:AnalysisError {
    string template = getTemplateContent(docType);
    string[] placeholders = extractPlaceholders(template);
    
    return {
        content: template,
        placeholders: placeholders
    };
}

// Get template content based on document type
function getTemplateContent(doc_analyzer:DocumentationType docType) returns string {
    match docType {
        doc_analyzer:MAIN_README => {
            return getMainReadmeTemplate();
        }
        doc_analyzer:BALLERINA_README => {
            return getBallerinaReadmeTemplate();
        }
        doc_analyzer:TESTS_README => {
            return getTestsReadmeTemplate();
        }
        doc_analyzer:EXAMPLES_README => {
            return getExamplesReadmeTemplate();
        }
        doc_analyzer:EXAMPLE_SPECIFIC => {
            return getExampleSpecificTemplate();
        }
    }
    
    return getMainReadmeTemplate();
}

// Extract placeholders from template content
function extractPlaceholders(string template) returns string[] {
    string[] placeholders = [];
    
    // Simple extraction of {{PLACEHOLDER}} patterns
    string[] parts = regex:split(template, "\\{\\{");
    
    foreach string part in parts {
        if part.includes("}}") {
            string[] subParts = regex:split(part, "\\}\\}");
            if subParts.length() > 0 {
                string placeholder = subParts[0];
                if placeholder.trim().length() > 0 {
                    placeholders.push(placeholder.trim());
                }
            }
        }
    }
    
    return placeholders;
}

// Main README template
function getMainReadmeTemplate() returns string {
    return "# {{CONNECTOR_NAME}} Connector\n\n{{DESCRIPTION}}\n\n## Overview\n\nThe {{CONNECTOR_NAME}} connector allows you to integrate with {{CONNECTOR_NAME}} services seamlessly. This connector provides access to {{OPERATIONS_COUNT}} operations.\n\n## Features\n\n{{FEATURES_LIST}}\n\n## Prerequisites\n\n{{SETUP_REQUIREMENTS}}\n\n## Quickstart\n\n### Installation\n\nAdd the dependency to your `Ballerina.toml` file.\n\n### Configuration\n\nCreate a `Config.toml` file with your credentials.\n\n### Basic Usage\n\n```ballerina\nimport ballerinax/{{CONNECTOR_NAME_LOWER}};\n\npublic function main() returns error? {\n    // Initialize the connector\n    {{CONNECTOR_NAME_LOWER}}:Client client = check new();\n    \n    // Example operation\n    {{BASIC_EXAMPLE}}\n}\n```\n\n## Examples\n\n{{EXAMPLES_INFO}}\n\n## API Reference\n\n### Available Operations\n\n{{OPERATIONS_LIST}}\n\n## Contributing\n\nContributions are welcome!\n\n## License\n\nThis project is licensed under the Apache License 2.0.";
}

// Ballerina module README template
function getBallerinaReadmeTemplate() returns string {
    return "# Ballerina {{CONNECTOR_NAME}} Connector\n\n{{DESCRIPTION}}\n\n## Module Overview\n\nThis module provides a Ballerina connector for {{CONNECTOR_NAME}}, enabling developers to:\n\n{{FEATURES_LIST}}\n\n## Setup\n\n{{SETUP_REQUIREMENTS}}\n\n## Usage\n\n{{BASIC_EXAMPLE}}\n\n## Examples\n\n{{EXAMPLES_INFO}}\n\n## Compatibility\n\n- Ballerina Swan Lake 2201.x and later\n- {{CONNECTOR_NAME}} API {{VERSION}}";
}

// Tests README template  
function getTestsReadmeTemplate() returns string {
    return "# Running Tests\n\nThis guide explains how to run tests for the {{CONNECTOR_NAME}} connector.\n\n## Prerequisites\n\n{{SETUP_REQUIREMENTS}}\n\n## Test Configuration\n\nCreate a `Config.toml` file in the tests directory.\n\n## Running Tests\n\nExecute the tests using:\n\n```bash\nbal test\n```\n\n## Test Coverage\n\nThe test suite covers:\n- {{TEST_COVERAGE}}\n\n## Test Data\n\nTests use mock data to avoid affecting production systems.";
}

// Examples README template
function getExamplesReadmeTemplate() returns string {
    return "# {{CONNECTOR_NAME}} Examples\n\nThis directory contains examples demonstrating how to use the {{CONNECTOR_NAME}} connector.\n\n## Available Examples\n\n{{EXAMPLES_LIST}}\n\n## Running Examples\n\n1. Configure your credentials in `Config.toml`\n2. Navigate to an example directory\n3. Run: `bal run`\n\n## Prerequisites\n\n{{SETUP_REQUIREMENTS}}";
}

// Example-specific template
function getExampleSpecificTemplate() returns string {
    return "# {{EXAMPLE_NAME}} Example\n\n{{EXAMPLE_DESCRIPTION}}\n\n## Prerequisites\n\n{{SETUP_REQUIREMENTS}}\n\n## Setup\n\n1. Configure your {{CONNECTOR_NAME}} credentials\n2. Install dependencies: `bal build`\n\n## Running\n\n```bash\nbal run\n```\n\n## Expected Output\n\nThis example demonstrates {{EXAMPLE_FUNCTIONALITY}}.";
}
