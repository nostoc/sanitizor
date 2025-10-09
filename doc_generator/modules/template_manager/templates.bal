import doc_generator.doc_analyzer;

import ballerina/regex;

// Generate placeholder values from connector analysis
public function generatePlaceholderValues(doc_analyzer:ConnectorAnalysis analysis) returns doc_analyzer:PlaceholderValue[] {
    doc_analyzer:PlaceholderValue[] values = [];
    
    // Basic connector information
    values.push({placeholder: "CONNECTOR_NAME", value: analysis.connectorName});
    values.push({placeholder: "CONNECTOR_NAME_LOWER", value: analysis.connectorName.toLowerAscii()});
    values.push({placeholder: "VERSION", value: analysis.version});
    values.push({placeholder: "DESCRIPTION", value: analysis.description});
    
    // Operations information
    values.push({placeholder: "OPERATIONS_COUNT", value: analysis.operations.length().toString()});
    values.push({placeholder: "KEY_OPERATIONS", value: generateKeyOperationsList(analysis.operations)});
    values.push({placeholder: "OPERATIONS_LIST", value: generateOperationsList(analysis.operations)});
    
    // Features list
    values.push({placeholder: "FEATURES_LIST", value: generateFeaturesList(analysis)});
    
    // Setup requirements
    values.push({placeholder: "SETUP_REQUIREMENTS", value: generateSetupRequirementsList(analysis.setupRequirements)});
    
    // Examples information
    values.push({placeholder: "EXAMPLES_INFO", value: generateExamplesInfo(analysis.examples)});
    values.push({placeholder: "EXAMPLES_LIST", value: generateExamplesList(analysis.examples)});
    
    // Basic example code
    values.push({placeholder: "BASIC_EXAMPLE", value: generateBasicExample(analysis)});
    
    // Test coverage
    values.push({placeholder: "TEST_COVERAGE", value: generateTestCoverage(analysis.operations)});
    
    return values;
}

// Replace placeholders in template content
public function replacePlaceholders(string template, doc_analyzer:PlaceholderValue[] values) returns string {
    string result = template;
    
    foreach doc_analyzer:PlaceholderValue placeholderValue in values {
        // Escape special regex characters in the placeholder name
        string escapedPlaceholder = regex:replaceAll(placeholderValue.placeholder, "[\\[\\]\\(\\)\\{\\}\\*\\+\\?\\^\\$\\|\\\\\\.]", "\\\\$0");
        string pattern = "\\{\\{" + escapedPlaceholder + "\\}\\}";
        result = regex:replaceAll(result, pattern, placeholderValue.value);
    }
    
    return result;
}

// Generate a list of key operations
function generateKeyOperationsList(doc_analyzer:Operation[] operations) returns string {
    if operations.length() == 0 {
        return "- Basic API operations";
    }
    
    string[] keyOps = [];
    int count = 0;
    foreach doc_analyzer:Operation op in operations {
        if count >= 5 { // Show top 5 operations
            break;
        }
        keyOps.push(string `- **${op.httpMethod}**: ${op.description}`);
        count += 1;
    }
    
    if operations.length() > 5 {
        keyOps.push(string `- And ${operations.length() - 5} more operations...`);
    }
    
    return string:'join("\n", ...keyOps);
}

// Generate detailed operations list
function generateOperationsList(doc_analyzer:Operation[] operations) returns string {
    if operations.length() == 0 {
        return "No operations detected.";
    }
    
    string[] opsList = [];
    foreach doc_analyzer:Operation op in operations {
        opsList.push(string `#### ${op.name}
- **Method**: ${op.httpMethod}
- **Description**: ${op.description}`);
    }
    
    return string:'join("\n\n", ...opsList);
}

// Generate features list based on analysis
function generateFeaturesList(doc_analyzer:ConnectorAnalysis analysis) returns string {
    string[] features = [];
    
    if analysis.operations.length() > 0 {
        features.push(string `- ${analysis.operations.length()} API operations available`);
    }
    
    if analysis.examples.length() > 0 {
        features.push(string `- ${analysis.examples.length()} practical examples included`);
    }
    
    // Add features based on keywords
    foreach string keyword in analysis.keywords {
        if keyword == "authentication" {
            features.push("- Secure authentication support");
        } else if keyword == "oauth" {
            features.push("- OAuth 2.0 authentication");
        } else if keyword == "webhook" {
            features.push("- Webhook integration support");
        } else if keyword == "batch" {
            features.push("- Batch operations support");
        } else if keyword == "real-time" {
            features.push("- Real-time data access");
        }
    }
    
    if features.length() == 0 {
        features.push("- Comprehensive API integration");
        features.push("- Easy-to-use Ballerina connector");
        features.push("- Well-documented with examples");
    }
    
    return string:'join("\n", ...features);
}

// Generate setup requirements list
function generateSetupRequirementsList(doc_analyzer:SetupRequirement[] requirements) returns string {
    if requirements.length() == 0 {
        return "- Ballerina Swan Lake 2201.x or later\n- Valid API credentials";
    }
    
    string[] reqList = [];
    foreach doc_analyzer:SetupRequirement req in requirements {
        string marker = req.required ? "**Required**" : "*Optional*";
        reqList.push(string `- ${marker}: ${req.description}`);
    }
    
    return string:'join("\n", ...reqList);
}

// Generate examples information
function generateExamplesInfo(doc_analyzer:ExampleProject[] examples) returns string {
    if examples.length() == 0 {
        return "Basic usage examples are available in the documentation.";
    }
    
    string[] exampleInfo = [];
    foreach doc_analyzer:ExampleProject example in examples {
        // Use direct access since hasConfiguration is now required
        string configInfo = example.hasConfiguration ? " (with configuration)" : "";
        exampleInfo.push(string `- **${example.name}**: ${example.description}${configInfo}`);
    }
    
    return string:'join("\n", ...exampleInfo);
}

// Generate examples list for examples README
function generateExamplesList(doc_analyzer:ExampleProject[] examples) returns string {
    if examples.length() == 0 {
        return "No examples available yet.";
    }
    
    string[] examplesList = [];
    foreach doc_analyzer:ExampleProject example in examples {
        examplesList.push(string `## ${example.name}

${example.description}

**Directory**: ${example.path}
**Configuration Required**: ${example.hasConfiguration ? "Yes" : "No"}`);
    }
    
    return string:'join("\n\n", ...examplesList);
}

// Generate basic usage example
function generateBasicExample(doc_analyzer:ConnectorAnalysis analysis) returns string {    
    // Try to find a simple GET operation for the example
    string exampleOperation = "// Perform your operations here";
    foreach doc_analyzer:Operation op in analysis.operations {
        if op.httpMethod == "GET" && op.description.toLowerAscii().includes("get") {
            exampleOperation = string `// ${op.description}
    var result = check client->${op.name}();`;
            break;
        }
    }
    
    return exampleOperation;
}

// Generate test coverage information
function generateTestCoverage(doc_analyzer:Operation[] operations) returns string {
    if operations.length() == 0 {
        return "Basic connector functionality";
    }
    
    string[] coverage = [];
    coverage.push("All connector operations");
    coverage.push("Authentication mechanisms");
    coverage.push("Error handling scenarios");
    
    if operations.length() >= 10 {
        coverage.push("Comprehensive API coverage");
    }
    
    return string:'join("\n- ", ...coverage);
}
