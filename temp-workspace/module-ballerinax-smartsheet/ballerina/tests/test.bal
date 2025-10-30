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

import ballerina/os;
import ballerina/test;
import smartsheet.mock.server as _;

configurable boolean isLiveServer = os:getEnv("IS_LIVE_SERVER") == "true";
configurable string token = isLiveServer ? os:getEnv("SMARTSHEET_TOKEN") : "test_token";
configurable string serviceUrl = isLiveServer ? "https://api.smartsheet.com/2.0" : "http://localhost:9090";

ConnectionConfig config = {auth: {token}};
final Client smartsheetClient = check new Client(config, serviceUrl);

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testDeleteSheet() returns error? {
    SuccessResult response = check smartsheetClient->/sheets/[123456789].delete();
    test:assertTrue(response?.resultCode !is (), "Expected resultCode to be present");
    test:assertTrue(response?.message !is (), "Expected message to be present");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testGetSheet() returns error? {
    anydata response = check smartsheetClient->/sheets/[123456789].get();
    test:assertTrue(response !is (), "Expected sheet data to be present");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testUpdateSheet() returns error? {
    UpdateSheet payload = {
        name: "Updated Test Sheet",
        userSettings: {
            criticalPathEnabled: false,
            displaySummaryTasks: true
        }
    };
    AttachmentListResponse response = check smartsheetClient->/sheets/[123456789].put(payload);
    test:assertTrue(response?.result !is (), "Expected result to be present");
    test:assertTrue(response?.resultCode !is (), "Expected resultCode to be present");
    test:assertTrue(response?.message !is (), "Expected message to be present");
}