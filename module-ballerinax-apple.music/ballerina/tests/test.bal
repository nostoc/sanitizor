

import ballerina/http;
import ballerina/test;

// HTTP client configuration for testing
final http:Client clientEp = check new ("http://localhost:9090/api");

// Test Scenario 1.1: GET /catalog/{storefront}/albums - Happy Path
// Validates retrieval of multiple albums with basic query parameters
@test:Config {}
function testGetMultipleCatalogAlbumsHappyPath() returns error? {
    // Action: Send GET request with ids query parameter
    AlbumsResponse response = check clientEp->/catalog/us/albums(ids = ["1234567890"]);

    // Validation: Verify response structure and data
    test:assertEquals(response.data.length(), 1, "Response should contain one album");
    
    Albums album = response.data[0];
    test:assertEquals(album.id, "1234567890", "Album ID should match requested ID");
    test:assertEquals(album.'type, "albums", "Type should be 'albums'");
    test:assertEquals(album.href, "/v1/catalog/us/albums/1234567890", "Href should be properly formatted");
    
    // Validate attributes
    AlbumsAttributes? attributes = album.attributes;
    test:assertEquals(attributes is AlbumsAttributes, true, "Attributes should be present");
    if attributes is AlbumsAttributes {
        test:assertEquals(attributes.name, "Sample Album", "Album name should match");
        test:assertEquals(attributes.artistName, "Sample Artist", "Artist name should match");
        test:assertEquals(attributes.genreNames.length(), 2, "Should have 2 genres");
        test:assertEquals(attributes.genreNames[0], "Pop", "First genre should be Pop");
        test:assertEquals(attributes.genreNames[1], "Rock", "Second genre should be Rock");
        test:assertEquals(attributes.releaseDate, "2023-01-01", "Release date should match");
        test:assertEquals(attributes.trackCount, 12d, "Track count should be 12");
        test:assertEquals(attributes.isComplete, true, "Album should be complete");
        test:assertEquals(attributes.isSingle, false, "Album should not be a single");
        test:assertEquals(attributes.isCompilation, false, "Album should not be a compilation");
        test:assertEquals(attributes.isMasteredForItunes, true, "Album should be mastered for iTunes");
        test:assertEquals(attributes.copyright, "℗ 2023 Sample Records", "Copyright should match");
        test:assertEquals(attributes.url, "https://music.apple.com/album/sample-album/1234567890", "URL should match");
        
        // Validate artwork
        Artwork artwork = attributes.artwork;
        test:assertEquals(artwork.width, 1000d, "Artwork width should be 1000");
        test:assertEquals(artwork.height, 1000d, "Artwork height should be 1000");
        test:assertEquals(artwork.url, "https://is1-ssl.mzstatic.com/image/thumb/sample.jpg", "Artwork URL should match");
        
        // Validate playParams
        PlayParameters? playParams = attributes.playParams;
        test:assertEquals(playParams is PlayParameters, true, "PlayParams should be present");
        if playParams is PlayParameters {
            test:assertEquals(playParams.id, "1234567890", "PlayParams ID should match");
            test:assertEquals(playParams.kind, "album", "PlayParams kind should be album");
        }
        
        // Validate editorialNotes
        EditorialNotes? editorialNotes = attributes.editorialNotes;
        test:assertEquals(editorialNotes is EditorialNotes, true, "Editorial notes should be present");
        if editorialNotes is EditorialNotes {
            test:assertEquals(editorialNotes.standard, "A fantastic album by Sample Artist.", "Standard notes should match");
            test:assertEquals(editorialNotes.short, "Great album", "Short notes should match");
        }
    }
}

// Test Scenario 1.2: GET /catalog/{storefront}/albums - Happy Path with Optional Parameters
// Validates that optional parameters are accepted without errors
@test:Config {}
function testGetMultipleCatalogAlbumsWithOptionalParameters() returns error? {
    // Action: Send GET request with all optional parameters
    AlbumsResponse response = check clientEp->/catalog/us/albums(
        ids = ["1234567890"],
        extend = ["credits"],
        include = ["artists"],
        l = "en-US",
        restrict = ["explicit"]
    );

    // Validation: Verify response is returned successfully with same structure
    test:assertEquals(response.data.length(), 1, "Response should contain one album");
    
    Albums album = response.data[0];
    test:assertEquals(album.id, "1234567890", "Album ID should match");
    test:assertEquals(album.'type, "albums", "Type should be 'albums'");
    
    // Verify attributes are present
    AlbumsAttributes? attributes = album.attributes;
    test:assertEquals(attributes is AlbumsAttributes, true, "Attributes should be present");
    if attributes is AlbumsAttributes {
        test:assertEquals(attributes.name, "Sample Album", "Album name should match");
        test:assertEquals(attributes.artistName, "Sample Artist", "Artist name should match");
    }
}

// Test Scenario 2.1: GET /catalog/{storefront}/albums/{id} - Happy Path
// Validates retrieval of a single album by ID
@test:Config {}
function testGetSingleCatalogAlbumHappyPath() returns error? {
    // Action: Send GET request for specific album ID
    AlbumsResponse response = check clientEp->/catalog/us/albums/["9876543210"]();

    // Validation: Verify response structure and dynamic construction
    test:assertEquals(response.data.length(), 1, "Response should contain one album");
    
    Albums album = response.data[0];
    test:assertEquals(album.id, "9876543210", "Album ID should match path parameter");
    test:assertEquals(album.'type, "albums", "Type should be 'albums'");
    test:assertEquals(album.href, "/v1/catalog/us/albums/9876543210", "Href should be dynamically constructed with storefront and id");
    
    // Validate attributes
    AlbumsAttributes? attributes = album.attributes;
    test:assertEquals(attributes is AlbumsAttributes, true, "Attributes should be present");
    if attributes is AlbumsAttributes {
        test:assertEquals(attributes.name, "Single Album", "Album name should be 'Single Album'");
        test:assertEquals(attributes.artistName, "Single Artist", "Artist name should be 'Single Artist'");
        test:assertEquals(attributes.genreNames.length(), 1, "Should have 1 genre");
        test:assertEquals(attributes.genreNames[0], "Electronic", "Genre should be Electronic");
        test:assertEquals(attributes.releaseDate, "2023-06-15", "Release date should match");
        test:assertEquals(attributes.trackCount, 10d, "Track count should be 10");
        test:assertEquals(attributes.isComplete, true, "Album should be complete");
        test:assertEquals(attributes.isSingle, false, "Album should not be a single");
        test:assertEquals(attributes.isCompilation, false, "Album should not be a compilation");
        test:assertEquals(attributes.isMasteredForItunes, false, "Album should not be mastered for iTunes");
        test:assertEquals(attributes.url, "https://music.apple.com/album/single-album/9876543210", "URL should be dynamically constructed");
        
        // Validate artwork
        Artwork artwork = attributes.artwork;
        test:assertEquals(artwork.width, 800d, "Artwork width should be 800");
        test:assertEquals(artwork.height, 800d, "Artwork height should be 800");
        test:assertEquals(artwork.url, "https://is1-ssl.mzstatic.com/image/thumb/single.jpg", "Artwork URL should match");
        
        // Validate playParams
        PlayParameters? playParams = attributes.playParams;
        test:assertEquals(playParams is PlayParameters, true, "PlayParams should be present");
        if playParams is PlayParameters {
            test:assertEquals(playParams.id, "9876543210", "PlayParams ID should match album ID");
            test:assertEquals(playParams.kind, "album", "PlayParams kind should be album");
        }
    }
}

// Test Scenario 2.2: GET /catalog/{storefront}/albums/{id} - Happy Path with Views and Optional Parameters
// Validates that views and optional parameters are accepted for different storefronts
@test:Config {}
function testGetSingleCatalogAlbumWithViewsAndOptionalParameters() returns error? {
    // Action: Send GET request with views and optional parameters for different storefront
    AlbumsResponse response = check clientEp->/catalog/gb/albums/["5555555555"](
        views = ["appears-on", "related-albums"],
        extend = ["bios"],
        include = ["tracks"],
        l = "en-GB"
    );

    // Validation: Verify response structure is consistent with different storefront
    test:assertEquals(response.data.length(), 1, "Response should contain one album");
    
    Albums album = response.data[0];
    test:assertEquals(album.id, "5555555555", "Album ID should match path parameter");
    test:assertEquals(album.'type, "albums", "Type should be 'albums'");
    test:assertEquals(album.href, "/v1/catalog/gb/albums/5555555555", "Href should use 'gb' storefront parameter");
    
    // Verify attributes are present
    AlbumsAttributes? attributes = album.attributes;
    test:assertEquals(attributes is AlbumsAttributes, true, "Attributes should be present");
}

// Test Scenario 3.1: GET /catalog/{storefront}/albums/{id}/{relationship} - Happy Path Artists Relationship
// Validates retrieval of album's artist relationship
@test:Config {}
function testGetAlbumArtistsRelationshipHappyPath() returns error? {
    // Action: Send GET request for artists relationship
    ArtistsResponse response = check clientEp->/catalog/us/albums/["1234567890"]/artists();

    // Validation: Verify response structure matches ArtistsResponse
    test:assertEquals(response.data.length(), 1, "Response should contain one artist");
    
    Artists artist = response.data[0];
    test:assertEquals(artist.id, "artist123", "Artist ID should be 'artist123'");
    test:assertEquals(artist.'type, "artists", "Type should be 'artists'");
    test:assertEquals(artist.href, "/v1/catalog/us/artists/artist123", "Href should be properly formatted with storefront");
    
    // Validate attributes
    ArtistsAttributes? attributes = artist.attributes;
    test:assertEquals(attributes is ArtistsAttributes, true, "Attributes should be present");
    if attributes is ArtistsAttributes {
        test:assertEquals(attributes.name, "Related Artist", "Artist name should be 'Related Artist'");
        test:assertEquals(attributes.genreNames.length(), 2, "Should have 2 genres");
        test:assertEquals(attributes.genreNames[0], "Pop", "First genre should be Pop");
        test:assertEquals(attributes.genreNames[1], "Electronic", "Second genre should be Electronic");
        test:assertEquals(attributes.url, "https://music.apple.com/artist/related-artist/artist123", "URL should match");
        
        // Validate editorialNotes
        EditorialNotes? editorialNotes = attributes.editorialNotes;
        test:assertEquals(editorialNotes is EditorialNotes, true, "Editorial notes should be present");
        if editorialNotes is EditorialNotes {
            test:assertEquals(editorialNotes.standard, "A talented artist with multiple hits.", "Standard notes should match");
        }
    }
}

// Test Scenario 3.2: GET /catalog/{storefront}/albums/{id}/{relationship} - Different Relationships with Custom Limit
// Validates different relationship types with custom parameters
@test:Config {}
function testGetAlbumTracksRelationshipWithCustomParameters() returns error? {
    // Action: Send GET request for tracks relationship with custom parameters
    ArtistsResponse response = check clientEp->/catalog/jp/albums/["9999999999"]/tracks(
        'limit = 10,
        extend = ["lyrics"],
        include = ["albums"],
        l = "ja-JP"
    );

    // Validation: Verify response is returned successfully
    test:assertEquals(response.data.length(), 1, "Response should contain data");
    
    Artists artist = response.data[0];
    test:assertEquals(artist.id, "artist123", "Artist ID should be present");
    test:assertEquals(artist.'type, "artists", "Type should be 'artists'");
    test:assertEquals(artist.href, "/v1/catalog/jp/artists/artist123", "Href should use 'jp' storefront parameter");
}

// Test Scenario 3.2 (Additional): Test genres relationship
@test:Config {}
function testGetAlbumGenresRelationship() returns error? {
    // Action: Send GET request for genres relationship
    ArtistsResponse response = check clientEp->/catalog/us/albums/["1234567890"]/genres();

    // Validation: Verify response is returned successfully for genres relationship
    test:assertEquals(response.data.length(), 1, "Response should contain data");
    
    Artists artist = response.data[0];
    test:assertEquals(artist.'type, "artists", "Type should be 'artists'");
}

// Test Scenario 3.2 (Additional): Test library relationship
@test:Config {}
function testGetAlbumLibraryRelationship() returns error? {
    // Action: Send GET request for library relationship
    ArtistsResponse response = check clientEp->/catalog/us/albums/["1234567890"]/library();

    // Validation: Verify response is returned successfully for library relationship
    test:assertEquals(response.data.length(), 1, "Response should contain data");
}

// Test Scenario 3.2 (Additional): Test record-labels relationship
@test:Config {}
function testGetAlbumRecordLabelsRelationship() returns error? {
    // Action: Send GET request for record-labels relationship
    ArtistsResponse response = check clientEp->/catalog/us/albums/["1234567890"]/["record-labels"]();

    // Validation: Verify response is returned successfully for record-labels relationship
    test:assertEquals(response.data.length(), 1, "Response should contain data");
}

// Test Scenario 4.1: GET /catalog/{storefront}/albums/{id}/view/{view} - Happy Path Related Videos View
// Validates retrieval of album's related videos view
@test:Config {}
function testGetAlbumRelatedVideosViewHappyPath() returns error? {
    // Action: Send GET request for related-videos view
    MusicVideosResponse response = check clientEp->/catalog/us/albums/["1234567890"]/view/["related-videos"]();

    // Validation: Verify response structure matches MusicVideosResponse
    test:assertEquals(response.data.length(), 1, "Response should contain data array");
    
    MusicVideos musicVideo = response.data[0];
    test:assertEquals(musicVideo.'type, "music-videos", "Type should be 'music-videos'");
    test:assertEquals(musicVideo.id is string, true, "ID field should be present");
    test:assertEquals(musicVideo.href is string, true, "Href field should be present");
}

// Test Scenario 4.2: GET /catalog/{storefront}/albums/{id}/view/{view} - Different Views with Optional Parameters
// Validates different view types with custom parameters
@test:Config {}
function testGetAlbumAppearsOnViewWithOptionalParameters() returns error? {
    // Action: Send GET request for appears-on view with optional parameters
    MusicVideosResponse response = check clientEp->/catalog/fr/albums/["7777777777"]/view/["appears-on"](
        'limit = 15,
        with = ["attributes", "topResults"],
        extend = ["details"],
        include = ["artists"],
        l = "fr-FR"
    );

    // Validation: Verify response is returned successfully for appears-on view
    test:assertEquals(response.data.length(), 1, "Response should contain data array");
    
    MusicVideos musicVideo = response.data[0];
    test:assertEquals(musicVideo.'type, "music-videos", "Type should be 'music-videos'");
}

// Test Scenario 4.2 (Additional): Test other-versions view
@test:Config {}
function testGetAlbumOtherVersionsView() returns error? {
    // Action: Send GET request for other-versions view
    MusicVideosResponse response = check clientEp->/catalog/us/albums/["1234567890"]/view/["other-versions"]();

    // Validation: Verify response is returned successfully for other-versions view
    test:assertEquals(response.data.length(), 1, "Response should contain data array");
    test:assertEquals(response.data[0].'type, "music-videos", "Type should be 'music-videos'");
}

// Test Scenario 4.2 (Additional): Test related-albums view
@test:Config {}
function testGetAlbumRelatedAlbumsView() returns error? {
    // Action: Send GET request for related-albums view
    MusicVideosResponse response = check clientEp->/catalog/us/albums/["1234567890"]/view/["related-albums"]();

    // Validation: Verify response is returned successfully for related-albums view
    test:assertEquals(response.data.length(), 1, "Response should contain data array");
    test:assertEquals(response.data[0].'type, "music-videos", "Type should be 'music-videos'");
}

// Additional test: Verify storefront parameter handling with different country codes
@test:Config {}
function testStorefrontParameterHandling() returns error? {
    // Test with Japanese storefront
    AlbumsResponse jpResponse = check clientEp->/catalog/jp/albums/["1234567890"]();
    test:assertEquals(jpResponse.data[0].href, "/v1/catalog/jp/albums/1234567890", "Href should use 'jp' storefront");
    
    // Test with French storefront
    AlbumsResponse frResponse = check clientEp->/catalog/fr/albums/["1234567890"]();
    test:assertEquals(frResponse.data[0].href, "/v1/catalog/fr/albums/1234567890", "Href should use 'fr' storefront");
    
    // Test with German storefront
    AlbumsResponse deResponse = check clientEp->/catalog/de/albums/["1234567890"]();
    test:assertEquals(deResponse.data[0].href, "/v1/catalog/de/albums/1234567890", "Href should use 'de' storefront");
}
