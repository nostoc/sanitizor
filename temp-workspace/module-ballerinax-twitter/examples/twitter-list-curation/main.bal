import ballerina/io;
import ballerinax/twitter;

configurable string bearerToken = ?;

public function main() returns error? {
    twitter:Client twitterClient = check new ({
        auth: {
            token: bearerToken
        }
    });

    // Create a new tweet
    twitter:TweetCreateResponse tweetResponse = check twitterClient->createTweet({
        text: "Creating a new list of content creators"
    });
    
    io:println("Created new tweet");
    
    // Get user tweets
    twitter:Get2UsersIdTweetsResponse tweetsResponse = check twitterClient->getUserTweets("783214", {
        max_results: 5
    });
    
    if tweetsResponse.data is twitter:Tweet[] {
        twitter:Tweet[] tweets = <twitter:Tweet[]>tweetsResponse.data;
        io:println("Retrieved " + tweets.length().toString() + " tweets:");
        
        foreach twitter:Tweet tweet in tweets {
            string tweetText = tweet.text ?: "";
            io:println("Tweet: " + tweetText);
        }
    }
}