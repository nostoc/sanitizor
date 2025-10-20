import ballerina/io;
import ballerinax/slack;

configurable string slackToken = ?;

public function main() returns error? {
    slack:Client slackClient = check new ({
        auth: {
            token: slackToken
        }
    });

    string channelName = "project-alpha";
    string[] teamMembers = ["U1234567890", "U0987654321", "U1122334455"];
    
    io:println("Step 1: Creating private project channel...");
    slack:ConversationsCreateResponse createResponse = check slackClient->/conversations\.create.post({
        name: channelName,
        is_private: true
    });
    
    string channelId = createResponse.channel.id;
    io:println(string `Channel created successfully: ${channelId}`);
    
    io:println("Step 2: Inviting team members to the channel...");
    slack:ConversationsInviteErrorResponse inviteResponse = check slackClient->/conversations\.invite.post({
        channel: channelId,
        users: string:'join(",", ...teamMembers)
    });
    
    io:println("Team members invited successfully");
    
    io:println("Step 3: Posting welcome message with project details...");
    string welcomeMessage = string `Welcome to the Project Alpha team channel! 🚀

*Project Overview:*
This channel is dedicated to Project Alpha development and collaboration.

*Guidelines:*
• Use threads for detailed discussions
• Share updates using @channel for important announcements
• Keep conversations relevant to the project
• Use reactions to acknowledge messages

*Important Information:*
• Project Manager: @projectmanager
• Sprint Planning: Every Monday 9 AM
• Daily Standups: 10 AM in this channel
• Documentation: Check pinned messages for links

Let's build something amazing together! 💪`;

    slack:ChatPostMessageResponse messageResponse = check slackClient->/chat\.postMessage.post({
        channel: channelId,
        text: welcomeMessage,
        mrkdwn: true
    });
    
    io:println(string `Welcome message posted successfully at ${messageResponse.ts}`);
    io:println("Project channel setup completed successfully!");
}