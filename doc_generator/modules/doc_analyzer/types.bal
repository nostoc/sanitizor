// Basic types for document generation

// Document types that can be generated
public enum DocumentationType {
    MAIN_README,
    BALLERINA_README, 
    TESTS_README,
    EXAMPLES_README,
    EXAMPLE_SPECIFIC
}

// Basic connector analysis result
public type ConnectorAnalysis record {
    string connectorName;
    string description;
    string version;
    boolean hasExamples;
    boolean hasTests;
};

// Template content structure
public type TemplateContent record {
    string content;
    string[] placeholders;
};

// Simple error type
public type AnalysisError error<record {
    string message;
}>;
