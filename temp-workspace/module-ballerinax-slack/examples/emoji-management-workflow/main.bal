import ballerina/io;
import ballerinax/slack;

configurable string slackToken = ?;

public function main() returns error? {
    slack:Client slackClient = check new ({
        auth: {
            token: slackToken
        }
    });

    io:println("Step 1: Retrieving current list of custom emojis...");
    map<string> listQueries = {
        "limit": "100"
    };
    slack:DefaultSuccessResponse emojiListResponse = check slackClient->/admin\.emoji\.list.post(listQueries);
    io:println("Current emoji list retrieved successfully:");
    io:println(emojiListResponse);

    io:println("\nStep 2: Adding a new custom emoji...");
    slack:admin_emoji_add_body addEmojiPayload = {
        name: "company_logo",
        url: "https://example.com/company-logo.png",
        token: slackToken
    };
    slack:DefaultSuccessResponse addEmojiResponse = check slackClient->/admin\.emoji\.add.post(addEmojiPayload);
    io:println("New emoji 'company_logo' added successfully:");
    io:println(addEmojiResponse);

    io:println("\nStep 3: Creating an alias for the newly added emoji...");
    slack:admin_emoji_addAlias_body addAliasPayload = {
        name: "logo",
        alias_for: "company_logo",
        token: slackToken
    };
    slack:DefaultSuccessResponse addAliasResponse = check slackClient->/admin\.emoji\.addAlias.post(addAliasPayload);
    io:println("Alias 'logo' created for 'company_logo' emoji successfully:");
    io:println(addAliasResponse);

    io:println("\nEmoji management workflow completed successfully!");
}