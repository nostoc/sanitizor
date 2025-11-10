import ballerina/io;
import ballerinax/apple.music;

configurable string developerToken = ?;
configurable string userToken = ?;
configurable string storefront = "us";

public function main() returns error? {
    music:Client appleMusic = check new ({
        auth: {
            token: developerToken
        }
    });

    io:println("Starting music discovery and library management workflow...");
    
    // Step 1: Search for a specific artist
    string artistName = "Taylor Swift";
    io:println(string `\nStep 1: Searching for artist: ${artistName}`);
    
    music:SearchResponse searchResponse = check appleMusic->/catalog/[storefront]/search(
        queries = {
            term: artistName.replace(" ", "+"),
            types: ["artists", "albums"],
            'limit: 25
        }
    );
    
    if searchResponse.results.artists is () || searchResponse.results.artists.data.length() == 0 {
        io:println("No artists found!");
        return;
    }
    
    music:Artists foundArtist = searchResponse.results.artists.data[0];
    io:println(string `Found artist: ${foundArtist.attributes.name}`);
    
    // Step 2: Analyze the artist's discography from search results
    io:println("\nStep 2: Analyzing artist's discography from search results");
    
    music:Albums[] artistAlbums = [];
    if searchResponse.results.albums is music:AlbumsResponse {
        artistAlbums = searchResponse.results.albums.data;
        
        io:println(string `Found ${artistAlbums.length()} albums in search results:`);
        foreach music:Albums album in artistAlbums {
            io:println(string `- ${album.attributes.name} (${album.attributes.releaseDate ?: "Unknown date"})`);
        }
    }
    
    // Step 3: Select interesting albums and add to library
    io:println("\nStep 3: Adding selected albums to personal library");
    
    if artistAlbums.length() > 0 {
        // Select first 3 albums as "interesting releases"
        int albumsToAdd = artistAlbums.length() < 3 ? artistAlbums.length() : 3;
        music:AddToLibraryQueriesIdsItemsString[] albumIds = [];
        
        int i = 0;
        while i < albumsToAdd {
            albumIds.push(artistAlbums[i].id);
            io:println(string `Selected for library: ${artistAlbums[i].attributes.name}`);
            i += 1;
        }
        
        // Add selected albums to user's library
        error? addResult = appleMusic->/me/library.post(
            headers = {
                "Music-User-Token": userToken
            },
            queries = {
                ids: albumIds
            }
        );
        
        if addResult is error {
            io:println(string `Error adding albums to library: ${addResult.message()}`);
        } else {
            io:println(string `Successfully added ${albumIds.length()} albums to your library!`);
        }
    } else {
        io:println("No albums found to add to library");
    }
    
    io:println("\nMusic discovery and library management workflow completed!");
}