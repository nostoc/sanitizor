# Examples

The `openai.chat` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-openai.chat/tree/main/examples), covering use cases like image analysis and conversational AI applications.

1. [Image to markdown converter](https://github.com/ballerina-platform/module-ballerinax-openai.chat/tree/main/examples/image-to-markdown-converter) - Convert images into structured markdown format using OpenAI's vision capabilities.

2. [CLI assistant](https://github.com/ballerina-platform/module-ballerinax-openai.chat/tree/main/examples/cli-assistant) - Build a command-line interface assistant powered by OpenAI's chat completion API.

## Prerequisites

1. Generate OpenAI credentials to authenticate the connector as described in the [Setup guide](https://central.ballerina.io/ballerinax/openai.chat/latest#setup-guide).

2. For each example, create a `Config.toml` file the related configuration. Here's an example of how your `Config.toml` file should look:

    ```toml
    token = "<Access Token>"
    ```

## Running an Example

Execute the following commands to build an example from the source:

* To build an example:

    ```bash
    bal build
    ```

* To run an example:

    ```bash
    bal run
    ```