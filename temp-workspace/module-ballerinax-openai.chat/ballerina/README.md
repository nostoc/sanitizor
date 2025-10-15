## Overview

[OpenAI](https://openai.com/) is an AI research and deployment company that provides powerful artificial intelligence models and APIs, enabling developers to integrate advanced capabilities like natural language processing, code generation, and conversational AI into their applications.

The `ballerinax/openai.chat` package offers APIs to connect and interact with [OpenAI API](https://platform.openai.com/docs/api-reference) endpoints, specifically based on [OpenAI API v1](https://platform.openai.com/docs/api-reference/chat).
## Setup guide

To use the OpenAI Chat connector, you must have access to the OpenAI API through an [OpenAI developer account](https://platform.openai.com/) and obtain an API key. If you do not have an OpenAI account, you can sign up for one [here](https://openai.com/api/).

### Step 1: Create an OpenAI Account

1. Navigate to the [OpenAI website](https://openai.com/api/) and sign up for an account or log in if you already have one.

2. Note that while you can create a free account, API usage requires adding a payment method and purchasing credits, as the free trial credits are limited and may expire.

### Step 2: Generate an API Key

1. Log in to your OpenAI account and navigate to the [OpenAI Platform](https://platform.openai.com/).

2. In the left sidebar, click on "API keys" or navigate directly to the API keys section.

3. Click on "Create new secret key" button.

4. Optionally, provide a name for your API key to help you identify it later.

5. Click "Create secret key" and copy the generated key immediately.

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
token = "<Your_OpenAI_Chat_Access_Token>"
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
        max_tokens: 100,
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
2. [Cli assistant](https://github.com/ballerina-platform/module-ballerinax-openai.chat/tree/main/examples/cli-assistant) - Illustrates building a command-line interface assistant powered by OpenAI chat completions.