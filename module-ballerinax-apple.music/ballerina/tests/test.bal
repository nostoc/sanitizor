// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).
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

configurable boolean isLiveServer = false;
configurable string serviceUrl = isLiveServer ? "https://api.music.apple.com/v1" : "http://localhost:9090/v1";
configurable string token = isLiveServer ? "" : "test-token";

final Client apple = check new Client({
    authorization: token,
    musicUserToken: token},
    {}, serviceUrl);

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetMultipleCatalogAlbums() returns error? {
    AlbumsResponse response = check apple->/catalog/["us"]/albums(ids = ["1234567890"]);
    test:assertTrue(response.data.length() > 0);
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetCatalogAlbum() returns error? {
    AlbumsResponse response = check apple->/catalog/["us"]/albums/["1234567890"]();
    test:assertTrue(response.data.length() > 0);

}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetCatalogAlbumRelationship() returns error? {
    ArtistsResponse response = check apple->/catalog/["us"]/albums/["1234567890"]/["artists"]();
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetCatalogAlbumView() returns error? {
    MusicVideosResponse response = check apple->/catalog/["us"]/albums/["1234567890"]/view/["related-videos"]();
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetMultipleCatalogArtists() returns error? {
    ArtistsResponse response = check apple->/catalog/["us"]/artists(ids = ["artist123"]);
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetCatalogArtist() returns error? {
    ArtistsResponse response = check apple->/catalog/["us"]/artists/["artist123"]();
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetCatalogArtistRelationship() returns error? {
    AlbumsResponse response = check apple->/catalog/["us"]/artists/["artist123"]/["albums"]();
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetCatalogArtistView() returns error? {
    AlbumsResponse response = check apple->/catalog/["us"]/artists/["artist123"]/view/["full-albums"]();
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testSearchCatalogResources() returns error? {
    SearchResponse response = check apple->/catalog/["us"]/search(term = "taylor+swift");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetMultipleCatalogSongs() returns error? {
    SongsResponse response = check apple->/catalog/["us"]/songs(ids = ["song123"]);
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetCatalogSong() returns error? {
    SongsResponse response = check apple->/catalog/["us"]/songs/["song123"]();
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetCatalogSongRelationship() returns error? {
    SongsResponse response = check apple->/catalog/["us"]/songs/["song123"]/["albums"]();
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetAllLibraryAlbums() returns error? {
    LibraryAlbumsResponse response = check apple->/me/library/albums();
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetLibraryAlbum() returns error? {
    LibraryAlbumsResponse response = check apple->/me/library/albums/["lib123"]();
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetLibraryAlbumRelationship() returns error? {
    LibraryArtistsResponse response = check apple->/me/library/albums/["lib123"]/["artists"]();
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetAllLibraryArtists() returns error? {
    LibraryArtistsResponse response = check apple->/me/library/artists();
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetLibraryArtist() returns error? {
    LibraryArtistsResponse response = check apple->/me/library/artists/["libArtist456"]();
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetLibraryArtistRelationship() returns error? {
    LibraryAlbumsResponse response = check apple->/me/library/artists/["libArtist456"]/["albums"]();
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetAllLibrarySongs() returns error? {
    LibrarySongsResponse response = check apple->/me/library/songs();
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetLibrarySong() returns error? {
    LibrarySongsResponse response = check apple->/me/library/songs/["libSong123"]();
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetLibrarySongRelationship() returns error? {
    LibrarySongsResponse response = check apple->/me/library/songs/["libSong123"]/["albums"]();
}

