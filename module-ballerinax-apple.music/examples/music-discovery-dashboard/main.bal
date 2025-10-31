import ballerina/io;
import ballerinax/apple.music;

configurable string authorization = ?;
configurable string musicUserToken = ?;
configurable string storefront = "us";

public function main() returns error? {
    
    music:ApiKeysConfig config = {
        authorization: authorization,
        musicUserToken: musicUserToken
    };
    
    music:Client appleMusic = check new (config);
    
    // Step 1: Search for artists in a specific genre to discover new music
    io:println("=== Step 1: Discovering Artists in Electronic Genre ===");
    
    music:GetSearchResponseFromCatalogQueries searchQueries = {
        term: "electronic",
        types: ["artists"],
        'limit: 10
    };
    
    music:SearchResponse searchResults = check appleMusic->/catalog/[storefront]/search(queries = searchQueries);
    
    if searchResults.results.artists is () {
        io:println("No artists found in search results");
        return;
    }
    
    music:ArtistsResponse artistsResponse = <music:ArtistsResponse>searchResults.results.artists;
    int artistCount = artistsResponse.data.length();
    io:println(string `Found ${artistCount} artists for discovery`);
    
    string[] discoveredArtistIds = [];
    foreach music:Artists artist in artistsResponse.data {
        string artistName = artist.attributes?.name ?: "Unknown";
        string artistId = artist.id;
        io:println(string `Discovered artist: ${artistName} (ID: ${artistId})`);
        discoveredArtistIds.push(artistId);
    }
    
    // Step 2: Get detailed information for the first discovered artist
    if discoveredArtistIds.length() > 0 {
        string selectedArtistId = discoveredArtistIds[0];
        io:println(string `\n=== Step 2: Getting Top Songs for Artist ID: ${selectedArtistId} ===`);
        
        music:GetArtistViewFromCatalogQueries topSongsQueries = {
            'limit: 5
        };
        
        music:AlbumsResponse topSongs = check appleMusic->/catalog/[storefront]/artists/[selectedArtistId]/view/["top-songs"](queries = topSongsQueries);
        
        int topSongsCount = topSongs.data.length();
        io:println(string `Found ${topSongsCount} top albums/songs for the artist`);
        foreach music:Albums album in topSongs.data {
            string albumName = album.attributes?.name ?: "Unknown Album";
            string releaseDate = album.attributes?.releaseDate ?: "Unknown Date";
            io:println(string `  - ${albumName} (${releaseDate})`);
        }
        
        // Get similar artists for better recommendations
        io:println(string `\n=== Step 2b: Finding Similar Artists ===`);
        
        music:GetArtistViewFromCatalogQueries similarArtistsQueries = {
            'limit: 8
        };
        
        music:AlbumsResponse|error similarArtistsResult = appleMusic->/catalog/[storefront]/artists/[selectedArtistId]/view/["similar-artists"](queries = similarArtistsQueries);
        
        if similarArtistsResult is music:AlbumsResponse {
            int similarCount = similarArtistsResult.data.length();
            io:println(string `Found ${similarCount} similar artists`);
            foreach music:Albums similarArtist in similarArtistsResult.data {
                string similarName = similarArtist.attributes?.name ?: "Unknown Artist";
                io:println(string `  Similar: ${similarName}`);
            }
        } else {
            io:println("Could not fetch similar artists for this artist");
        }
    }
    
    // Step 3: Check user's library to avoid duplicate recommendations
    io:println("\n=== Step 3: Checking User's Library Artists ===");
    
    music:GetArtistsFromLibraryQueries libraryQueries = {
        'limit: 20
    };
    
    music:LibraryArtistsResponse|error libraryResult = appleMusic->/me/library/artists(queries = libraryQueries);
    
    if libraryResult is music:LibraryArtistsResponse {
        int libraryCount = libraryResult.data.length();
        io:println(string `User has ${libraryCount} artists in their library`);
        
        string[] libraryArtistNames = [];
        foreach music:LibraryArtists libraryArtist in libraryResult.data {
            string artistName = libraryArtist.attributes?.name ?: "Unknown";
            libraryArtistNames.push(artistName.toLowerAscii());
            io:println(string `  Library artist: ${artistName}`);
        }
        
        // Step 4: Generate filtered recommendations
        io:println("\n=== Step 4: Generating Filtered Recommendations ===");
        
        string[] recommendations = [];
        foreach music:Artists discoveredArtist in artistsResponse.data {
            string artistName = discoveredArtist.attributes?.name ?: "Unknown";
            string artistNameLower = artistName.toLowerAscii();
            
            boolean alreadyInLibrary = false;
            foreach string libraryName in libraryArtistNames {
                if libraryName.includes(artistNameLower) || artistNameLower.includes(libraryName) {
                    alreadyInLibrary = true;
                    break;
                }
            }
            
            if !alreadyInLibrary {
                recommendations.push(artistName);
            }
        }
        
        io:println("\n🎵 NEW ARTIST RECOMMENDATIONS FOR YOUR DISCOVERY:");
        if recommendations.length() == 0 {
            io:println("No new recommendations - you already have similar artists in your library!");
        } else {
            foreach int i in 0..<recommendations.length() {
                int displayNumber = i + 1;
                string recommendationName = recommendations[i];
                io:println(string `${displayNumber}. ${recommendationName}`);
            }
        }
        
        int discoveredCount = discoveredArtistIds.length();
        int libraryDataCount = libraryResult.data.length();
        int recommendationCount = recommendations.length();
        io:println(string `\nSummary: Found ${discoveredCount} discovery candidates, you have ${libraryDataCount} artists in library, recommending ${recommendationCount} new artists`);
        
    } else {
        io:println("Could not access user's library - showing all discovered artists as recommendations");
        io:println("\n🎵 DISCOVERY RECOMMENDATIONS:");
        foreach int i in 0..<discoveredArtistIds.length() {
            music:Artists artist = artistsResponse.data[i];
            int displayNumber = i + 1;
            string artistName = artist.attributes?.name ?: "Unknown Artist";
            io:println(string `${displayNumber}. ${artistName}`);
        }
    }
}