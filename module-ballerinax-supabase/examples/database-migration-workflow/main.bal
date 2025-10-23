import ballerina/io;
import ballerina/http;

configurable string apiKey = ?;
configurable string projectRef = ?;

public function main() returns error? {
    http:Client ballerinaClient = check new ("https://api.ballerina.io", {
        auth: {
            token: apiKey
        }
    });

    // Step 1: Create a new feature branch from the main branch
    io:println("Creating feature branch for database migration...");
    map<json> createBranchPayload = {
        "branchName": "feature/database-migration-v2"
    };
    
    http:Response branchResponse = check ballerinaClient->post("/v1/projects/" + projectRef + "/branches", createBranchPayload);
    json branchData = check branchResponse.getJsonPayload();
    io:println("Feature branch created successfully:");
    io:println("Branch Name: " + (check branchData.gitBranch).toString());
    io:println("Created At: " + (check branchData.createdAt).toString());
    io:println("Is Default: " + (check branchData.isDefault).toString());

    // Step 2: Push local changes to the remote feature branch
    io:println("\nPushing local changes to remote feature branch...");
    map<json> pushPayload = {
        "migrationVersion": "v2.1.0"
    };
    
    http:Response pushResponse = check ballerinaClient->post("/v1/branches/feature/database-migration-v2/push", pushPayload);
    json pushData = check pushResponse.getJsonPayload();
    io:println("Changes pushed successfully:");
    io:println("Status: " + (check pushData.message).toString());
    io:println("Workflow Run ID: " + (check pushData.workflowRunId).toString());

    // Step 3: Merge the feature branch back into the main branch
    io:println("\nMerging feature branch into main branch...");
    map<json> mergePayload = {
        "migrationVersion": "v2.1.0"
    };
    
    http:Response mergeResponse = check ballerinaClient->post("/v1/branches/feature/database-migration-v2/merge", mergePayload);
    json mergeData = check mergeResponse.getJsonPayload();
    io:println("Feature branch merged successfully:");
    io:println("Status: " + (check mergeData.message).toString());
    io:println("Workflow Run ID: " + (check mergeData.workflowRunId).toString());

    io:println("\nDatabase migration workflow completed successfully!");
}