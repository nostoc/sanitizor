// Basic types for document generation

// Document types that can be generated
public enum DocumentationType {
    MAIN_README,
    BALLERINA_README, 
    TESTS_README,
    EXAMPLES_README,
    EXAMPLE_SPECIFIC
}

// API Operation information
public type Operation record {
    string name;
    string httpMethod;
    string description;
};

// Example project information
public type ExampleProject record {
    string name;
    string description;
    string path;
    boolean hasConfiguration;
};

// Setup requirement information
public type SetupRequirement record {
    string name;
    string description;
    boolean required;
};

// Template-related types
public type TemplateContent record {
    string content;
    string[] placeholders;
};

public type PlaceholderValue record {
    string placeholder;
    string value;
};

// Enhanced connector analysis result
public type ConnectorAnalysis record {
    string connectorName;
    string description;
    string version;
    string[] keywords;
    boolean hasExamples;
    boolean hasTests;
    Operation[] operations;
    ExampleProject[] examples;
    SetupRequirement[] setupRequirements;
    string[] imports;
};

// Simple error type
public type AnalysisError error<record {
    string message;
}>;
