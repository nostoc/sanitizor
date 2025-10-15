# Automated Summary Report

This example demonstrates how to create an automated stand-up report using Ballerina connector for Slack. The system fetches the latest message from each Slack channel and compiles them into a comprehensive summary report that is automatically posted to the "general" channel.

## Prerequisites

1. **Slack Setup**
   - Refer the [Slack setup guide](`https://github.com/ballerina-platform/module-ballerinax-slack/blob/main/ballerina/README.md`) here.

2. For this example, create a `Config.toml` file with your credentials. Here's an example of how your `Config.toml` file should look:

```toml
token = "YOUR_SLACK_BOT_TOKEN"
```

## Run the Example

1. Execute the following command to run the example:

```bash
bal run
```

2. The application will automatically:
   - Fetch all channels in your Slack workspace
   - Retrieve the latest message from each channel
   - Compile these messages into a numbered summary report
   - Post the automated stand-up report to the "general" channel