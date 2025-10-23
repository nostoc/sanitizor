import ballerina/io;
import ballerina/http;

configurable string supabaseUrl = ?;
configurable string supabaseKey = ?;
configurable string projectRef = ?;

public function main() returns error? {
    http:Client supabaseClient = check new (supabaseUrl,
        {
            auth: {
                token: supabaseKey
            }
        }
    );

    // Step 1: Create a new feature branch from main branch
    io:println("Creating feature branch...");
    map<json> createBranchPayload = {
        "branchName": "feature-branch"
    };
    
    http:Response branchResponse = check supabaseClient->/v1/projects/[projectRef]/branches.post(createBranchPayload);
    io:println("Branch created successfully:");
    io:println(branchResponse);

    // Step 2: Get diff between feature branch and main branch
    io:println("\nRetrieving diff between feature branch and main branch...");
    http:Response diffResult = check supabaseClient->/v1/branches/["feature-branch"]/diff();
    io:println("Diff result:");
    io:println(diffResult);

    // Step 3: Merge feature branch back into main branch
    io:println("\nMerging feature branch into main branch...");
    map<json> mergePayload = {};
    
    http:Response mergeResponse = check supabaseClient->/v1/branches/["feature-branch"]/merge.post(mergePayload);
    io:println("Merge completed successfully:");
    io:println(mergeResponse);
}