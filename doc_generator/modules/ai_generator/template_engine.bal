import ballerina/io;
import ballerina/file;
import ballerina/lang.'string as strings;

public type TemplateData record {|
    string CONNECTOR_NAME?;
    string VERSION?;
    string DESCRIPTION?;
    string AI_GENERATED_OVERVIEW?;
    string AI_GENERATED_SETUP?;
    string AI_GENERATED_QUICKSTART?;
    string AI_GENERATED_EXAMPLES?;
    string AI_GENERATED_USAGE?;
    string AI_GENERATED_TESTING_APPROACH?;
    string AI_GENERATED_TEST_SCENARIOS?;
    string AI_GENERATED_EXAMPLE_DESCRIPTIONS?;
    string AI_GENERATED_GETTING_STARTED?;
|};

public class TemplateEngine {
    private string templatesPath;
    
    public function init(string templatesPath = "modules/templates") {
        self.templatesPath = templatesPath;
    }
    
    public function processTemplate(string templateName, TemplateData data) returns string|error {
        string templatePath = self.templatesPath + "/" + templateName;
        
        if !check file:test(templatePath, file:EXISTS) {
            return error("Template not found: " + templatePath);
        }
        
        string template = check io:fileReadString(templatePath);
        return self.substituteVariables(template, data);
    }
    
    private function substituteVariables(string template, TemplateData data) returns string {
        string result = template;
        
        // Simple string replacement function
        string connectorName = data.CONNECTOR_NAME ?: "";
        if connectorName != "" {
            result = self.simpleReplace(result, "{{CONNECTOR_NAME}}", connectorName);
        }
        
        string version = data.VERSION ?: "";
        if version != "" {
            result = self.simpleReplace(result, "{{VERSION}}", version);
        }
        
        string description = data.DESCRIPTION ?: "";
        if description != "" {
            result = self.simpleReplace(result, "{{DESCRIPTION}}", description);
        }
        
        string overview = data.AI_GENERATED_OVERVIEW ?: "";
        if overview != "" {
            result = self.simpleReplace(result, "{{AI_GENERATED_OVERVIEW}}", overview);
        }
        
        string setup = data.AI_GENERATED_SETUP ?: "";
        if setup != "" {
            result = self.simpleReplace(result, "{{AI_GENERATED_SETUP}}", setup);
        }
        
        string quickstart = data.AI_GENERATED_QUICKSTART ?: "";
        if quickstart != "" {
            result = self.simpleReplace(result, "{{AI_GENERATED_QUICKSTART}}", quickstart);
        }
        
        string examples = data.AI_GENERATED_EXAMPLES ?: "";
        if examples != "" {
            result = self.simpleReplace(result, "{{AI_GENERATED_EXAMPLES}}", examples);
        }
        
        string usage = data.AI_GENERATED_USAGE ?: "";
        if usage != "" {
            result = self.simpleReplace(result, "{{AI_GENERATED_USAGE}}", usage);
        }
        
        string testingApproach = data.AI_GENERATED_TESTING_APPROACH ?: "";
        if testingApproach != "" {
            result = self.simpleReplace(result, "{{AI_GENERATED_TESTING_APPROACH}}", testingApproach);
        }
        
        string testScenarios = data.AI_GENERATED_TEST_SCENARIOS ?: "";
        if testScenarios != "" {
            result = self.simpleReplace(result, "{{AI_GENERATED_TEST_SCENARIOS}}", testScenarios);
        }
        
        string exampleDescriptions = data.AI_GENERATED_EXAMPLE_DESCRIPTIONS ?: "";
        if exampleDescriptions != "" {
            result = self.simpleReplace(result, "{{AI_GENERATED_EXAMPLE_DESCRIPTIONS}}", exampleDescriptions);
        }
        
        string gettingStarted = data.AI_GENERATED_GETTING_STARTED ?: "";
        if gettingStarted != "" {
            result = self.simpleReplace(result, "{{AI_GENERATED_GETTING_STARTED}}", gettingStarted);
        }
        
        return result;
    }
    
    private function simpleReplace(string text, string searchFor, string replaceWith) returns string {
        string result = text;
        int? index = strings:indexOf(result, searchFor);
        while index is int {
            string before = result.substring(0, index);
            string after = result.substring(index + searchFor.length());
            result = before + replaceWith + after;
            index = strings:indexOf(result, searchFor);
        }
        return result;
    }
    
    public function writeOutput(string content, string outputPath) returns error? {
        check io:fileWriteString(outputPath, content);
    }
    
    public function createTemplateData(ConnectorMetadata metadata) returns TemplateData {
        return {
            CONNECTOR_NAME: metadata.connectorName,
            VERSION: metadata.version,
            DESCRIPTION: metadata.description
        };
    }
    
    public function mergeAIContent(TemplateData baseData, map<string> aiContent) returns TemplateData {
        TemplateData merged = baseData.clone();
        
        foreach var [key, value] in aiContent.entries() {
            match key {
                "overview" => { merged.AI_GENERATED_OVERVIEW = value; }
                "setup" => { merged.AI_GENERATED_SETUP = value; }
                "quickstart" => { merged.AI_GENERATED_QUICKSTART = value; }
                "examples" => { merged.AI_GENERATED_EXAMPLES = value; }
                "usage" => { merged.AI_GENERATED_USAGE = value; }
                "testing_approach" => { merged.AI_GENERATED_TESTING_APPROACH = value; }
                "test_scenarios" => { merged.AI_GENERATED_TEST_SCENARIOS = value; }
                "example_descriptions" => { merged.AI_GENERATED_EXAMPLE_DESCRIPTIONS = value; }
                "getting_started" => { merged.AI_GENERATED_GETTING_STARTED = value; }
            }
        }
        
        return merged;
    }
}