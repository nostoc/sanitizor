import ballerina/io;
import ballerinax/slack;

configurable string token = ?;

public function main() returns error? {
    slack:ConnectionConfig config = {
        auth: {
            token: token
        }
    };
    
    slack:Client slackClient = check new(config);
    
    io:println("Step 1: Creating a new public channel for team onboarding...");
    
    slack:ConversationsCreateBody createChannelRequest = {
        name: "team-onboarding",
        is_private: false
    };
    
    slack:ConversationsCreateResponse createResponse = check slackClient->/conversations\.create.post(createChannelRequest);
    string channelId = createResponse.channel.id;
    io:println("Channel created successfully: " + channelId);
    
    io:println("Step 2: Posting a welcome message to the channel...");
    
    slack:ChatPostMessageBody messageRequest = {
        channel: channelId,
        text: "Welcome to the team! 🎉\n\nHere are some essential resources to get you started:\n\n• Employee Handbook: [Link]\n• Team Directory: [Link]\n• IT Setup Guide: [Link]\n• HR Policies: [Link]\n• Project Management Tools: [Link]\n\nFeel free to ask questions here - we're here to help!"
    };
    
    slack:ChatPostMessageResponse messageResponse = check slackClient->/chat\.postMessage.post(messageRequest);
    string messageTimestamp = messageResponse.ts;
    io:println("Welcome message posted successfully: " + messageTimestamp);
    
    io:println("Step 3: Pinning the welcome message for permanent visibility...");
    
    slack:PinsAddBody pinRequest = {
        channel: channelId,
        timestamp: messageTimestamp
    };
    
    slack:PinsAddResponse pinResponse = check slackClient->/pins\.add.post(pinRequest);
    io:println("Message pinned successfully!");
    
    io:println("Team onboarding bot workflow completed successfully! ✅");
    io:println("Channel: " + channelId);
    io:println("Message: " + messageTimestamp);
}