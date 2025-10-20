import ballerina/io;
import ballerinax/slack;

configurable string token = ?;
configurable string channelName = ?;
configurable string userIds = ?;
configurable string welcomeMessage = ?;

public function main() returns error? {
    slack:ConnectionConfig config = {
        auth: {
            token: token
        }
    };
    
    slack:Client slackClient = check new (config);
    
    io:println("Starting team onboarding workflow...");
    
    io:println("Step 1: Creating new channel...");
    slack:ConversationsCreateResponse createResponse = check slackClient->/conversations\.create.post({
        name: channelName,
        is_private: false
    });
    
    if createResponse.ok {
        string channelId = createResponse.channel.id;
        io:println(string `Channel created successfully: ${channelId}`);
        
        io:println("Step 2: Inviting team members to the channel...");
        slack:ConversationsInviteErrorResponse inviteResponse = check slackClient->/conversations\.invite.post({
            channel: channelId,
            users: userIds
        });
        
        if inviteResponse.ok {
            io:println("Team members invited successfully");
            
            io:println("Step 3: Posting welcome message...");
            slack:ChatPostMessageResponse messageResponse = check slackClient->/chat\.postMessage.post({
                channel: channelId,
                text: welcomeMessage
            });
            
            if messageResponse.ok {
                io:println(string `Welcome message posted successfully at ${messageResponse.ts}`);
                io:println("Team onboarding workflow completed successfully!");
            } else {
                io:println("Failed to post welcome message");
            }
        } else {
            io:println("Failed to invite team members");
        }
    } else {
        io:println("Failed to create channel");
    }
}