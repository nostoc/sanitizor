import ballerina/io;
import ballerinax/smartsheet;

configurable string accessToken = ?;

public function main() returns error? {
    smartsheet:Client smartsheetClient = check new ({
        auth: {
            token: accessToken
        }
    });

    // Step 1: Retrieve all available dashboards to check for existing templates
    io:println("Step 1: Retrieving all available dashboards...");
    
    smartsheet:ListSightsHeaders listHeaders = {
        authorization: "Bearer " + accessToken
    };
    
    smartsheet:ListSightsQueries listQueries = {
        includeAll: true,
        pageSize: 100
    };
    
    smartsheet:DashboardListResponse dashboardList = check smartsheetClient->/sights.get(listHeaders, {"queries": listQueries});
    
    io:println("Retrieved dashboards:");
    if (dashboardList.data is smartsheet:SightListItem[]) {
        smartsheet:SightListItem[] dashboards = <smartsheet:SightListItem[]>dashboardList.data;
        foreach smartsheet:SightListItem dashboard in dashboards {
            string dashboardId = dashboard["id"] is int ? dashboard["id"].toString() : "N/A";
            string dashboardName = dashboard["name"] ?: "N/A";
            io:println("Dashboard ID: " + dashboardId + ", Name: " + dashboardName);
        }
    }

    // Step 2: Create/Update a dashboard (sight) with specific project widgets
    io:println("\nStep 2: Creating/Updating a dashboard with project widgets...");
    
    string sightId = "123456789"; // Replace with actual sight ID
    
    smartsheet:SightName sightPayload = {
        name: "Project Management Dashboard"
    };
    
    smartsheet:UpdateSightHeaders updateHeaders = {
        authorization: "Bearer " + accessToken,
        contentType: "application/json"
    };
    
    smartsheet:UpdateSightQueries updateQueries = {
        numericDates: false
    };
    
    smartsheet:ShareResponse updateResponse = check smartsheetClient->/sights/[sightId].put(sightPayload, updateHeaders, {"queries": updateQueries});
    
    io:println("Dashboard update response:");
    int? resultCode = updateResponse.resultCode;
    string resultCodeStr = resultCode is int ? resultCode.toString() : "N/A";
    io:println("Result code: " + resultCodeStr);
    io:println("Message: " + (updateResponse.message ?: "N/A"));

    // Step 3: Configure sharing permissions for team collaboration
    io:println("\nStep 3: Configuring sharing permissions for team collaboration...");
    
    smartsheet:Share sharePayload = {
        email: "team.member@company.com",
        accessLevel: "EDITOR"
    };
    
    smartsheet:ShareSightHeaders shareHeaders = {
        authorization: "Bearer " + accessToken
    };
    
    smartsheet:ShareSightQueries shareQueries = {
        accessApiLevel: 1,
        sendEmail: true
    };
    
    smartsheet:TokenResponse shareResponse = check smartsheetClient->/sights/[sightId]/shares.post(sharePayload, shareHeaders, {"queries": shareQueries});
    
    io:println("Share configuration response:");
    int? shareResultCode = shareResponse.resultCode;
    string shareResultCodeStr = shareResultCode is int ? shareResultCode.toString() : "N/A";
    io:println("Result code: " + shareResultCodeStr);
    io:println("Message: " + (shareResponse.message ?: "N/A"));
    
    io:println("\nProject management dashboard setup completed successfully!");
}