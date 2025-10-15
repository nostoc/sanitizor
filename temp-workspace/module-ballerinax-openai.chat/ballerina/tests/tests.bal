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

import ballerina/os;
import ballerina/test;

configurable boolean isLiveServer = os:getEnv("IS_LIVE_SERVER") == "true";
configurable string token = isLiveServer ? os:getEnv("OPENAI_TOKEN") : "test";
final string mockServiceUrl = "http://localhost:9090";
final Client openAIChat = check initClient();

function initClient() returns Client|error {
    if isLiveServer {
        return new ({auth: {token}});
    }
    return new ({auth: {token}}, mockServiceUrl);
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testChatCompletion() returns error? {
    CreateChatCompletionRequest request = {
        model: "gpt-4o-mini",
        messages: [{"role": "user", "content": "This is a test message"}]
    };
    CreateChatCompletionResponse response = check openAIChat->/chat/completions.post(request);
    test:assertTrue(response.choices.length() > 0, msg = "Expected at least one completion choice");
    string? content = response.choices[0].message.content;
    test:assertTrue(content !is (), msg = "Expected content in the completion response");
}
