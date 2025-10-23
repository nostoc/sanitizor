import ballerina/io;
import ballerinax/smartsheet;

configurable string authToken = ?;
configurable string callbackUrl = ?;

public function main() returns error? {
    smartsheet:Client smartsheetClient = check new({
        auth: {
            token: authToken
        }
    });

    // Step 1: Create a new workspace for the regulatory team
    smartsheet:WorkspacesBody workspacePayload = {
        name: "Regulatory Compliance Workspace"
    };
    
    smartsheet:CreateWorkspaceHeaders workspaceHeaders = {
        authorization: "Bearer " + authToken,
        contentType: "application/json"
    };
    
    smartsheet:CreateWorkspaceQueries workspaceQueries = {};
    
    smartsheet:WorkspaceResponse workspaceResponse = check smartsheetClient->/workspaces.post(
        workspacePayload, 
        workspaceHeaders, 
        {queries: workspaceQueries}
    );
    
    io:println("Created workspace: ", workspaceResponse);
    
    decimal? workspaceId = workspaceResponse?.result?.id;
    if workspaceId is () {
        return error("Failed to get workspace ID from response");
    }
    
    // Step 2: Create a webhook to capture sheet modifications within the workspace
    smartsheet:CreateWebhookRequest webhookRequest = {
        scopeObjectId: <int>workspaceId,
        scope: "sheet",
        name: "Compliance Audit Webhook",
        callbackUrl: callbackUrl
    };
    
    smartsheet:WebhooksAllOf2 webhooksAllOf2 = {};
    
    smartsheet:WebhooksBody webhookPayload = {
        ...webhookRequest,
        ...webhooksAllOf2
    };
    
    smartsheet:CreateWebhookHeaders webhookHeaders = {
        authorization: "Bearer " + authToken,
        contentType: "application/json"
    };
    
    smartsheet:WorkspaceFolderCreateResponse webhookResponse = check smartsheetClient->/webhooks.post(
        webhookPayload,
        webhookHeaders
    );
    
    io:println("Created webhook: ", webhookResponse);
    
    string? webhookId = webhookResponse?.result?.id?.toString();
    if webhookId is () {
        return error("Failed to get webhook ID from response");
    }
    
    // Step 3: Configure the webhook's shared secret for secure communication
    smartsheet:ResetSharedSecretHeaders secretHeaders = {
        authorization: "Bearer " + authToken,
        contentType: "application/json"
    };
    
    smartsheet:WorkspaceShareCreateResponse secretResponse = check smartsheetClient->/webhooks/[webhookId]/resetSharedSecret.post(
        secretHeaders
    );
    
    io:println("Configured webhook shared secret: ", secretResponse);
    
    io:println("Compliance monitoring setup completed successfully!");
    io:println("Workspace ID: ", workspaceId);
    io:println("Webhook ID: ", webhookId);
    io:println("Shared Secret: ", secretResponse?.result?.sharedSecret);
}