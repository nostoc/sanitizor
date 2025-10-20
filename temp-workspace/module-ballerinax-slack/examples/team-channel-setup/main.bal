import ballerina/io;
import ballerinax/slack;

configurable string token = ?;

public function main() returns error? {
    slack:Client slackClient = check new ({
        auth: {
            token: token
        }
    });

    io:println("Starting team channel setup workflow...");

    string channelName = "project-alpha-team";
    string[] teamMembers = ["U1234567890", "U0987654321", "U1122334455"];
    string welcomeMessage = "Welcome to the Project Alpha team channel! 🚀\n\n" +
        "This is our dedicated space for collaboration on the new project. " +
        "Please use this channel for:\n" +
        "• Project updates and status reports\n" +
        "• Team discussions and brainstorming\n" +
        "• File sharing and resource coordination\n" +
        "• Meeting scheduling and announcements\n\n" +
        "Let's make this project a success! Feel free to introduce yourselves and share any initial thoughts.";

    io:println("Step 1: Creating private channel '" + channelName + "'...");
    
    slack:ConversationsCreateResponse createResponse = check slackClient->conversations\.create({
        name: channelName,
        is_private: true
    });
    
    if createResponse.ok {
        string channelId = createResponse.channel.id;
        io:println("✓ Successfully created private channel with ID: " + channelId);

        io:println("Step 2: Inviting team members to the channel...");
        
        string userIds = string:'join(",", ...teamMembers);
        slack:ConversationsInviteErrorResponse inviteResponse = check slackClient->conversations\.invite({
            channel: channelId,
            users: userIds
        });
        
        if inviteResponse.ok {
            io:println("✓ Successfully invited " + teamMembers.length().toString() + " team members to the channel");

            io:println("Step 3: Posting welcome message to the channel...");
            
            slack:ChatPostMessageResponse messageResponse = check slackClient->chat\.postMessage({
                channel: channelId,
                text: welcomeMessage,
                unfurl_links: false,
                unfurl_media: false
            });
            
            if messageResponse.ok {
                io:println("✓ Successfully posted welcome message");
                io:println("Message timestamp: " + messageResponse.ts);
                io:println("\n🎉 Team channel setup completed successfully!");
                io:println("Channel: #" + channelName);
                io:println("Members invited: " + teamMembers.length().toString());
                io:println("Welcome message posted and ready for team collaboration!");
            } else {
                io:println("✗ Failed to post welcome message to the channel");
            }
        } else {
            io:println("✗ Failed to invite team members to the channel");
        }
    } else {
        io:println("✗ Failed to create the private channel");
    }
}