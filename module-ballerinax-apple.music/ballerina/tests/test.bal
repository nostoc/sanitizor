// Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import apple.music.mock.server as _;

import ballerina/test;

// Configurable variables for testing
configurable string serviceUrl = "http://localhost:9090/v1";
configurable string token = "test_token";
configurable string storefront = "us";

// Test client configuration
final Client appleMusic = check new Client({
    authorization: token,
    musicUserToken: token
}, {}, serviceUrl);

// Test data
final string testAlbumId = "1234567890";
final string testArtistId = "artist123";
final string testSongId = "song123";
final string testLibraryAlbumId = "lib001";
final string testLibraryArtistId = "libartist001";
final string testLibrarySongId = "libsong001";
final string[] testIds = ["1234567890", "0987654321"];

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetMultipleCatalogAlbums() returns error? {
    AlbumsResponse response = check appleMusic->/catalog/[storefront]/albums(ids = testIds);
    test:assertTrue(response?.data is AlbumsResponse[]);
    //test:assertTrue(response?.errors is ());
}

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetCatalogAlbum() returns error? {
//     AlbumsResponse response = check appleMusic->/catalog/[storefront]/albums/[testAlbumId]();
//     test:assertTrue(response?.data is AlbumsResponse[]);
//     // test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetCatalogAlbumWithViews() returns error? {
//     AlbumsResponse response = check appleMusic->/catalog/[storefront]/albums/[testAlbumId](views = ["appears-on", "other-versions"]);
//     test:assertTrue(response?.data is AlbumsResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetCatalogAlbumRelationship() returns error? {
//     ArtistsResponse response = check appleMusic->/catalog/[storefront]/albums/[testAlbumId]/artists();
//     test:assertTrue(response?.data is ArtistsResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetCatalogAlbumRelationshipWithLimit() returns error? {
//     ArtistsResponse response = check appleMusic->/catalog/[storefront]/albums/[testAlbumId]/artists('limit = 10);
//     test:assertTrue(response?.data !is AlbumsResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetCatalogAlbumRelationshipView() returns error? {
//     MusicVideosResponse response = check appleMusic->/catalog/[storefront]/albums/[testAlbumId]/view/["appears-on"]();
//     test:assertTrue(response?.data is MusicVideosResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetCatalogAlbumRelationshipViewWithParams() returns error? {
//     MusicVideosResponse response = check appleMusic->/catalog/[storefront]/albums/[testAlbumId]/view/["related-videos"]('limit = 3, with = ["attributes"]);
//     test:assertTrue(response?.data is MusicVideosResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetMultipleCatalogArtists() returns error? {
//     ArtistsResponse response = check appleMusic->/catalog/[storefront]/artists(ids = testIds);
//     test:assertTrue(response?.data is ArtistsResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetCatalogArtist() returns error? {
//     ArtistsResponse response = check appleMusic->/catalog/[storefront]/artists/[testArtistId]();
//     test:assertTrue(response?.data is ArtistsResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetCatalogArtistWithViews() returns error? {
//     ArtistsResponse response = check appleMusic->/catalog/[storefront]/artists/[testArtistId](views = ["full-albums", "top-songs"]);
//     test:assertTrue(response?.data is ArtistsResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetCatalogArtistRelationship() returns error? {
//     AlbumsResponse response = check appleMusic->/catalog/[storefront]/artists/[testArtistId]/albums();
//     test:assertTrue(response?.data is AlbumsResponse[]);
//     // test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetCatalogArtistRelationshipView() returns error? {
//     AlbumsResponse response = check appleMusic->/catalog/[storefront]/artists/[testArtistId]/view/["full-albums"]();
//     test:assertTrue(response?.data is AlbumsResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testSearchCatalog() returns error? {
//     SearchResponse response = check appleMusic->/catalog/[storefront]/search(term = "taylor+swift");
//     test:assertTrue(response?.results is SearchResponse);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testSearchCatalogWithTypes() returns error? {
//     SearchResponse response = check appleMusic->/catalog/[storefront]/search(term = "billie+eilish", types = ["albums", "artists"]);
//     test:assertTrue(response?.results is SearchResponse);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testSearchCatalogWithLimit() returns error? {
//     SearchResponse response = check appleMusic->/catalog/[storefront]/search(term = "pop+music", 'limit = 10);
//     test:assertTrue(response?.results is SearchResponse);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetMultipleCatalogSongs() returns error? {
//     SongsResponse response = check appleMusic->/catalog/[storefront]/songs(ids = testIds);
//     test:assertTrue(response?.data is SongsResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetCatalogSong() returns error? {
//     SongsResponse response = check appleMusic->/catalog/[storefront]/songs/[testSongId]();
//     test:assertTrue(response?.data is SongsResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetCatalogSongWithInclude() returns error? {
//     SongsResponse response = check appleMusic->/catalog/[storefront]/songs/[testSongId](include = ["albums", "artists"]);
//     test:assertTrue(response?.data is SongsResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetCatalogSongRelationship() returns error? {
//     SongsResponse response = check appleMusic->/catalog/[storefront]/songs/[testSongId]/albums();
//     test:assertTrue(response?.data is SongsResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetAllLibraryAlbums() returns error? {
//     LibraryAlbumsResponse response = check appleMusic->/me/library/albums();
//     test:assertTrue(response?.data is LibraryAlbumsResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetAllLibraryAlbumsWithIds() returns error? {
//     LibraryAlbumsResponse response = check appleMusic->/me/library/albums(ids = testIds);
//     test:assertTrue(response?.data is LibraryAlbumsResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetAllLibraryAlbumsWithLimit() returns error? {
//     LibraryAlbumsResponse response = check appleMusic->/me/library/albums('limit = 10);
//     test:assertTrue(response?.data is LibraryAlbumsResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetLibraryAlbum() returns error? {
//     LibraryAlbumsResponse response = check appleMusic->/me/library/albums/[testLibraryAlbumId]();
//     test:assertTrue(response?.data is LibraryAlbumsResponse[]);
//     // test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetLibraryAlbumRelationship() returns error? {
//     LibraryArtistsResponse response = check appleMusic->/me/library/albums/[testLibraryAlbumId]/artists();
//     test:assertTrue(response?.data is LibraryArtistsResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetAllLibraryArtists() returns error? {
//     LibraryArtistsResponse response = check appleMusic->/me/library/artists();
//     test:assertTrue(response?.data is LibraryArtistsResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetAllLibraryArtistsWithIds() returns error? {
//     LibraryArtistsResponse response = check appleMusic->/me/library/artists(ids = testIds);
//     test:assertTrue(response?.data is LibraryArtistsResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetLibraryArtist() returns error? {
//     LibraryArtistsResponse response = check appleMusic->/me/library/artists/[testLibraryArtistId]();
//     test:assertTrue(response?.data is LibraryArtistsResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetLibraryArtistRelationship() returns error? {
//     LibraryAlbumsResponse response = check appleMusic->/me/library/artists/[testLibraryArtistId]/albums();
//     test:assertTrue(response?.data is LibraryAlbumsResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetAllLibrarySongs() returns error? {
//     LibrarySongsResponse response = check appleMusic->/me/library/songs();
//     test:assertTrue(response?.data is LibrarySongsResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetAllLibrarySongsWithIds() returns error? {
//     LibrarySongsResponse response = check appleMusic->/me/library/songs(ids = testIds);
//     test:assertTrue(response?.data is LibrarySongsResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetLibrarySong() returns error? {
//     LibrarySongsResponse response = check appleMusic->/me/library/songs/[testLibrarySongId]();
//     test:assertTrue(response?.data is LibrarySongsResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetLibrarySongRelationship() returns error? {
//     LibrarySongsResponse response = check appleMusic->/me/library/songs/[testLibrarySongId]/albums();
//     test:assertTrue(response?.data is LibrarySongsResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// // @test:Config {
// //     groups: ["live_tests", "mock_tests"]
// // }
// // isolated function testAddResourceToLibrary() returns error? {
// //     http:Accepted response = check appleMusic->/me/library.post(ids = ["1234567890", "0987654321"]);
// //     test:assertTrue(response !is ());
// // }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetCatalogAlbumsWithExtendAndFilter() returns error? {
//     AlbumsResponse response = check appleMusic->/catalog/[storefront]/albums(
//         ids = testIds,
//         extend = ["editorialNotes"],
//         filter = ["explicit"]
//     );
//     test:assertTrue(response?.data is AlbumsResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetCatalogArtistsWithLocalization() returns error? {
//     ArtistsResponse response = check appleMusic->/catalog/[storefront]/artists(
//         ids = testIds,
//         l = "en-US"
//     );
//     test:assertTrue(response?.data is ArtistsResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetCatalogSongsWithRestrictions() returns error? {
//     SongsResponse response = check appleMusic->/catalog/[storefront]/songs(
//         ids = testIds,
//         restrict = ["explicit"]
//     );
//     test:assertTrue(response?.data is SongsResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetLibraryAlbumsWithOffset() returns error? {
//     LibraryAlbumsResponse response = check appleMusic->/me/library/albums(
//         'limit = 5,
//         offset = "10"
//     );
//     test:assertTrue(response?.data is LibraryAlbumsResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetLibraryArtistsWithExtend() returns error? {
//     LibraryArtistsResponse response = check appleMusic->/me/library/artists(
//         extend = ["bornOrFormed"],
//         'limit = 3
//     );
//     test:assertTrue(response?.data is LibraryArtistsResponse[]);
//     // test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testGetLibrarySongsWithInclude() returns error? {
//     LibrarySongsResponse response = check appleMusic->/me/library/songs(
//         include = ["albums", "artists"],
//         'limit = 8
//     );
//     test:assertTrue(response?.data is LibrarySongsResponse[]);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testSearchCatalogWithOffset() returns error? {
//     SearchResponse response = check appleMusic->/catalog/[storefront]/search(
//         term = "rock+music",
//         types = ["albums", "songs"],
//         'limit = 15,
//         offset = "5"
//     );
//     test:assertTrue(response?.results is SearchResponse);
//     //test:assertTrue(response?.errors is ());
// }

// @test:Config {
//     groups: ["live_tests", "mock_tests"]
// }
// isolated function testSearchCatalogWithWith() returns error? {
//     SearchResponse response = check appleMusic->/catalog/[storefront]/search(
//         term = "jazz+classics",
//         with = ["topResults", "attributes"]
//     );
//     test:assertTrue(response?.results is SearchResponse);
//     //test:assertTrue(response?.errors is ());
// }
