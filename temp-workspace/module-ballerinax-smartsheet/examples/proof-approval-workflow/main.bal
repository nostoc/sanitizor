import ballerina/io;
import ballerina/http;

configurable string accessToken = ?;

public function main() returns error? {
    http:Client smartsheetClient = check new ("https://api.smartsheet.com/2.0", {
        auth: {
            token: accessToken
        }
    });

    decimal sheetId = 123456789;
    string proofId = "proof-123";

    map<string> getAllHeaders = {
        "Authorization": "Bearer " + accessToken
    };

    map<string|int|boolean> getAllQueries = {
        "pageSize": 100,
        "includeAll": false,
        "page": 1
    };

    io:println("Step 1: Retrieving all existing proofs for the sheet...");
    http:Response allProofsResponse = check smartsheetClient->get(string `/sheets/${sheetId}/proofs`, getAllHeaders);
    json allProofs = check allProofsResponse.getJsonPayload();
    io:println("Retrieved proofs: ", allProofs);

    json requestBody = {
        "sendTo": [
            {
                "email": "stakeholder1@example.com"
            },
            {
                "email": "stakeholder2@example.com"
            }
        ],
        "ccMe": true,
        "subject": "Design Approval Required - Please Review",
        "message": "Please review and approve the attached design proof. Your feedback is needed by end of week."
    };

    map<string> createHeaders = {
        "Authorization": "Bearer " + accessToken,
        "Content-Type": "application/json"
    };

    io:println("Step 2: Creating a new proof request for stakeholder review...");
    http:Response proofRequestResponse = check smartsheetClient->post(string `/sheets/${sheetId}/proofs/${proofId}/requests`, requestBody, createHeaders);
    json proofRequest = check proofRequestResponse.getJsonPayload();
    io:println("Created proof request: ", proofRequest);

    json statusUpdate = {
        "isCompleted": false
    };

    map<string> updateHeaders = {
        "Authorization": "Bearer " + accessToken
    };

    io:println("Step 3: Updating proof status to reflect current approval state...");
    http:Response updatedProofResponse = check smartsheetClient->put(string `/sheets/${sheetId}/proofs/${proofId}`, statusUpdate, updateHeaders);
    json updatedProof = check updatedProofResponse.getJsonPayload();
    io:println("Updated proof status: ", updatedProof);

    io:println("Proof review workflow completed successfully!");
}