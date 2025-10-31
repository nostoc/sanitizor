import ballerina/io;
import ballerinax/apple.music;

configurable string developerToken = ?;
configurable string musicUserToken = ?;
configurable string storefront = "us";

public function main() returns error? {
    
    music:Client appleMusicClient = check new({
        authorization: developerToken,
        musicUserToken: musicUserToken
    });

    io:println("=== Music Discovery Feature Demo ===\n");
    
    // Step 1: Find albums by a specific artist (using artist name search)
    io:println("Step 1: Searching for albums by Taylor Swift...");
    
    string[] artistAlbumIds = [
        "1440857781", // Folklore
        "1584791136", // Red (Taylor's Version)  
        "1613424530", // Midnights
        "1708308989", // The Tortured Poets Department
        "1440935467"  // Evermore
    ];
    
    music:AlbumsResponse albumsResponse = check appleMusicClient->/catalog/[storefront]/albums.get(ids = artistAlbumIds);
    
    io:println(string `Found ${albumsResponse.data.length()} albums`);
    
    // Step 2: Analyze track composition and genres
    io:println("\nStep 2: Analyzing album genres and characteristics...");
    
    map<int> genreCount = {};
    string[] allGenres = [];
    
    foreach music:Albums album in albumsResponse.data {
        music:AlbumsAttributes? albumAttributes = album.attributes;
        if albumAttributes is music:AlbumsAttributes {
            
            string albumName = albumAttributes.name;
            string? releaseDateOptional = albumAttributes.releaseDate;
            string releaseDate = releaseDateOptional ?: "Unknown";
            io:println(string `Album: ${albumName}`);
            io:println(string `Release Date: ${releaseDate}`);
            io:println(string `Genres: ${albumAttributes.genreNames.toString()}`);
            io:println(string `Apple Digital Master: ${albumAttributes.isMasteredForItunes}`);
            
            // Count genre occurrences
            foreach string genre in albumAttributes.genreNames {
                allGenres.push(genre);
                if genreCount.hasKey(genre) {
                    genreCount[genre] = genreCount.get(genre) + 1;
                } else {
                    genreCount[genre] = 1;
                }
            }
            io:println("---");
        }
    }
    
    // Step 3: Identify dominant genres
    io:println("\nStep 3: Genre Analysis Results:");
    foreach string genre in genreCount.keys() {
        io:println(string `${genre}: ${genreCount.get(genre)} albums`);
    }
    
    // Step 4: Find related artists through similar genres
    io:println("\nStep 4: Discovering similar artists based on genre patterns...");
    
    // Simulate finding related artists with similar genre profiles
    string[] relatedArtistAlbumIds = [
        "1450695723", // Phoebe Bridgers - Stranger in the Alps
        "1531075861", // Lorde - Solar Power
        "1552791073", // Olivia Rodrigo - SOUR
        "1579971135", // Clairo - Sling
        "1584791042"  // Gracie Abrams - Minor
    ];
    
    music:AlbumsResponse relatedAlbumsResponse = check appleMusicClient->/catalog/[storefront]/albums.get(ids = relatedArtistAlbumIds);
    
    // Step 5: Generate music recommendations
    io:println("\nStep 5: Music Recommendations Based on Analysis:");
    io:println("Based on your interest in indie pop/alternative music, here are similar artists:");
    
    foreach music:Albums relatedAlbum in relatedAlbumsResponse.data {
        music:AlbumsAttributes? relatedAlbumAttributes = relatedAlbum.attributes;
        if relatedAlbumAttributes is music:AlbumsAttributes {
            
            // Check for genre overlap
            boolean hasGenreMatch = false;
            foreach string relatedGenre in relatedAlbumAttributes.genreNames {
                if genreCount.hasKey(relatedGenre) {
                    hasGenreMatch = true;
                    break;
                }
            }
            
            if hasGenreMatch {
                string albumName = relatedAlbumAttributes.name;
                string artistName = relatedAlbumAttributes.artistName;
                string? releaseDateOptional = relatedAlbumAttributes.releaseDate;
                string releaseDate = releaseDateOptional ?: "Unknown";
                io:println(string `✓ Recommended: ${albumName}`);
                io:println(string `  Artist: ${artistName}`);
                io:println(string `  Matching Genres: ${relatedAlbumAttributes.genreNames.toString()}`);
                io:println(string `  Release: ${releaseDate}`);
                io:println("");
            }
        }
    }
    
    // Step 6: Summary of discovery insights
    io:println("=== Discovery Summary ===");
    io:println(string `Analyzed ${albumsResponse.data.length()} original albums`);
    io:println(string `Found ${genreCount.keys().length()} distinct genres`);
    io:println(string `Generated ${relatedAlbumsResponse.data.length()} recommendations`);
    
    string dominantGenre = "";
    int maxCount = 0;
    foreach string genre in genreCount.keys() {
        int count = genreCount.get(genre);
        if count > maxCount {
            maxCount = count;
            dominantGenre = genre;
        }
    }
    
    io:println(string `Primary genre preference: ${dominantGenre} (${maxCount} albums)`);
    io:println("\nMusic discovery analysis complete!");
}