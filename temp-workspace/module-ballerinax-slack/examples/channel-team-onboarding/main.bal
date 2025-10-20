import ballerina/io;
import ballerinax/slack;

configurable string token = ?;
configurable string channelName = ?;
configurable string[] teamMembers = ?;

public function main() returns error? {
    slack:Client slackClient = check new ({
        auth: {
            token: token
        }
    });

    io:println("Step 1: Creating a new public channel...");
    slack:ConversationsCreateResponse createResponse = check slackClient->/conversations\.create.post({
        name: channelName,
        is_private: false
    });
    
    string channelId = createResponse.channel.id;
    io:println(string `Channel created successfully: ${channelId}`);

    io:println("Step 2: Inviting team members to the channel...");
    string userIds = string:'join(",", ...teamMembers);
    slack:ConversationsInviteErrorResponse inviteResponse = check slackClient->/conversations\.invite.post({
        channel: channelId,
        users: userIds
    });
    io:println("Team members invited successfully");

    io:println("Step 3: Posting a welcome message to the channel...");
    string welcomeMessage = string `Welcome to the ${channelName} channel! 🎉

This channel has been created for our project collaboration. Here are some guidelines to get us started:

• Use this space for project-related discussions and updates
• Share relevant documents and resources here
• Feel free to ask questions and collaborate openly
• Keep conversations focused and productive

Let's build something amazing together! 🚀`;

    slack:ChatPostMessageResponse messageResponse = check slackClient->/chat\.postMessage.post({
        channel: channelId,
        text: welcomeMessage
    });
    
    io:println(string `Welcome message posted successfully with timestamp: ${messageResponse.ts}`);
    io:println("Channel creation and team onboarding workflow completed!");
}