import ballerina/io;
import ballerinax/apple.music;

configurable string storefront = "us";
configurable string searchTerm = "Bohemian+Rhapsody";
configurable string apiKey = "";
configurable string musicUserToken = "";

public function main() returns error? {
    
    music:ApiKeysConfig apiKeyConfig = {
        authorization: apiKey,
        musicUserToken: musicUserToken
    };
    
    music:Client musicClient = check new (apiKeyConfig = apiKeyConfig);
    
    io:println("🎵 Starting Music Discovery Service");
    io:println("=====================================");
    
    io:println(string `\n🔍 Searching for song: ${searchTerm.toString()}`);
    
    music:GetSearchResponseFromCatalogQueries searchQueries = {
        term: searchTerm,
        types: ["songs", "artists"],
        "limit": 10
    };
    
    music:SearchResponse searchResponse = check musicClient->/catalog/[storefront]/search(queries = searchQueries);
    
    music:ArtistsResponse? artistsResponse = searchResponse.results.artists;
    if artistsResponse is () {
        io:println("❌ No artists found for the search term");
        return;
    }
    
    music:Artists[] artistsData = artistsResponse.data;
    if artistsData.length() == 0 {
        io:println("❌ No artists found for the search term");
        return;
    }
    
    music:Artists primaryArtist = artistsData[0];
    io:println(string `✅ Found primary artist: ${primaryArtist.id}`);
    
    io:println(string `\n🎭 Finding similar artists to: ${primaryArtist.id}`);
    
    music:GetArtistViewFromCatalogQueries similarArtistsQueries = {
        "limit": 5
    };
    
    music:AlbumsResponse|error similarArtistsResult = musicClient->/catalog/[storefront]/artists/[primaryArtist.id]/view/["similar-artists"](queries = similarArtistsQueries);
    
    if similarArtistsResult is error {
        io:println(string `⚠️ Could not fetch similar artists: ${similarArtistsResult.message()}`);
    } else {
        io:println(string `✅ Found ${similarArtistsResult.data.length()} similar artists`);
    }
    
    io:println(string `\n🎶 Getting top songs for primary artist: ${primaryArtist.id}`);
    
    music:GetArtistViewFromCatalogQueries topSongsQueries = {
        "limit": 10
    };
    
    music:AlbumsResponse|error topSongsResult = musicClient->/catalog/[storefront]/artists/[primaryArtist.id]/view/["top-songs"](queries = topSongsQueries);
    
    if topSongsResult is error {
        io:println(string `⚠️ Could not fetch top songs: ${topSongsResult.message()}`);
    } else {
        io:println(string `✅ Found ${topSongsResult.data.length()} top songs for primary artist`);
        
        foreach int i in 0..<topSongsResult.data.length() {
            if i < 3 {
                music:Albums song = topSongsResult.data[i];
                io:println(string `   🎵 Song ${i + 1}: ID ${song.id}`);
            }
        }
    }
    
    io:println("\n📊 Music Discovery Summary");
    io:println("==========================");
    io:println(string `🎯 Original search: ${searchTerm}`);
    io:println(string `🎤 Primary artist found: ${primaryArtist.id}`);
    
    if similarArtistsResult is music:AlbumsResponse {
        io:println(string `👥 Similar artists discovered: ${similarArtistsResult.data.length()}`);
    }
    
    if topSongsResult is music:AlbumsResponse {
        io:println(string `🎵 Top songs available: ${topSongsResult.data.length()}`);
    }
    
    io:println("\n🔄 Expanding recommendations with additional song search...");
    
    music:GetSongsFromCatalogQueries additionalSongsQueries = {
        "limit": 5
    };
    
    music:SongsResponse|error additionalSongs = musicClient->/catalog/[storefront]/songs(queries = additionalSongsQueries);
    
    if additionalSongs is error {
        io:println(string `⚠️ Could not fetch additional songs: ${additionalSongs.message()}`);
    } else {
        io:println(string `✅ Found ${additionalSongs.data.length()} additional songs for discovery`);
        
        foreach int i in 0..<additionalSongs.data.length() {
            music:Songs song = additionalSongs.data[i];
            if song.attributes is music:SongsAttributes {
                music:SongsAttributes attrs = <music:SongsAttributes>song.attributes;
                io:println(string `   🎵 ${attrs.albumName} - Duration: ${attrs.durationInMillis}ms`);
                
                if attrs.genreNames.length() > 0 {
                    io:println(string `      🏷️ Genres: ${attrs.genreNames[0]}`);
                }
            }
        }
    }
    
    io:println("\n🎉 Music discovery service completed!");
    io:println("Recommendations have been built based on musical taste patterns.");
}