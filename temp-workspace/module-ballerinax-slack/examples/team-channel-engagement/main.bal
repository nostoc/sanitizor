import ballerina/io;
import ballerinax/slack;

configurable string slackToken = ?;

public function main() returns error? {
    slack:Client slackClient = check new({
        auth: {
            token: slackToken
        }
    });
    
    // Step 1: Create a new public channel called "team-announcements"
    slack:ConversationsCreateResponse channelResponse = check slackClient->/conversations\.create.post({
        name: "team-announcements",
        is_private: false
    });
    
    string channelId = channelResponse.channel.id;
    io:println("Created channel: " + channelResponse.channel.name + " with ID: " + channelId);
    
    // Step 2: Post a welcome message to the newly created channel
    slack:ChatPostMessageResponse messageResponse = check slackClient->/chat\.postMessage.post({
        channel: channelId,
        text: "Welcome to the team announcements channel! 🎉 This is your dedicated space for important team updates and announcements. Please feel free to react to messages to show your engagement and let us know you've seen important updates."
    });
    
    string messageTs = messageResponse.ts;
    io:println("Posted welcome message with timestamp: " + messageTs);
    
    // Step 3: Add a thumbs up reaction to the welcome message
    slack:ReactionsAddResponse reactionResponse = check slackClient->/reactions\.add.post({
        channel: channelId,
        name: "thumbsup",
        timestamp: messageTs
    });
    
    io:println("Added thumbs up reaction to the welcome message");
    io:println("Team notification channel setup completed successfully!");
}