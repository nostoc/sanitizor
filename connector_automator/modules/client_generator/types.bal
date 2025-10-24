public type CommandExecutorError distinct error;

# Compilation error from a `bal build` output

public type CompilationError record {|
    # name of the file where error occured
    string fileName;
    # Line number of the error
    int line;
    # Column number of the error
    int column;
    # Error message description
    string message;
    # Type of error (ERROR, WARNING)
    string errorType;
    # file path
    string filePath?;
|};

# result of executing a `bal` command
public type CommandResult record {|
    # The command that was executed
    string command;
    # Whether the command executed successfully
    boolean success;
    # Exit code returned by the command
    int exitCode;
    # Standard output from the command
    string stdout;
    # Standard error output from the command
    string stderr;
    # Parsed compilation errors from the output
    CompilationError[] compilationErrors;
    # Execution time 
    decimal executionTime;
|};

# OpenAPI tool configuration options
public type OpenAPIToolOptions record {|
    # License file path to add copyright/license header to generated files
    string license = "docs/license.txt";
    # Tags to filter operations that need to be generated
    string[] tags?;
    # List of specific operations to generate
    string[] operations?;
    # Client method type - resource methods or remote methods
    "resource"|"remote" clientMethod = "resource";
|};

# Default OpenAPI tool options - can be overridden via configuration
configurable OpenAPIToolOptions options = {};

# Configuration for client generation
#
# + autoYes - field description  
# + quietMode - field description  
# + toolOptions - field description
public type ClientGeneratorConfig record {|
    boolean autoYes = false;
    boolean quietMode = false;
    OpenAPIToolOptions? toolOptions = ();
|};
