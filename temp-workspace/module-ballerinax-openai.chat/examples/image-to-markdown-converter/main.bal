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

import ballerina/file;
import ballerina/io;
import ballerinax/openai.chat;

configurable string token = ?;

public function main() returns error? {
    final chat:Client openAIChat = check new ({auth: {token}});
    string imagePath = getImageFilePath();
    string|error base64Image = encodeImageToBase64(imagePath);

    if base64Image is error {
        io:println(base64Image);
        return;
    }
    string|error markdownDoc = generateDocumentation(base64Image, openAIChat);

    if markdownDoc is error {
        io:println(markdownDoc);
        return;
    }
    check saveMarkdownToFile(markdownDoc, imagePath);
    io:println("Markdown documentation generated and saved successfully.");
}

function getImageFilePath() returns string {
    io:println("Enter the path to the image file:");
    return io:readln().trim();
}

function encodeImageToBase64(string imagePath) returns string|error {
    byte[] imageBytes = check io:fileReadBytes(imagePath);
    return imageBytes.toBase64();
}

function generateDocumentation(string base64Image, chat:Client openAIChat) returns string|error {
    string prompt = "Generate markdown documentation based on the content of the following image. Include detailed descriptions of any diagrams, notes, or code snippets present. Structure the documentation with appropriate headings, and provide a summary of the key concepts discussed. Additionally, include any relevant annotations or comments that might aid in understanding the content";

    chat:CreateChatCompletionRequest request = {
        model: "gpt-4o-mini",
        messages: [
            {
                role: "user",
                content: [
                    {
                        "type": "text",
                        "text": prompt
                    },
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": string `data:image/jpeg;base64,${base64Image}`
                        }
                    }
                ]
            }
        ],
        max_tokens: 300
    };
    chat:CreateChatCompletionResponse response = check openAIChat->/chat/completions.post(request);
    string? markdownDoc = response.choices[0].message.content;

    if markdownDoc is () {
        return error("Failed to generate markdown documentation.");
    }
    return markdownDoc;
}

function saveMarkdownToFile(string markdownDoc, string imagePath) returns error? {
    string imageName = check file:basename(imagePath);
    string parentPath = check file:parentPath(imagePath);
    string docName = string `${re `\.`.split(imageName)[0]}_documentation.md`;
    check io:fileWriteBytes(parentPath + "/" + docName, markdownDoc.toBytes());
}
