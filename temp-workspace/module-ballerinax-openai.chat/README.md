
# Ballerina openai.chat connector

[![Build](https://github.com/ballerina-platform/module-ballerinax-openai.chat/actions/workflows/ci.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-openai.chat/actions/workflows/ci.yml)
[![Trivy](https://github.com/ballerina-platform/module-ballerinax-openai.chat/actions/workflows/trivy-scan.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-openai.chat/actions/workflows/trivy-scan.yml)
[![GraalVM Check](https://github.com/ballerina-platform/module-ballerinax-openai.chat/actions/workflows/build-with-bal-test-graalvm.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-openai.chat/actions/workflows/build-with-bal-test-graalvm.yml)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-openai.chat.svg)](https://github.com/ballerina-platform/module-ballerinax-openai.chat/commits/master)
[![GitHub Issues](https://img.shields.io/github/issues/ballerina-platform/ballerina-library/module/openai.chat.svg?label=Open%20Issues)](https://github.com/ballerina-platform/ballerina-library/labels/module%openai.chat)

## Overview

[OpenAI](https://openai.com/) is an AI research and deployment company that develops cutting-edge artificial intelligence models and provides APIs for developers to integrate advanced AI capabilities like natural language processing, code generation, and multimodal AI into their applications.

The `ballerinax/openai.chat` package offers APIs to connect and interact with [OpenAI API](https://platform.openai.com/docs/api-reference) endpoints, specifically based on [OpenAI API v1](https://platform.openai.com/docs/api-reference/introduction).
## Setup guide

To use the OpenAI Chat connector, you must have access to the OpenAI API through an [OpenAI developer account](`https://platform.openai.com/`) and obtain an API key. If you do not have an OpenAI account, you can sign up for one [here](`https://platform.openai.com/signup`).

### Step 1: Create an OpenAI Account

1. Navigate to the [OpenAI Platform website](`https://platform.openai.com/signup`) and sign up for an account or log in if you already have one.

2. Note that while account creation is free, API usage requires credits. You'll need to add a payment method and purchase credits to make API calls.

### Step 2: Generate an API Key

1. Log in to your OpenAI Platform account.

2. Navigate to the API keys section by clicking on your profile in the top-right corner, then select "View API keys" or go directly to the [API keys page](`https://platform.openai.com/api-keys`).

3. Click on "Create new secret key", provide a name for your key, and click "Create secret key".

> **Tip:** You must copy and store this key somewhere safe. It won't be visible again in your account settings for security reasons.
## Quickstart

To use the `OpenAI Chat` connector in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

Import the `openai.chat` module.

```ballerina
import ballerinax/openai.chat;
```

### Step 2: Instantiate a new connector

1. Create a `Config.toml` file and configure the obtained access token as follows:

```toml
token = "<Your_OpenAI_Access_Token>"
```

2. Create a `openai.chat:ConnectionConfig` with the obtained access token and initialize the connector with it.

```ballerina
configurable string token = ?;

final openai.chat:Client openaiChat = check new({
    auth: {
        token
    }
});
```

### Step 3: Invoke the connector operation

Now, utilize the available connector operations.

#### Create a chat completion

```ballerina
public function main() returns error? {
    openai.chat:CreateChatCompletionRequest chatRequest = {
        model: "gpt-3.5-turbo",
        messages: [
            {
                role: "system",
                content: "You are a helpful assistant."
            },
            {
                role: "user",
                content: "What is the capital of France?"
            }
        ],
        max_tokens: 150,
        temperature: 0.7
    };

    openai.chat:CreateChatCompletionResponse response = check openaiChat->/chat/completions.post(chatRequest);
}
```

### Step 4: Run the Ballerina application

```bash
bal run
```
## Examples

The `openai.chat` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-openai.chat/tree/main/examples), covering the following use cases:

1. [Image to markdown converter](https://github.com/ballerina-platform/module-ballerinax-openai.chat/tree/main/examples/image-to-markdown-converter) - Demonstrates how to convert images to markdown format using OpenAI's chat capabilities.
2. [Cli assistant](https://github.com/ballerina-platform/module-ballerinax-openai.chat/tree/main/examples/cli-assistant) - Illustrates building a command-line interface assistant powered by OpenAI's chat API.
## Build from the source

### Setting up the prerequisites

1. Download and install Java SE Development Kit (JDK) version 17. You can download it from either of the following sources:

    * [Oracle JDK](https://www.oracle.com/java/technologies/downloads/)
    * [OpenJDK](https://adoptium.net/)

    > **Note:** After installation, remember to set the `JAVA_HOME` environment variable to the directory where JDK was installed.

2. Download and install [Ballerina Swan Lake](https://ballerina.io/).

3. Download and install [Docker](https://www.docker.com/get-started).

    > **Note**: Ensure that the Docker daemon is running before executing any tests.

4. Export Github Personal access token with read package permissions as follows,

    ```bash
    export packageUser=<Username>
    export packagePAT=<Personal access token>
    ```

### Build options

Execute the commands below to build from the source.

1. To build the package:

    ```bash
    ./gradlew clean build
    ```

2. To run the tests:

    ```bash
    ./gradlew clean test
    ```

3. To build the without the tests:

    ```bash
    ./gradlew clean build -x test
    ```

4. To run tests against different environments:

    ```bash
    ./gradlew clean test -Pgroups=<Comma separated groups/test cases>
    ```

5. To debug the package with a remote debugger:

    ```bash
    ./gradlew clean build -Pdebug=<port>
    ```

6. To debug with the Ballerina language:

    ```bash
    ./gradlew clean build -PbalJavaDebug=<port>
    ```

7. Publish the generated artifacts to the local Ballerina Central repository:

    ```bash
    ./gradlew clean build -PpublishToLocalCentral=true
    ```

8. Publish the generated artifacts to the Ballerina Central repository:

    ```bash
    ./gradlew clean build -PpublishToCentral=true
    ```

## Contribute to Ballerina

As an open-source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All the contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).


## Useful links

* For more information go to the [`openai.chat` package](https://central.ballerina.io/ballerinax/openai.chat/latest).
* For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/learn/by-example/).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
