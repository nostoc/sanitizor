import ballerina/test;
import ballerina/lang.regexp;
import example_generator.analyzer;

// Sample client content for testing
final string sampleClientContent = string `
public isolated client class Client {
    
    resource isolated function get advisories(string? before = (), string? after = (), int? per_page = (), 
                                             string? direction = (), string? sort = (), string? severity = ()) 
                                             returns Advisory[]|error {
        // implementation
    }
    
    resource isolated function get [string org]/secret\-scanning/alerts(int? per_page = (), int? page = ()) 
                                   returns SecretScanningAlert[]|error {
        // implementation
    }
    
    resource isolated function get advisories/[string ghsa_id]() returns Advisory|error {
        // implementation
    }
    
    remote isolated function createRepository(CreateRepoRequest request) returns Repository|error {
        // implementation
    }
    
    remote isolated function deleteRepository(string owner, string repo) returns error? {
        // implementation
    }
}
`;

// Test extractFunctionSignatures function
@test:Config {}
function testExtractFunctionSignatures() {
    string signatures = analyzer:extractFunctionSignatures(sampleClientContent);
    
    // Verify that all expected function types are extracted
    test:assertTrue(signatures.includes("resource isolated function get advisories"), 
                   "Should extract resource function for advisories");
    test:assertTrue(signatures.includes("resource isolated function get [string org]/secret\\-scanning/alerts"), 
                   "Should extract resource function for secret scanning");
    test:assertTrue(signatures.includes("resource isolated function get advisories/[string ghsa_id]"), 
                   "Should extract resource function for specific advisory");
    test:assertTrue(signatures.includes("remote isolated function createRepository"), 
                   "Should extract remote function for createRepository");
    test:assertTrue(signatures.includes("remote isolated function deleteRepository"), 
                   "Should extract remote function for deleteRepository");
    
    // Verify clean formatting (single spaces, no extra whitespace)
    string[] lines = regexp:split(re `\n\n`, signatures);
    foreach string line in lines {
        if line.trim().length() > 0 {
            test:assertFalse(line.includes("  "), "Should not have double spaces: " + line);
            test:assertFalse(line.startsWith(" "), "Should not start with space: " + line);
            test:assertFalse(line.endsWith(" "), "Should not end with space: " + line);
        }
    }
}

// Test isMatchingFunction with various scenarios
@test:Config {}
function testIsMatchingFunctionPositiveCases() {
    string advisoryFuncDef = "resource isolated function get advisories(string? before = ()) returns Advisory[]|error";
    string secretScanningFuncDef = "resource isolated function get [string org]/secret-scanning/alerts() returns SecretScanningAlert[]|error";
    string specificAdvisoryFuncDef = "resource isolated function get advisories/[string ghsa_id]() returns Advisory|error";
    string createRepoFuncDef = "remote isolated function createRepository(CreateRepoRequest request) returns Repository|error";
    
    // Test positive matches
    test:assertTrue(analyzer:isMatchingFunction(advisoryFuncDef, "get advisories"), 
                   "Should match 'get advisories'");
    test:assertTrue(analyzer:isMatchingFunction(secretScanningFuncDef, "get scanning alerts"), 
                   "Should match 'get scanning alerts'");
    test:assertTrue(analyzer:isMatchingFunction(secretScanningFuncDef, "secret scanning"), 
                   "Should match 'secret scanning'");
    test:assertTrue(analyzer:isMatchingFunction(specificAdvisoryFuncDef, "get advisory details"), 
                   "Should match 'get advisory details'");
    test:assertTrue(analyzer:isMatchingFunction(createRepoFuncDef, "create repository"), 
                   "Should match 'create repository'");
    test:assertTrue(analyzer:isMatchingFunction(createRepoFuncDef, "createRepository"), 
                   "Should match exact function name");
}

