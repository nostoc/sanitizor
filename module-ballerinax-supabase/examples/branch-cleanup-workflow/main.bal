import ballerina/io;
import ballerina/http;

configurable string accessToken = ?;
configurable string projectRef = ?;
configurable string branchRef = ?;

type BranchDetailResponse record {
    string ref;
    string postgresVersion;
    string postgresEngine;
    string? jwtSecret;
};

type V1DiffABranchQueries record {
};

type BranchDeleteResponse record {
    string message;
};

public function main() returns error? {
    http:Client ballerinaClient = check new("https://api.ballerina.io", {
        auth: {
            token: accessToken
        }
    });

    io:println("=== Branch Cleanup Workflow ===");
    io:println("1. Retrieving detailed branch information...");
    
    BranchDetailResponse branchDetails = check ballerinaClient->/v1/branches/[branchRef]();
    
    io:println("Branch Details:");
    io:println("- Reference: " + branchDetails.ref);
    io:println("- PostgreSQL Version: " + branchDetails.postgresVersion);
    io:println("- PostgreSQL Engine: " + branchDetails.postgresEngine);
    if (branchDetails.jwtSecret is string) {
        io:println("- JWT Secret configured: Yes");
    }
    
    io:println("\n2. Examining differences between branch and main...");
    
    string branchDiff = check ballerinaClient->/v1/branches/[branchRef]/diff();
    
    io:println("Branch Differences:");
    io:println(branchDiff);
    
    io:println("\n3. Proceeding with branch deletion...");
    
    BranchDeleteResponse deleteResponse = check ballerinaClient->/v1/branches/[branchRef].delete();
    
    io:println("Branch Deletion Result:");
    io:println("- Status: " + deleteResponse.message);
    
    io:println("\n=== Branch cleanup workflow completed successfully ===");
}