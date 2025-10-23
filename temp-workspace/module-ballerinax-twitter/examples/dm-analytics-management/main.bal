import ballerina/io;
import ballerinax/twitter;

configurable string consumerKey = ?;
configurable string consumerSecret = ?;
configurable string accessToken = ?;
configurable string accessTokenSecret = ?;

public function main() returns error? {
    twitter:Client twitterClient = check new ({
        auth: {
            token: accessToken
        }
    });

    string conversationId = "conversation123";
    
    io:println("Step 1: Retrieving DM events for conversation analysis...");
    twitter:Get2DmConversationsIdDmEventsResponse dmEventsResponse = check twitterClient->/dm_conversations/[conversationId]/dm_events({
        dmEventFields: ["id", "text", "created_at", "sender_id", "event_type"],
        userFields: ["id", "username", "name"]
    });
    
    io:println("DM Events Response:");
    io:println(dmEventsResponse);
    
    string highEngagementEventId = "event456";
    
    io:println("Step 2: Fetching detailed information about high engagement DM event...");
    twitter:Get2DmEventsEventIdResponse dmEventDetailResponse = check twitterClient->/dm_events/[highEngagementEventId]({
        dmEventFields: ["id", "text", "created_at", "sender_id", "event_type", "attachments", "entities"],
        userFields: ["id", "username", "name", "public_metrics"],
        tweetFields: ["id", "text", "public_metrics", "created_at"]
    });
    
    io:println("Detailed DM Event Response:");
    io:println(dmEventDetailResponse);
    
    string outdatedEventId = "event789";
    
    io:println("Step 3: Deleting outdated DM event for conversation quality maintenance...");
    twitter:DeleteDmResponse deleteResponse = check twitterClient->/dm_events/[outdatedEventId].delete();
    
    io:println("Delete DM Event Response:");
    io:println(deleteResponse);
    
    io:println("Direct messaging analytics feature implementation completed successfully!");
}