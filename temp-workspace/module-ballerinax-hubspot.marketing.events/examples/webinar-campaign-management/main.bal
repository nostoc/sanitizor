import ballerina/io;
import ballerinax/hubspot.marketing.events;

configurable string accessToken = ?;

public function main() returns error? {
    
    events:Client hubspotClient = check new ({
        auth: {
            token: accessToken
        }
    });

    string externalEventId = "webinar-2024-001";
    string externalAccountId = "account-123";
    
    io:println("Step 1: Marketing event creation (assuming event already exists with ID: " + externalEventId + ")");
    
    io:println("Step 2: Getting event associations with contact lists");
    var associationsResult = hubspotClient->getMarketingEventAssociations(
        externalEventId,
        externalAccountId
    );
    if associationsResult is error {
        io:println("Error getting associations: " + associationsResult.message());
    } else {
        io:println("Successfully retrieved event associations");
        io:println(associationsResult.toString());
    }
    
    io:println("Step 3: Recording attendance by adding subscriber records");
    
    events:MarketingEventSubscriber[] subscribers = [
        {
            vid: 12345,
            interactionDateTime: 1703097600000,
            properties: {
                "attendance_status": "attended",
                "engagement_score": "high"
            }
        },
        {
            vid: 67890,
            interactionDateTime: 1703097600000,
            properties: {
                "attendance_status": "attended",
                "engagement_score": "medium"
            }
        }
    ];
    
    events:BatchInputMarketingEventSubscriber batchInput = {
        inputs: subscribers
    };
    
    string subscriberState = "attended";
    
    var attendanceResult = hubspotClient->createMarketingEventAttendance(
        externalEventId,
        subscriberState,
        batchInput,
        externalAccountId
    );
    
    if attendanceResult is error {
        io:println("Error recording attendance: " + attendanceResult.message());
    } else {
        io:println("Successfully recorded attendance for webinar participants");
        io:println("Number of contacts processed: " + subscribers.length().toString());
        io:println("Event ID: " + externalEventId);
        io:println("Subscriber State: " + subscriberState);
    }
    
    io:println("Webinar campaign setup completed successfully!");
}