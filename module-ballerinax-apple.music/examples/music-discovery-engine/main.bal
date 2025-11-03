import ballerina/io;
import ballerinax/apple.music;

configurable string developerToken = ?;
configurable string musicUserToken = ?;
configurable string storefront = "us";

public function main() returns error? {
    // Initialize Apple Music client
    music:ApiKeysConfig apiKeyConfig = {
        authorization: developerToken,
        musicUserToken: musicUserToken
    };
    music:Client appleMusicClient = check new(apiKeyConfig = apiKeyConfig);

    io:println("=== Music Discovery Feature Demo ===\n");

    // Step 1: Search for trending artists
    io:println("Step 1: Searching for trending artists...");
    music:GetSearchResponseFromCatalogQueries searchQuery = {
        term: "pop+music",
        types: ["artists"],
        'limit: 5
    };

    music:SearchResponse searchResponse = check appleMusicClient->/catalog/[storefront]/search(queries = searchQuery);
    
    if searchResponse.results.artists is () {
        io:println("No artists found in search results");
        return;
    }

    music:ArtistsResponse artistsResponse = <music:ArtistsResponse>searchResponse.results.artists;
    io:println(string `Found ${artistsResponse.data.length()} trending artists`);

    foreach music:Artists artist in artistsResponse.data {
        io:println(string `- Artist ID: ${artist.id}`);
    }

    // Step 2: Analyze first artist's catalog to find top songs
    if artistsResponse.data.length() > 0 {
        string firstArtistId = artistsResponse.data[0].id;
        io:println(string `\nStep 2: Analyzing catalog for artist: ${firstArtistId}`);
        
        music:GetArtistViewFromCatalogQueries topSongsQuery = {
            'limit: 10
        };

        music:AlbumsResponse topSongsResponse = check appleMusicClient->/catalog/[storefront]/artists/[firstArtistId]/view/["top-songs"](queries = topSongsQuery);
        
        io:println(string `Found ${topSongsResponse.data.length()} top albums/songs`);

        // Step 3: Get detailed song information including related artists and albums
        foreach music:Albums album in topSongsResponse.data {
            io:println(string `\nStep 3: Getting detailed information for album: ${album.id}`);
            
            if album.attributes is music:AlbumsAttributes {
                music:AlbumsAttributes attrs = <music:AlbumsAttributes>album.attributes;
                io:println(string `Album Release Date: ${attrs.releaseDate ?: "Unknown"}`);
                io:println(string `Genres: ${attrs.genreNames.toString()}`);
                io:println(string `Apple Digital Master: ${attrs.isMasteredForItunes}`);
            }

            // For demonstration, we'll analyze relationships for the first album only
            if album == topSongsResponse.data[0] {
                // Get related artists information
                music:GetSongsRelationshipFromCatalogQueries relationshipQuery = {
                    'limit: 5
                };

                io:println("\nStep 4: Finding related artists and albums...");
                
                // Note: Using the album ID as song ID for demonstration
                // In a real scenario, you would extract individual song IDs
                music:SongsResponse|error artistsRelationship = appleMusicClient->/catalog/[storefront]/songs/[album.id]/["artists"](queries = relationshipQuery);
                
                if artistsRelationship is music:SongsResponse {
                    io:println(string `Found ${artistsRelationship.data.length()} related artist songs`);
                    
                    foreach music:Songs song in artistsRelationship.data {
                        io:println(string `- Related Song ID: ${song.id}`);
                    }
                } else {
                    io:println("Could not fetch artist relationships");
                }

                // Get related albums information
                music:SongsResponse|error albumsRelationship = appleMusicClient->/catalog/[storefront]/songs/[album.id]/["albums"](queries = relationshipQuery);
                
                if albumsRelationship is music:SongsResponse {
                    io:println(string `Found ${albumsRelationship.data.length()} related album songs`);
                    
                    foreach music:Songs song in albumsRelationship.data {
                        io:println(string `- Related Album Song ID: ${song.id}`);
                    }
                } else {
                    io:println("Could not fetch album relationships");
                }
            }
        }
    }

    io:println("\n=== Music Discovery Analysis Complete ===");
    io:println("This workflow demonstrates how to:");
    io:println("1. Search for trending artists in a specific genre");
    io:println("2. Analyze their catalog to find top songs/albums");
    io:println("3. Extract detailed information including genres and release data");
    io:println("4. Discover related artists and albums for recommendation engines");
}