import ballerina/io;
import ballerinax/twitter;

configurable string bearerToken = ?;

public function main() returns error? {
    twitter:Client twitterClient = check new ({
        auth: {
            token: bearerToken
        }
    });

    // Step 1: Get user information
    twitter:User|error userResult = twitterClient->getUserById("783214");
    if (userResult is twitter:User) {
        io:println("Retrieved user: " + userResult.toString());
    } else {
        io:println("Error retrieving user: " + userResult.toString());
    }

    // Step 2: Search for tweets
    twitter:TweetSearchRecentResponse|error searchResult = twitterClient->searchRecentTweets("marketing", maxResults = 10);
    if (searchResult is twitter:TweetSearchRecentResponse) {
        io:println("Search results: " + searchResult.toString());
        
        // Step 3: Process the tweets
        if (searchResult.data is twitter:Tweet[]) {
            foreach twitter:Tweet tweet in <twitter:Tweet[]>searchResult.data {
                string tweetText = tweet.text ?: "";
                io:println("Tweet: " + tweetText);
            }
        }
    } else {
        io:println("Error searching tweets: " + searchResult.toString());
    }

    io:println("Successfully completed Twitter operations for marketing campaign");
}