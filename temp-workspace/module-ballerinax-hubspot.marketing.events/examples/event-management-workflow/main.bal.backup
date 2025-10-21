import ballerina/io;
import ballerinax/hubspot.marketing.events;

configurable string accessToken = ?;

public function main() returns error? {
    events:Client hubspotClient = check new ({
        auth: {
            token: accessToken
        }
    });

    string externalEventId = "marketing-workshop-2024";
    string externalAccountId = "company-123";
    
    io:println("Step 1: Creating marketing event subscriber records for registered contacts");
    
    events:MarketingEventSubscriber[] registeredContacts = [
        {
            vid: 12345,
            interactionDateTime: 1703001600000,
            properties: {"registration_source": "website"}
        },
        {
            vid: 67890,
            interactionDateTime: 1703002200000,
            properties: {"registration_source": "email"}
        }
    ];

    events:BatchInputMarketingEventSubscriber registeredPayload = {
        inputs: registeredContacts
    };

    var registeredResult = hubspotClient->postAttendanceExternalEventIdSubscriberStateCreate(
        externalEventId, 
        "registered", 
        registeredPayload
    );
    
    if registeredResult is error {
        io:println("Error creating registered subscriber records: " + registeredResult.message());
        return registeredResult;
    } else {
        io:println("Successfully created registered subscriber records");
    }

    io:println("Step 2: Getting event associations with contact lists");
    
    var associationsResult = hubspotClient->getAssociationsExternalAccountIdExternalEventIdGet(
        externalAccountId,
        externalEventId
    );
    
    if associationsResult is error {
        io:println("Error retrieving event associations: " + associationsResult.message());
        return associationsResult;
    } else {
        io:println("Successfully retrieved event associations with contact lists");
    }

    io:println("Step 3: Creating attendance records for contacts who attended");
    
    events:MarketingEventSubscriber[] attendedContacts = [
        {
            vid: 12345,
            interactionDateTime: 1703088000000,
            properties: {"attendance_duration": "120", "feedback_score": "5"}
        },
        {
            vid: 67890,
            interactionDateTime: 1703088300000,
            properties: {"attendance_duration": "90", "feedback_score": "4"}
        }
    ];

    events:BatchInputMarketingEventSubscriber attendedPayload = {
        inputs: attendedContacts
    };

    var attendedResult = hubspotClient->postAttendanceExternalEventIdSubscriberStateCreate(
        externalEventId,
        "attended",
        attendedPayload
    );
    
    if attendedResult is error {
        io:println("Error creating attended subscriber records: " + attendedResult.message());
        return attendedResult;
    } else {
        io:println("Successfully created attended subscriber records");
    }

    io:println("Event management workflow completed successfully!");
    io:println("- Created registration records for target audience");
    io:println("- Retrieved event-list associations");
    io:println("- Tracked attendance for engagement measurement");
}