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

import ballerina/io;
import ballerina/os;
import ballerinax/openai.chat;

configurable string token = ?;

public function main() returns error? {
    final chat:Client openAIChat = check new ({auth: {token}});
    string osType = getOSType();
    string taskDescription = getTaskDescription();
    string|error command = generateCLICommand(osType, taskDescription, openAIChat);

    // if the command generation was unsuccessful, terminate the program
    if command is error {
        io:println(command);
        return;
    }
    boolean shouldExecute = confirmExecution(command);

    if shouldExecute {
        io:println("Generated command: " + command);
        check executeCommand(command, osType);
        return;
    }
    io:println("Command execution aborted.");
}

function getOSType() returns string {
    io:println("Select your operating system by pressing the corresponding number:\n1. Windows\n2. Linux\n3. macOS");
    string osType;
    string userInput = io:readln().trim();

    match userInput {
        "1" => {
            osType = "windows";
        }
        "2" => {
            osType = "linux";
        }
        "3" => {
            osType = "mac";
        }
        _ => {
            io:println("Invalid selection. Defaulting to 'linux'.");
            osType = "linux";
        }
    }
    return osType;
}

function getTaskDescription() returns string {
    io:println("Please describe the task you want to perform:");
    string taskDescription = io:readln().trim();
    return taskDescription;
}

function generateCLICommand(string osType, string taskDescription, chat:Client openAIChat) returns string|error {
    chat:CreateChatCompletionRequest request = {
        model: "gpt-4o-mini",
        messages: [
            {role: "system", content: string `Generate a terminal command for ${osType} to perform the following task.The response should be a direct command that can be run in the terminal without markdown.`},
            {role: "user", content: taskDescription}
        ]
    };

    chat:CreateChatCompletionResponse response = check openAIChat->/chat/completions.post(request);

    string? command = response.choices[0].message.content;
    if command is () {
        return error("Failed to generate a valid command.");
    }
    return command;
}

function confirmExecution(string command) returns boolean {
    io:println("Generated command: " + command);
    io:println("Do you want to execute this command? (y/n)");
    string? userInput = io:readln().trim().toLowerAscii();
    if userInput == "y" {
        return true;
    }
    return false;
}

function executeCommand(string command, string osType) returns error? {
    io:println("Executing command...");

    string[] cmdArray;
    if osType == "windows" {
        // Use PowerShell to execute the command on Windows
        cmdArray = ["powershell", "-Command", command];
    } else {
        // For Linux/macOS, use /bin/sh to execute the command
        cmdArray = ["/bin/sh", "-c", command];
    }

    os:Process exec = check os:exec({value: cmdArray[0], arguments: cmdArray.slice(1)});

    int status = check exec.waitForExit();
    if status != 0 {
        io:println(string `Process exited with status: ${status}. The command may have failed.`);
    } else {
        io:println("Process executed successfully.");
    }

    byte[] output = check exec.output(io:stdout);
    if output.length() > 0 {
        io:println("Output:");
        io:print(check string:fromBytes(output));
    }
}
