import ballerina/io;
import ballerinax/smartsheet;

configurable string accessToken = ?;
configurable decimal sheetId = ?;

public function main() returns error? {
    smartsheet:Client smartsheetClient = check new ({
        auth: {
            token: accessToken
        }
    });

    io:println("=== COMPREHENSIVE AUDIT TRAIL SYSTEM ===");
    io:println();

    // Step 1: Retrieve all automation rules across sheets
    io:println("Step 1: Retrieving automation rules for compliance workflows...");
    
    smartsheet:AutomationrulesListHeaders automationHeaders = {
        authorization: "Bearer " + accessToken
    };
    
    smartsheet:AutomationrulesListQueries automationQueries = {
        includeAll: true,
        pageSize: 100
    };
    
    smartsheet:AutomationRuleListResponse automationRules = check smartsheetClient->/sheets/[sheetId]/automationrules(automationHeaders, {queries: automationQueries});
    
    io:println("Found automation rules:");
    if automationRules.data is smartsheet:AutomationRule[] {
        smartsheet:AutomationRule[] rules = automationRules.data ?: [];
        foreach smartsheet:AutomationRule rule in rules {
            io:println("- Automation Rule Created: " + (rule.createdAt is smartsheet:Timestamp ? rule.createdAt.toString() : "N/A"));
        }
    }
    io:println("Total automation rules retrieved: " + (automationRules.totalCount is decimal ? automationRules.totalCount.toString() : "0"));
    io:println();

    // Step 2: Fetch complete event stream for analysis
    io:println("Step 2: Fetching complete event stream for user activities and data changes...");
    
    smartsheet:ListEventsHeaders eventHeaders = {
        authorization: "Bearer " + accessToken,
        acceptEncoding: "gzip"
    };
    
    smartsheet:ListEventsQueries eventQueries = {
        streamPosition: "0"
    };
    
    smartsheet:EventStreamResponse eventStream = check smartsheetClient->/events(eventHeaders, {queries: eventQueries});
    
    io:println("Event stream analysis:");
    io:println("More events available: " + (eventStream.moreAvailable is boolean ? eventStream.moreAvailable.toString() : "false"));
    string nextPosition = eventStream.nextStreamPosition ?: "N/A";
    io:println("Next stream position: " + nextPosition);
    
    if eventStream.data is smartsheet:EventUnionData[] {
        smartsheet:EventUnionData[] events = eventStream.data ?: [];
        io:println("Total events in stream: " + events.length().toString());
        foreach smartsheet:EventUnionData event in events {
            if event is smartsheet:DashboardRename {
                string action = event.action ?: "N/A";
                io:println("- Dashboard Rename Event - Action: " + action);
            }
        }
    }
    io:println();

    // Step 3: Apply advanced filtering for compliance-related activities
    io:println("Step 3: Applying advanced filtering for compliance and security incidents...");
    
    smartsheet:FilteredEventsRequest filterRequest = {
        streamPosition: eventStream.nextStreamPosition ?: "0",
        sheetIds: [sheetId.toString()]
    };
    
    smartsheet:ListFilteredEventsHeaders filterHeaders = {
        authorization: "Bearer " + accessToken,
        acceptEncoding: "gzip"
    };
    
    smartsheet:EventFilterResponse filteredEvents = check smartsheetClient->/events/filter(filterRequest, filterHeaders);
    
    io:println("Filtered events for compliance analysis:");
    io:println("More events available: " + (filteredEvents.moreAvailable is boolean ? filteredEvents.moreAvailable.toString() : "false"));
    string nextFilterPosition = filteredEvents.nextStreamPosition ?: "N/A";
    io:println("Next stream position: " + nextFilterPosition);
    
    if filteredEvents.data is smartsheet:Event[] {
        smartsheet:Event[] events = filteredEvents.data ?: [];
        io:println("Compliance-related events found: " + events.length().toString());
        foreach smartsheet:Event event in events {
            io:println("- Event detected for regulatory documentation");
        }
    }
    
    if filteredEvents.unavailableSheetIds is string[] {
        string[] unavailableSheets = filteredEvents.unavailableSheetIds ?: [];
        int unavailableSheetCount = unavailableSheets.length();
        if unavailableSheetCount > 0 {
            io:println("Unavailable sheet IDs: " + filteredEvents.unavailableSheetIds.toString());
        }
    }
    
    if filteredEvents.unavailableWorkspaceIds is string[] {
        string[] unavailableWorkspaces = filteredEvents.unavailableWorkspaceIds ?: [];
        int unavailableWorkspaceCount = unavailableWorkspaces.length();
        if unavailableWorkspaceCount > 0 {
            io:println("Unavailable workspace IDs: " + filteredEvents.unavailableWorkspaceIds.toString());
        }
    }
    
    io:println();
    io:println("=== AUDIT TRAIL SYSTEM IMPLEMENTATION COMPLETE ===");
    io:println("Comprehensive audit data retrieved and filtered for compliance analysis");
}