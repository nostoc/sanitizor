import sanitizor.command_executor;
import sanitizor.error_registry;

import ballerina/io;
import ballerina/test;

@test:Config {}
function testFixRealOpenApiSpec() returns error? {
    // Test with the actual flattened OpenAPI spec  
    string specPath = "/home/hansika/dev/sanitizor/temp-workspace/docs/spec/flattened_openapi.json";

    io:println("Testing real schema identification from types.bal...");

    // Use a real compilation error from the actual bal build
    command_executor:CompilationError[] realError = [
        {fileName: "types.bal", line: 14, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 432, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 576, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 581, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 599, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 624, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 643, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 651, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 747, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 1110, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 1239, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 1480, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 1490, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 1498, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 1616, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 1718, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 1872, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 1877, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 1942, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 1947, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 2012, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 2083, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 2127, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 2232, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 2268, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 2290, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 2295, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 2302, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 2417, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 2604, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 2752, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 3172, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 3186, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 3254, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 3278, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 3335, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 3421, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 3454, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 3495, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 3520, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 3652, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 3657, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 3872, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 3908, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 3922, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 4011, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 4115, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 4254, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 4259, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 4264, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 4407, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 4713, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 4799, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 4992, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 4997, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 5008, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 5249, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 5563, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 5670, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 5802, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 5973, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 6015, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 6059, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 6556, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 6566, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 6954, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 7044, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 7138, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 7208, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 7213, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 7311, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 7316, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 7919, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 8029, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 8062, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 8125, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 8133, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 8138, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 8261, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 8322, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 8380, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 8713, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 8718, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 8762, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 8798, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 8890, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 8921, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 8971, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 9014, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 9052, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 9172, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 9218, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 9331, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 9437, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 9624, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 9638, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 9770, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 9836, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 9857, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 10036, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 10270, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 10311, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 10378, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 10411, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 10483, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 10538, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 10639, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 10703, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 11217, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 11222, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 11365, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 11482, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 11570, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 11691, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 11827, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 11832, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 11875, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 11891, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 11901, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 11981, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 12008, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 12051, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 12056, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 12189, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 12296, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"},
        {fileName: "types.bal", line: 12310, column: 6, message: "redeclared symbol 'action'", errorType: "ERROR"}
        // {
        //     fileName: "types.bal",
        //     line: 3373,
        //     column: 6,
        //     message: "redeclared symbol 'scope'",
        //     errorType: "ERROR"
        // }
        // //        {fileName: "types.bal", line: 3373, column: 6, message: "redeclared symbol 'scope'", errorType: "ERROR"}

    ];

    io:println(string `Processing real compilation error at line ${realError[0].line}: ${realError[0].message}`);

    // Apply fix using the new schema identification approach
    error_registry:BatchFixResult result = check error_registry:applyBatchFixes(realError, specPath);

    // Print results
    io:println(string `Fix Result: ${result.summary}`);
    io:println(string `Overall Success: ${result.overallSuccess}`);
    io:println(string `Fixed ${result.fixedErrors} errors out of ${result.totalErrors}`);
    io:println(string `Failed errors: ${result.failedErrors}`);

    if (result.fixedErrors > 0) {
        io:println("✓ Successfully identified and fixed schema from real compilation error!");
    } else {
        io:println("✗ Could not identify or fix schema - check logs for details");
    }

    // Test should pass regardless - we're testing the approach
    return ();
}

@test:Config {}
function testUndocumentedFieldFix() returns error? {
    io:println("Testing undocumented field fix...");

    // Test with flattened spec path (function will derive aligned spec path internally)
    string specPath = "/home/hansika/dev/openapi-spec-sanitizor/temp-workspace/generated/flattened_openapi.json";

    // Create sample undocumented field errors
    command_executor:CompilationError[] errors = [

    ];

    io:println(string `Processing ${errors.length()} undocumented field warnings...`);

    // Apply batch fixes
    error_registry:BatchFixResult result = check error_registry:applyBatchFixes(errors, specPath);

    // Print results
    io:println(string `Fix Result: ${result.summary}`);
    io:println(string `Overall Success: ${result.overallSuccess}`);
    io:println(string `Fixed ${result.fixedErrors} errors out of ${result.totalErrors}`);
    io:println(string `Failed errors: ${result.failedErrors}`);

    foreach var fixResult in result.individualResults {
        string status = fixResult.success ? "✓" : "✗";
        io:println(string `${status} ${fixResult.fixDescription}`);
        if (!fixResult.success) {
            string? errorMsg = fixResult.errorMessage;
            if (errorMsg is string) {
                io:println(string `   Error: ${errorMsg}`);
            }
        }
    }

    if (result.fixedErrors > 0) {
        io:println("✓ Successfully added documentation to undocumented fields!");
    } else {
        io:println("✗ Could not add documentation - check logs for details");
    }

    return ();
}
