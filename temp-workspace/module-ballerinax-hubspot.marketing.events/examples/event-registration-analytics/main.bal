import ballerina/io;
import ballerinax/hubspot.marketing.events;

configurable string accessToken = ?;

public function main() returns error? {
    events:Client hubspotClient = check new({
        auth: {
            token: accessToken
        }
    });

    io:println("Starting marketing event management process...");

    string externalEventId = "marketing-event-2024-001";
    int marketingEventId = 123456789;

    io:println("Step 1: Creating marketing event (assuming event is already created with ID: " + externalEventId + ")");

    io:println("Step 2: Registering attendees for the event...");

    events:MarketingEventSubscriber[] subscribers = [
        {
            vid: 101,
            interactionDateTime: 1704067200000,
            properties: {"email": "attendee1@example.com", "firstname": "John", "lastname": "Doe"}
        },
        {
            vid: 102,
            interactionDateTime: 1704067260000,
            properties: {"email": "attendee2@example.com", "firstname": "Jane", "lastname": "Smith"}
        },
        {
            vid: 103,
            interactionDateTime: 1704067320000,
            properties: {"email": "attendee3@example.com", "firstname": "Mike", "lastname": "Johnson"}
        }
    ];

    events:BatchInputMarketingEventSubscriber batchInput = {
        inputs: subscribers
    };

    var registrationResult = hubspotClient->/marketing\-events/[externalEventId]/attendance\-subscribers/registered.post(
        batchInput
    );

    if (registrationResult is error) {
        io:println("Error registering attendees: " + registrationResult.message());
        return registrationResult;
    }

    io:println("Successfully registered " + subscribers.length().toString() + " attendees for the event");

    io:println("Step 3: Retrieving participation breakdown data...");

    var participationResult = hubspotClient->/marketing\-events/[marketingEventId.toString()]/participation\-breakdown.get();

    if (participationResult is error) {
        io:println("Error retrieving participation data: " + participationResult.message());
        return participationResult;
    }

    io:println("Successfully retrieved participation breakdown data");
    io:println("Participation metrics: " + participationResult.toString());

    io:println("Marketing event management process completed successfully!");
}