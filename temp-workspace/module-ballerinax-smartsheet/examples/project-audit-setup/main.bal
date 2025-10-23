import ballerina/io;
import ballerinax/smartsheet;

configurable string accessToken = ?;
configurable string callbackUrl = ?;

public function main() returns error? {
    smartsheet:Client smartsheetClient = check new ({
        auth: {
            token: accessToken
        }
    });

    // Step 1: Create a dedicated workspace for the project
    smartsheet:WorkspacesBody workspacePayload = {
        name: "Project Audit Trail Workspace"
    };

    smartsheet:CreateWorkspaceHeaders workspaceHeaders = {
        authorization: "Bearer " + accessToken,
        contentType: "application/json"
    };

    smartsheet:CreateWorkspaceQueries workspaceQueries = {
        accessApiLevel: 0
    };

    smartsheet:WorkspaceResponse workspaceResponse = check smartsheetClient->/workspaces.post(workspacePayload, workspaceHeaders, {"queries": workspaceQueries});
    io:println("Created workspace: ", workspaceResponse);

    decimal? workspaceId = workspaceResponse.result?.id;
    if workspaceId is () {
        return error("Failed to get workspace ID from response");
    }

    // Step 2: Set up automated webhook notifications
    smartsheet:WebhooksBody webhookPayload = {
        name: "Project Audit Webhook",
        callbackUrl: callbackUrl,
        scope: "sheet",
        scopeObjectId: <int>workspaceId
    };

    smartsheet:CreateWebhookHeaders webhookHeaders = {
        authorization: "Bearer " + accessToken,
        contentType: "application/json"
    };

    smartsheet:WorkspaceFolderCreateResponse webhookResponse = check smartsheetClient->/webhooks.post(webhookPayload, webhookHeaders);
    io:println("Created webhook: ", webhookResponse);

    // Get webhook ID from response
    string webhookId = "";
    if webhookResponse.result is smartsheet:Webhook {
        decimal? id = webhookResponse.result?.id;
        if id is decimal {
            webhookId = id.toString();
        }
    }

    if webhookId == "" {
        return error("Failed to get webhook ID from response");
    }

    // Step 3: Configure webhook with secure shared secret
    smartsheet:ResetSharedSecretHeaders secretHeaders = {
        authorization: "Bearer " + accessToken,
        contentType: "application/json"
    };

    smartsheet:WorkspaceShareCreateResponse secretResponse = check smartsheetClient->/webhooks/[webhookId]/resetSharedSecret.post(secretHeaders);
    io:println("Configured shared secret: ", secretResponse);

    io:println("Project audit trail setup completed successfully!");
    io:println("- Workspace ID: ", workspaceId);
    io:println("- Webhook ID: ", webhookId);
    io:println("- Shared secret configured for data integrity");
}