# CLI Assistant

This example demonstrates how to create an intelligent command-line assistant using Ballerina and OpenAI's GPT model. The application prompts users to describe a task, generates appropriate terminal commands for their operating system, and optionally executes the commands with user confirmation.

## Prerequisites

1. **OpenAI Setup**
   - Create an OpenAI account and obtain an API key
   - Ensure you have access to the GPT models (gpt-4o-mini is used in this example)

   > Refer the [OpenAI setup guide](https://github.com/ballerina-platform/module-ballerinax-openai.chat/blob/main/ballerina/README.md) here.

2. For this example, create a `Config.toml` file with your credentials. Here's an example of how your `Config.toml` file should look:

```toml
token = "YOUR_OPENAI_API_KEY"
```

## Run the Example

1. Execute the following command to run the example:

```bash
bal run
```

2. The application will start and prompt you to:
   - Select your operating system (Windows, Linux, or macOS)
   - Describe the task you want to perform
   - Confirm whether to execute the generated command

   Example interaction:
   ```
   Select your operating system by pressing the corresponding number:
   1. Windows
   2. Linux  
   3. macOS
   > 2

   Please describe the task you want to perform:
   > list all files in the current directory

   Generated command: ls -la
   Do you want to execute this command? (y/n)
   > y
   ```