@test:Config {}
function testIsMatchingFunctionNegativeCases() {
    string advisoryFuncDef = "resource isolated function get advisories(string? before = ()) returns Advisory[]|error";
    string createRepoFuncDef = "remote isolated function createRepository(CreateRepoRequest request) returns Repository|error";
    
    // Test negative matches
    test:assertFalse(analyzer:isMatchingFunction(advisoryFuncDef, "delete advisories"), 
                    "Should not match 'delete advisories'");
    test:assertFalse(analyzer:isMatchingFunction(advisoryFuncDef, "get users"), 
                    "Should not match 'get users'");
    test:assertFalse(analyzer:isMatchingFunction(createRepoFuncDef, "delete repository"), 
                    "Should not match 'delete repository'");
    test:assertFalse(analyzer:isMatchingFunction(advisoryFuncDef, "xyz abc def"), 
                    "Should not match completely unrelated terms");
}

@test:Config {}
function testIsMatchingFunctionEdgeCases() {
    string funcDef = "resource isolated function get advisories(string? before = ()) returns Advisory[]|error";
    
    // Test edge cases
    test:assertFalse(analyzer:isMatchingFunction(funcDef, ""), 
                    "Should not match empty string");
    test:assertFalse(analyzer:isMatchingFunction(funcDef, "a b"), 
                    "Should not match very short keywords");
    test:assertTrue(analyzer:isMatchingFunction(funcDef, "get"), 
                   "Should match single meaningful keyword");
    test:assertTrue(analyzer:isMatchingFunction(funcDef, "advisories"), 
                   "Should match single meaningful keyword");
}

// Test findMatchingFunction with different scenarios
@test:Config {}
function testFindMatchingFunctionSuccess() {
    // Test successful matches
    string? result1 = analyzer:findMatchingFunction(sampleClientContent, "get advisories");
    test:assertTrue(result1 is string, "Should find matching function for 'get advisories'");
    if result1 is string {
        test:assertTrue(result1.includes("get advisories"), "Result should contain the matched function");
    }
    
    string? result2 = analyzer:findMatchingFunction(sampleClientContent, "secret scanning");
    test:assertTrue(result2 is string, "Should find matching function for 'secret scanning'");
    if result2 is string {
        test:assertTrue(result2.includes("secret-scanning"), "Result should contain secret-scanning function");
    }
    
    string? result3 = analyzer:findMatchingFunction(sampleClientContent, "create repository");
    test:assertTrue(result3 is string, "Should find matching function for 'create repository'");
    if result3 is string {
        test:assertTrue(result3.includes("createRepository"), "Result should contain createRepository function");
    }
}

@test:Config {}
function testFindMatchingFunctionNoMatch() {
    // Test cases where no match should be found
    string? result1 = analyzer:findMatchingFunction(sampleClientContent, "delete advisories");
    test:assertTrue(result1 is (), "Should not find match for 'delete advisories'");
    
    string? result2 = analyzer:findMatchingFunction(sampleClientContent, "get users");
    test:assertTrue(result2 is (), "Should not find match for 'get users'");
    
    string? result3 = analyzer:findMatchingFunction(sampleClientContent, "completely unrelated function");
    test:assertTrue(result3 is (), "Should not find match for completely unrelated terms");
}

@test:Config {}
function testFindMatchingFunctionEdgeCases() {
    // Test edge cases
    string? result1 = analyzer:findMatchingFunction("", "get advisories");
    test:assertTrue(result1 is (), "Should return null for empty client content");
    
    string? result2 = analyzer:findMatchingFunction(sampleClientContent, "");
    test:assertTrue(result2 is (), "Should return null for empty search term");
    
    string? result3 = analyzer:findMatchingFunction("no functions here", "get advisories");
    test:assertTrue(result3 is (), "Should return null when no functions exist in content");
}

// Test integration scenario
@test:Config {}
function testExtractTargetedContextIntegration() {
    // Create a mock ConnectorDetails for testing
    analyzer:ConnectorDetails details = {
        connectorName: "github",
        apiCount: 5,
        clientBalContent: sampleClientContent,
        typesBalContent: "public type Advisory record { string id; };",
        functionSignatures: "",
        typeNames: ""
    };
    
    string[] functionNames = ["get advisories", "secret scanning"];
    string|error result = analyzer:extractTargetedContext(details, functionNames);
    
    test:assertTrue(result is string, "Should successfully extract targeted context");
    if result is string {
        test:assertTrue(result.includes("get advisories"), "Should include advisories function");
        test:assertTrue(result.includes("secret-scanning") || result.includes("scanning"), 
                      "Should include secret scanning related function");
    }
}