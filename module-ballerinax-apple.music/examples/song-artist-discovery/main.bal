import ballerina/io;
import ballerinax/apple.music;

configurable string accessToken = ?;
configurable string storefront = "us";

public function main() returns error? {

    music:Client appleMusic = check new ({
        authorization: accessToken,
        musicUserToken: ""
    });

    io:println("=== Music Discovery Application ===");
    io:println("Searching for song: 'Shake It Off'");

    ("activities"|"albums"|"apple-curators"|"artists"|"curators"|"music-videos"|"playlists"|"record-labels"|"songs"|"stations")[] searchTypes = ["songs", "artists"];
    music:SearchResponse searchResponse = check appleMusic->/catalog/[storefront]/search(
        term = "Shake+It+Off",
        types = searchTypes,
        'limit = 10
    );

    io:println("Search completed successfully");

    music:ArtistsResponse? artistsResponse = searchResponse.results.artists;
    if artistsResponse is () {
        io:println("No artists found in search results");
        return;
    }

    music:Artists[] artistsData = artistsResponse.data;
    if artistsData.length() == 0 {
        io:println("No artists found in search results");
        return;
    }

    music:Artists firstArtist = artistsData[0];
    string artistId = firstArtist.id;

    io:println(string `Found artist with ID: ${artistId}`);

    io:println("\n=== Getting Artist Details ===");
    string[] includeFields = ["albums"];
    ("appears-on-albums"|"compilation-albums"|"featured-albums"|"featured-playlists"|"full-albums"|"latest-release"|"live-albums"|"similar-artists"|"singles"|"top-music-videos"|"top-songs")[] viewTypes = ["full-albums", "featured-playlists", "top-songs"];
    music:ArtistsResponse artistResponse = check appleMusic->/catalog/[storefront]/artists/[artistId](
        include = includeFields,
        views = viewTypes
    );

    if artistResponse.data.length() > 0 {
        music:Artists artist = artistResponse.data[0];
        io:println(string `Artist ID: ${artist.id}`);
        io:println(string `Artist Type: ${artist.'type}`);
    }

    io:println("\n=== Exploring Artist's Full Albums ===");
    string[] includeTracksFields = ["tracks"];
    music:AlbumsResponse fullAlbumsResponse = check appleMusic->/catalog/[storefront]/artists/[artistId]/view/["full-albums"](
        'limit = 20,
        include = includeTracksFields
    );

    io:println(string `Found ${fullAlbumsResponse.data.length()} full albums`);
    foreach music:Albums album in fullAlbumsResponse.data {
        io:println(string `- Album: ${album.id} (Type: ${album.'type})`);
        if album.attributes is music:AlbumsAttributes {
            music:AlbumsAttributes attrs = <music:AlbumsAttributes>album.attributes;
            io:println(string `  Release Date: ${attrs.releaseDate ?: "Unknown"}`);
            io:println(string `  Genres: ${string:'join(", ", ...attrs.genreNames)}`);
            io:println(string `  Apple Digital Master: ${attrs.isMasteredForItunes}`);
        }
    }

    io:println("\n=== Finding Featured Playlists ===");
    music:AlbumsResponse featuredPlaylistsResponse = check appleMusic->/catalog/[storefront]/artists/[artistId]/view/["featured-playlists"](
        'limit = 15
    );

    io:println(string `Found ${featuredPlaylistsResponse.data.length()} featured playlists`);
    foreach music:Albums playlist in featuredPlaylistsResponse.data {
        io:println(string `- Playlist: ${playlist.id}`);
        io:println(string `  Href: ${playlist.href}`);
    }

    io:println("\n=== Discovering Similar Artists ===");
    music:AlbumsResponse similarArtistsResponse = check appleMusic->/catalog/[storefront]/artists/[artistId]/view/["similar-artists"](
        'limit = 10
    );

    io:println(string `Found ${similarArtistsResponse.data.length()} similar artists`);
    foreach music:Albums similarArtist in similarArtistsResponse.data {
        io:println(string `- Similar Artist: ${similarArtist.id} (${similarArtist.'type})`);
    }

    io:println("\n=== Top Songs for Recommendations ===");
    music:AlbumsResponse topSongsResponse = check appleMusic->/catalog/[storefront]/artists/[artistId]/view/["top-songs"](
        'limit = 25
    );

    io:println(string `Found ${topSongsResponse.data.length()} top songs`);

    io:println("\n=== Music Discovery Complete ===");
    io:println("Recommendation Summary:");
    io:println(string `- ${fullAlbumsResponse.data.length()} albums to explore`);
    io:println(string `- ${featuredPlaylistsResponse.data.length()} curated playlists`);
    io:println(string `- ${similarArtistsResponse.data.length()} similar artists to discover`);
    io:println(string `- ${topSongsResponse.data.length()} top tracks for immediate listening`);
}
