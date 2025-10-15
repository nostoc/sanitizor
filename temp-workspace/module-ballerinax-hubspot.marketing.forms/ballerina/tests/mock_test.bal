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

import ballerina/test;

// create mock client
final Client mockClient = check new (
    {
        auth: {
            token: "test-token" // This approach eliminates the need for the client to make additional server requests for token validation, such as a refresh token request in the OAuth2 flow.
        }
    }, "http://localhost:9090/marketing/v3/forms"
);

final string mockFormId = "b6336282-50ec-465e-894e-e368146fa25f";

@test:Config {
    groups: ["mock_service_test"]
}
isolated function mockTestGetForm() returns error? {
    CollectionResponseFormDefinitionBaseForwardPaging response = check mockClient->/.get();
    test:assertTrue(response?.results.length() > 0);
}

@test:Config {
    groups: ["mock_service_test"]
}
isolated function mockTestGetFormById() returns error? {
    FormDefinitionBase response = check mockClient->/[mockFormId].get();
    test:assertEquals(response?.id, mockFormId);
}

