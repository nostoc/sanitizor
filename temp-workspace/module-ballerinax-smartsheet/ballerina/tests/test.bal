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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/os;
import ballerina/test;

configurable boolean isLiveServer = os:getEnv("IS_LIVE_SERVER") == "true";
configurable string token = isLiveServer ? os:getEnv("SMARTSHEET_TOKEN") : "test-token";
configurable string serviceUrl = isLiveServer ? "https://api.smartsheet.com/2.0" : "http://localhost:9090";

ConnectionConfig config = {auth: {token}};
final Client smartsheet = check new Client(config, serviceUrl);

final decimal testSheetId = 123456789;
final decimal testFolderId = 987654321;
final decimal testRowId = 111222333;
final decimal testColumnId = 444555666;
final string testUserId = "test-user-123";

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetSheets() returns error? {
    AlternateEmailListResponse response = check smartsheet->/sheets();
    test:assertTrue(response.data !is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetSheet() returns error? {
    anydata response = check smartsheet->/sheets/[testSheetId]();
    test:assertTrue(response !is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testDeleteSheet() returns error? {
    SuccessResult response = check smartsheet->/sheets/[testSheetId].delete();
    test:assertTrue(response.message !is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testUpdateSheet() returns error? {
    UpdateSheet payload = {
        name: "Updated Test Sheet"
    };
    AttachmentListResponse response = check smartsheet->/sheets/[testSheetId].put(payload);
    test:assertTrue(response.result !is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetColumns() returns error? {
    ColumnListResponse response = check smartsheet->/sheets/[testSheetId]/columns();
    test:assertTrue(response.data !is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testAddColumns() returns error? {
    ColumnObjectAttributes payload = {
        title: "New Column",
        'type: "TEXT_NUMBER",
        index: 1
    };
    ColumnCreateResponse response = check smartsheet->/sheets/[testSheetId]/columns.post(payload);
    test:assertTrue(response.result !is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetRow() returns error? {
    RowResponse response = check smartsheet->/sheets/[testSheetId]/rows/[testRowId]();
    test:assertTrue(response.id !is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testAddRows() returns error? {
    Row payload = {
        cells: [
            {
                columnId: testColumnId,
                value: "Test Cell Value"
            }
        ]
    };
    RowMoveResponse response = check smartsheet->/sheets/[testSheetId]/rows.post(payload);
    test:assertTrue(response.result !is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testUpdateRows() returns error? {
    Row payload = {
        id: testRowId,
        cells: [
            {
                columnId: testColumnId,
                value: "Updated Cell Value"
            }
        ]
    };
    RowCopyResponse response = check smartsheet->/sheets/[testSheetId]/rows.put(payload);
    test:assertTrue(response.result !is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testDeleteRows() returns error? {
    RowListResponse response = check smartsheet->/sheets/[testSheetId]/rows.delete(ids = testRowId.toString());
    test:assertTrue(response.result !is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetFolder() returns error? {
    Folder response = check smartsheet->/folders/[testFolderId]();
    test:assertTrue(response.id !is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetUsers() returns error? {
    UserListResponse response = check smartsheet->/users();
    test:assertTrue(response.data !is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetCurrentUser() returns error? {
    UserImgProfileResponse response = check smartsheet->/users/me();
    test:assertTrue(response.data !is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetWorkspaces() returns error? {
    WorkspaceShareListResponse response = check smartsheet->/workspaces();
    test:assertTrue(response.data !is ());
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testErrorHandling() {
    decimal invalidSheetId = 999999999;
    anydata|error response = smartsheet->/sheets/[invalidSheetId]();
    test:assertTrue(response !is error);
}
