import ballerina/test;
import ballerina/http;

// Import mock server
import apple.music.mock.server as _;

// Configurable variables for testing
configurable boolean useMockServer = true;
configurable string mockServerUrl = "http://localhost:9090";
configurable string liveServerUrl = "https://api.music.apple.com";

// HTTP client configuration
final http:Client clientEp = check new (useMockServer ? mockServerUrl : liveServerUrl);

// CATALOG ALBUMS TESTS

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetMultipleCatalogAlbums() returns error? {
    AlbumsResponse response = check clientEp->/v1/catalog/us/albums(ids = ["1440857781", "1193701079"]);
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
    test:assertTrue(response.data.length() > 0);
    test:assertEquals(response.data[0].id, "1440857781");
    test:assertEquals(response.data[0].attributes.name, "Abbey Road (Remastered)");
    test:assertEquals(response.data[0].attributes.artistName, "The Beatles");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetMultipleCatalogAlbumsWithOptionalParams() returns error? {
    AlbumsResponse response = check clientEp->/v1/catalog/us/albums(
        ids = ["1440857781"],
        extend = ["attributes"],
        include = ["artists"],
        l = "en-US"
    );
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
    test:assertTrue(response.data.length() > 0);
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetMultipleCatalogAlbumsUnauthorized() returns error? {
    AlbumsResponse|ErrorsResponseUnauthorized|ErrorsResponseInternalServerError response = 
        check clientEp->/v1/catalog/unauthorized/albums(ids = ["1440857781"]);
    
    if response is ErrorsResponseUnauthorized {
        test:assertTrue(response?.body?.data !is ());
        test:assertEquals(response.body.data[0].status, "401");
        test:assertEquals(response.body.data[0].code, "UNAUTHORIZED");
    } else {
        test:assertFail("Expected unauthorized error response");
    }
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetCatalogAlbum() returns error? {
    AlbumsResponse response = check clientEp->/v1/catalog/us/albums/1708283932();
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
    test:assertEquals(response.data[0].id, "1708283932");
    test:assertEquals(response.data[0].attributes.name, "1989 (Taylor's Version)");
    test:assertEquals(response.data[0].attributes.artistName, "Taylor Swift");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetCatalogAlbumWithViews() returns error? {
    AlbumsResponse response = check clientEp->/v1/catalog/us/albums/1708283932(
        views = ["appears-on", "other-versions"],
        extend = ["attributes"],
        include = ["artists"]
    );
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetCatalogAlbumRelationshipArtists() returns error? {
    ArtistsResponse response = check clientEp->/v1/catalog/us/albums/1708283932/artists();
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
    test:assertTrue(response.data.length() > 0);
    test:assertEquals(response.data[0].id, "159260351");
    test:assertEquals(response.data[0].attributes.name, "Taylor Swift");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetCatalogAlbumRelationshipWithLimit() returns error? {
    ArtistsResponse response = check clientEp->/v1/catalog/us/albums/1708283932/artists(
        'limit = 10,
        extend = ["attributes"]
    );
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetCatalogAlbumViewRelatedVideos() returns error? {
    MusicVideosResponse response = check clientEp->/v1/catalog/us/albums/1708283932/view/related\-videos();
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
    test:assertTrue(response.data.length() > 0);
    test:assertEquals(response.data[0].id, "1234567890");
    test:assertEquals(response.data[0].attributes.name, "Shake It Off");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetCatalogAlbumViewWithParams() returns error? {
    MusicVideosResponse response = check clientEp->/v1/catalog/us/albums/1708283932/view/related\-videos(
        'limit = 3,
        with = ["attributes"],
        extend = ["attributes"]
    );
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
}

// CATALOG ARTISTS TESTS

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetMultipleCatalogArtists() returns error? {
    ArtistsResponse response = check clientEp->/v1/catalog/us/artists(ids = ["159260351", "136975"]);
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
    test:assertTrue(response.data.length() >= 2);
    test:assertEquals(response.data[0].id, "159260351");
    test:assertEquals(response.data[0].attributes.name, "Taylor Swift");
    test:assertEquals(response.data[1].id, "136975");
    test:assertEquals(response.data[1].attributes.name, "The Beatles");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetMultipleCatalogArtistsWithFilters() returns error? {
    ArtistsResponse response = check clientEp->/v1/catalog/us/artists(
        ids = ["159260351"],
        filter = ["genre"],
        restrict = ["explicit"],
        l = "en-US"
    );
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetCatalogArtist() returns error? {
    ArtistsResponse response = check clientEp->/v1/catalog/us/artists/5468295();
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
    test:assertEquals(response.data[0].id, "5468295");
    test:assertEquals(response.data[0].attributes.name, "Adele");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetCatalogArtistWithViews() returns error? {
    ArtistsResponse response = check clientEp->/v1/catalog/us/artists/5468295(
        views = ["top-songs", "full-albums", "latest-release"],
        extend = ["attributes"],
        include = ["albums"]
    );
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetCatalogArtistRelationshipAlbums() returns error? {
    AlbumsResponse response = check clientEp->/v1/catalog/us/artists/5468295/albums();
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
    test:assertTrue(response.data.length() > 0);
    test:assertEquals(response.data[0].id, "1440857781");
    test:assertEquals(response.data[0].attributes.name, "25");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetCatalogArtistRelationshipWithParams() returns error? {
    AlbumsResponse response = check clientEp->/v1/catalog/us/artists/5468295/albums(
        'limit = 20,
        extend = ["attributes"],
        include = ["artists"]
    );
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetCatalogArtistViewFullAlbums() returns error? {
    AlbumsResponse response = check clientEp->/v1/catalog/us/artists/5468295/view/full\-albums();
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
    test:assertTrue(response.data.length() > 0);
    test:assertEquals(response.data[0].id, "987654321");
    test:assertEquals(response.data[0].attributes.name, "30");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetCatalogArtistViewWithModifications() returns error? {
    AlbumsResponse response = check clientEp->/v1/catalog/us/artists/5468295/view/full\-albums(
        'limit = 10,
        with = ["topResults"],
        extend = ["attributes"]
    );
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
}

// CATALOG SEARCH TESTS

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testSearchCatalog() returns error? {
    SearchResponse response = check clientEp->/v1/catalog/us/search(term = "beatles");
    test:assertTrue(response?.results !is ());
    test:assertTrue(response.results.albums?.data !is ());
    test:assertTrue(response.results.artists?.data !is ());
    test:assertTrue(response.results.albums.data.length() > 0);
    test:assertTrue(response.results.artists.data.length() > 0);
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testSearchCatalogWithTypes() returns error? {
    SearchResponse response = check clientEp->/v1/catalog/us/search(
        term = "taylor+swift",
        types = ["albums", "artists", "songs"],
        'limit = 10
    );
    test:assertTrue(response?.results !is ());
    test:assertTrue(response.results.albums?.data !is ());
    test:assertTrue(response.results.artists?.data !is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testSearchCatalogWithAllParams() returns error? {
    SearchResponse response = check clientEp->/v1/catalog/us/search(
        term = "shake+it+off",
        types = ["songs", "music-videos"],
        'limit = 5,
        offset = "0",
        with = ["topResults"],
        l = "en-US"
    );
    test:assertTrue(response?.results !is ());
}

// CATALOG SONGS TESTS

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetMultipleCatalogSongs() returns error? {
    SongsResponse response = check clientEp->/v1/catalog/us/songs(ids = ["1440857915", "1193701194"]);
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
    test:assertTrue(response.data.length() >= 2);
    test:assertEquals(response.data[0].id, "1440857915");
    test:assertEquals(response.data[0].attributes.name, "Come Together (Remastered 2019)");
    test:assertEquals(response.data[1].id, "1193701194");
    test:assertEquals(response.data[1].attributes.name, "Billie Jean");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetMultipleCatalogSongsWithFilters() returns error? {
    SongsResponse response = check clientEp->/v1/catalog/us/songs(
        ids = ["1440857915"],
        filter = ["explicit"],
        restrict = ["clean"],
        extend = ["attributes"]
    );
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetCatalogSong() returns error? {
    SongsResponse response = check clientEp->/v1/catalog/us/songs/1708284055();
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
    test:assertEquals(response.data[0].id, "1708284055");
    test:assertEquals(response.data[0].attributes.name, "Shake It Off");
    test:assertEquals(response.data[0].attributes.artistName, "Taylor Swift");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetCatalogSongWithParams() returns error? {
    SongsResponse response = check clientEp->/v1/catalog/us/songs/1708284055(
        extend = ["attributes"],
        include = ["albums", "artists"],
        l = "en-US"
    );
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetCatalogSongRelationship() returns error? {
    SongsResponse response = check clientEp->/v1/catalog/us/songs/1708284055/albums();
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetCatalogSongRelationshipWithLimit() returns error? {
    SongsResponse response = check clientEp->/v1/catalog/us/songs/1708284055/artists(
        'limit = 1,
        extend = ["attributes"]
    );
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
}

// LIBRARY ALBUMS TESTS

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetAllLibraryAlbums() returns error? {
    LibraryAlbumsResponse response = check clientEp->/v1/me/library/albums();
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
    test:assertTrue(response.data.length() >= 2);
    test:assertEquals(response.data[0].id, "lib-1440857781");
    test:assertEquals(response.data[0].attributes.name, "Abbey Road (Remastered)");
    test:assertEquals(response.data[1].id, "lib-1708283932");
    test:assertEquals(response.data[1].attributes.name, "1989 (Taylor's Version)");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetAllLibraryAlbumsWithParams() returns error? {
    LibraryAlbumsResponse response = check clientEp->/v1/me/library/albums(
        ids = ["lib-1440857781"],
        'limit = 10,
        offset = "0",
        extend = ["attributes"]
    );
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetLibraryAlbum() returns error? {
    LibraryAlbumsResponse response = check clientEp->/v1/me/library/albums/lib\-folklore();
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
    test:assertEquals(response.data[0].id, "lib-folklore");
    test:assertEquals(response.data[0].attributes.name, "Folklore");
    test:assertEquals(response.data[0].attributes.artistName, "Taylor Swift");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetLibraryAlbumWithParams() returns error? {
    LibraryAlbumsResponse response = check clientEp->/v1/me/library/albums/lib\-folklore(
        extend = ["attributes"],
        include = ["artists"],
        l = "en-US"
    );
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetLibraryAlbumRelationshipArtists() returns error? {
    LibraryArtistsResponse response = check clientEp->/v1/me/library/albums/lib\-folklore/artists();
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
    test:assertTrue(response.data.length() > 0);
    test:assertEquals(response.data[0].id, "lib-159260351");
    test:assertEquals(response.data[0].attributes.name, "Taylor Swift");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetLibraryAlbumRelationshipWithLimit() returns error? {
    LibraryArtistsResponse response = check clientEp->/v1/me/library/albums/lib\-folklore/artists(
        'limit = 5,
        extend = ["attributes"]
    );
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
}

// LIBRARY ARTISTS TESTS

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetAllLibraryArtists() returns error? {
    LibraryArtistsResponse response = check clientEp->/v1/me/library/artists();
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
    test:assertTrue(response.data.length() >= 2);
    test:assertEquals(response.data[0].id, "lib-159260351");
    test:assertEquals(response.data[0].attributes.name, "Taylor Swift");
    test:assertEquals(response.data[1].id, "lib-136975");
    test:assertEquals(response.data[1].attributes.name, "The Beatles");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetAllLibraryArtistsWithParams() returns error? {
    LibraryArtistsResponse response = check clientEp->/v1/me/library/artists(
        ids = ["lib-159260351"],
        'limit = 20,
        offset = "0",
        include = ["albums"]
    );
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetLibraryArtist() returns error? {
    LibraryArtistsResponse response = check clientEp->/v1/me/library/artists/lib\-ed\-sheeran();
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
    test:assertEquals(response.data[0].id, "lib-ed-sheeran");
    test:assertEquals(response.data[0].attributes.name, "Ed Sheeran");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetLibraryArtistWithParams() returns error? {
    LibraryArtistsResponse response = check clientEp->/v1/me/library/artists/lib\-ed\-sheeran(
        extend = ["attributes"],
        include = ["albums"],
        l = "en-US"
    );
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetLibraryArtistRelationshipAlbums() returns error? {
    LibraryAlbumsResponse response = check clientEp->/v1/me/library/artists/lib\-ed\-sheeran/albums();
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
    test:assertTrue(response.data.length() > 0);
    test:assertEquals(response.data[0].id, "lib-divide-album");
    test:assertEquals(response.data[0].attributes.name, "÷ (Divide)");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetLibraryArtistRelationshipWithParams() returns error? {
    LibraryAlbumsResponse response = check clientEp->/v1/me/library/artists/lib\-ed\-sheeran/albums(
        'limit = 10,
        extend = ["attributes"],
        include = ["artists"]
    );
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
}

// LIBRARY SONGS TESTS

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetAllLibrarySongs() returns error? {
    LibrarySongsResponse response = check clientEp->/v1/me/library/songs();
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
    test:assertTrue(response.data.length() >= 2);
    test:assertEquals(response.data[0].id, "lib-shape-of-you");
    test:assertEquals(response.data[0].attributes.name, "Shape of You");
    test:assertEquals(response.data[1].id, "lib-perfect");
    test:assertEquals(response.data[1].attributes.name, "Perfect");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetAllLibrarySongsWithParams() returns error? {
    LibrarySongsResponse response = check clientEp->/v1/me/library/songs(
        ids = ["lib-shape-of-you"],
        'limit = 25,
        offset = "0",
        extend = ["attributes"]
    );
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetLibrarySong() returns error? {
    LibrarySongsResponse response = check clientEp->/v1/me/library/songs/lib\-thinking\-out\-loud();
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
    test:assertEquals(response.data[0].id, "lib-thinking-out-loud");
    test:assertEquals(response.data[0].attributes.name, "Thinking Out Loud");
    test:assertEquals(response.data[0].attributes.artistName, "Ed Sheeran");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetLibrarySongWithParams() returns error? {
    LibrarySongsResponse response = check clientEp->/v1/me/library/songs/lib\-thinking\-out\-loud(
        extend = ["attributes"],
        include = ["albums", "artists"],
        l = "en-US"
    );
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetLibrarySongRelationship() returns error? {
    LibrarySongsResponse response = check clientEp->/v1/me/library/songs/lib\-thinking\-out\-loud/albums();
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetLibrarySongRelationshipWithLimit() returns error? {
    LibrarySongsResponse response = check clientEp->/v1/me/library/songs/lib\-thinking\-out\-loud/artists(
        'limit = 1,
        extend = ["attributes"]
    );
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
}

// LIBRARY MODIFICATION TESTS

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testAddResourceToLibrary() returns error? {
    http:Response response = check clientEp->/v1/me/library.post(ids = ["1440857781", "159260351"]);
    test:assertEquals(response.statusCode, 202);
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testAddMultipleResourceTypesToLibrary() returns error? {
    http:Response response = check clientEp->/v1/me/library.post(
        ids = ["1440857781", "159260351", "1440857915"]
    );
    test:assertEquals(response.statusCode, 202);
}

// STOREFRONT VARIATION TESTS

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetAlbumsFromDifferentStorefront() returns error? {
    AlbumsResponse response = check clientEp->/v1/catalog/gb/albums(ids = ["1440857781"]);
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
    test:assertTrue(response.data.length() > 0);
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetArtistsFromDifferentStorefront() returns error? {
    ArtistsResponse response = check clientEp->/v1/catalog/jp/artists(ids = ["159260351"]);
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
    test:assertTrue(response.data.length() > 0);
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testSearchInDifferentStorefront() returns error? {
    SearchResponse response = check clientEp->/v1/catalog/ca/search(
        term = "taylor+swift",
        types = ["albums", "artists"]
    );
    test:assertTrue(response?.results !is ());
}

// EDGE CASES AND ERROR SCENARIOS

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetAlbumWithEmptyIds() returns error? {
    AlbumsResponse response = check clientEp->/v1/catalog/us/albums();
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetArtistWithAllViewTypes() returns error? {
    ArtistsResponse response = check clientEp->/v1/catalog/us/artists/159260351(
        views = [
            "appears-on-albums", 
            "compilation-albums", 
            "featured-albums", 
            "featured-playlists", 
            "full-albums", 
            "latest-release", 
            "live-albums", 
            "similar-artists", 
            "singles", 
            "top-music-videos", 
            "top-songs"
        ]
    );
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetAlbumWithAllViewTypes() returns error? {
    AlbumsResponse response = check clientEp->/v1/catalog/us/albums/1440857781(
        views = ["appears-on", "other-versions", "related-albums", "related-videos"]
    );
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testSearchWithAllResourceTypes() returns error? {
    SearchResponse response = check clientEp->/v1/catalog/us/search(
        term = "music",
        types = [
            "activities", 
            "albums", 
            "apple-curators", 
            "artists", 
            "curators", 
            "music-videos", 
            "playlists", 
            "record-labels", 
            "songs", 
            "stations"
        ]
    );
    test:assertTrue(response?.results !is ());
}

// PARAMETER COMBINATION TESTS

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetAlbumsWithAllOptionalParams() returns error? {
    AlbumsResponse response = check clientEp->/v1/catalog/us/albums(
        ids = ["1440857781"],
        extend = ["attributes"],
        filter = ["genre"],
        include = ["artists"],
        l = "en-US",
        restrict = ["explicit"]
    );
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetArtistsWithAllOptionalParams() returns error? {
    ArtistsResponse response = check clientEp->/v1/catalog/us/artists(
        ids = ["159260351"],
        extend = ["attributes"],
        filter = ["genre"],
        include = ["albums"],
        l = "en-US",
        restrict = ["explicit"]
    );
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetSongsWithAllOptionalParams() returns error? {
    SongsResponse response = check clientEp->/v1/catalog/us/songs(
        ids = ["1440857915"],
        extend = ["attributes"],
        filter = ["explicit"],
        include = ["albums", "artists"],
        l = "en-US",
        restrict = ["clean"]
    );
    test:assertTrue(response?.data !is ());
    test:assertTrue(response?.errors is ());
}

// RELATIONSHIP TESTS FOR ALL SUPPORTED TYPES

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetAlbumAllRelationshipTypes() returns error? {
    // Test artists relationship
    ArtistsResponse artistsResponse = check clientEp->/v1/catalog/us/albums/1440857781/artists();
    test:assertTrue(artistsResponse?.data !is ());
    
    // Test other relationships (will return empty but should not error)
    ArtistsResponse genresResponse = check clientEp->/v1/catalog/us/albums/1440857781/genres();
    test:assertTrue(genresResponse?.data !is ());
    
    ArtistsResponse tracksResponse = check clientEp->/v1/catalog/us/albums/1440857781/tracks();
    test:assertTrue(tracksResponse?.data !is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetArtistAllRelationshipTypes() returns error? {
    // Test albums relationship
    AlbumsResponse albumsResponse = check clientEp->/v1/catalog/us/artists/5468295/albums();
    test:assertTrue(albumsResponse?.data !is ());
    
    // Test other relationships (will return empty but should not error)
    AlbumsResponse genresResponse = check clientEp->/v1/catalog/us/artists/5468295/genres();
    test:assertTrue(genresResponse?.data !is ());
    
    AlbumsResponse playlistsResponse = check clientEp->/v1/catalog/us/artists/5468295/playlists();
    test:assertTrue(playlistsResponse?.data !is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
function testGetSongAllRelationshipTypes() returns error? {
    // Test all song relationship types (will return empty but should not error)
    SongsResponse albumsResponse = check clientEp->/v1/catalog/us/songs/1708284055/albums();
    test:assertTrue(albumsResponse?.data !is ());
    
    SongsResponse artistsResponse = check clientEp->/v1/catalog/us/songs/1708284055/artists();
    test:assertTrue(artistsResponse?.data !is ());
    
    SongsResponse genresResponse = check clientEp->/v1/catalog/us/songs/1708284055/genres();
    test:assertTrue(genresResponse?.data !is ());
}
