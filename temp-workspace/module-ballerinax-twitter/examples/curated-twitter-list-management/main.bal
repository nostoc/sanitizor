import ballerina/io;
import ballerinax/twitter;

configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string accessToken = ?;
configurable string accessTokenSecret = ?;

public function main() returns error? {
    twitter:Client twitterClient = check new ({
        auth: {
            token: accessToken
        }
    });

    twitter:ListCreateRequest listRequest = {
        name: "Industry Experts",
        description: "Curated list of influential experts in our industry for marketing campaign",
        'private: false
    };

    io:println("Creating Twitter list...");
    twitter:ListCreateResponse listResponse = check twitterClient->createList(listRequest);
    
    if listResponse.data is () {
        io:println("Failed to create list");
        return;
    }
    
    twitter:List listData = <twitter:List>listResponse.data;
    io:println("Created list: " + listData.name + " with ID: " + listData.id);

    string[] userIds = ["783214", "17874544", "428333"];
    
    foreach string userId in userIds {
        io:println("Adding user " + userId + " to list...");
        twitter:ListAddUserRequest addUserRequest = {
            user_id: userId
        };
        
        twitter:ListMutateResponse addResponse = check twitterClient->addListMember(listData.id, addUserRequest);
        
        if addResponse.data is record {} {
            record {} mutateData = <record {}>addResponse.data;
            if mutateData.hasKey("is_member") && mutateData.get("is_member") == true {
                io:println("Successfully added user " + userId + " to list");
            } else {
                io:println("Failed to add user " + userId + " to list");
            }
        }
    }

    io:println("Retrieving list members to verify composition...");
    map<string|string[]> memberQueries = {
        "user.fields": ["id", "name", "username", "public_metrics", "verified"]
    };
    
    twitter:Get2ListsIdMembersResponse membersResponse = check twitterClient->getListMembers(listData.id, queries = memberQueries);
    
    if membersResponse.data is twitter:User[] {
        twitter:User[] members = <twitter:User[]>membersResponse.data;
        io:println("List contains " + members.length().toString() + " members:");
        
        foreach twitter:User member in members {
            string memberName = member.name is string ? member.name : "Unknown";
            string memberUsername = member.username is string ? member.username : "unknown";
            io:println("- " + memberName + " (@" + memberUsername + ") - ID: " + member.id);
        }
    } else {
        io:println("No members found in the list");
    }

    if membersResponse.meta is record {} {
        record {} meta = <record {}>membersResponse.meta;
        if meta.hasKey("result_count") {
            io:println("Total result count: " + meta.get("result_count").toString());
        }
    }

    io:println("List verification complete. Ready to make public for marketing campaign.");
}