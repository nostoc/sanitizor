```ballerina
import ballerina/io;
import ballerinax/slack;

configurable string slackToken = ?;
configurable string channelName = ?;
configurable string[] teamMembers = ?;
configurable string welcomeMessage = ?;

public function main() returns error? {
    slack:Client slackClient = check new ({
        auth: {
            token: slackToken
        }
    });

    io:println("Step 1: Creating private channel...");
    slack:ConversationsCreateResponse createResponse = check slackClient->/conversations\.create.post({
        name: channelName,
        is_private: true
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

    io:println("Step 3: Posting welcome message to the channel...");
    slack:ChatPostMessageResponse messageResponse = check slackClient->/chat\.postMessage.post({
        channel: channelId,
        text: welcomeMessage
    });

    io:println(string `Welcome message posted successfully at: ${messageResponse.ts}`);
    io:println("Project team channel setup completed successfully!");
}
```