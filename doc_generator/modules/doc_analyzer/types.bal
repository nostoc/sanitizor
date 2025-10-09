public type ConnectorAnalysis record {|
    string connectorName;
    string description;
    APIMetadata apiInfo;
    SetupRequirement[] setupRequirements;
    CodeExample[] codeExamples;
    TestConfiguration testConfig;
    ExampleProject[] examples;
|};

public type APIMetadata record {|
    string baseUrl;
    string version;
    AuthenticationType authType;
    Operation[] operations;
|};