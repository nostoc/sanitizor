# Survey Feedback Analysis

This example demonstrates how to automate survey feedback collection and analysis using Ballerina connector for Slack. The system creates a dedicated survey channel, posts a survey request message, and then retrieves and displays all replies for analysis.

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

2. The application will:
   - Create a new Slack channel named "survey-coordination"
   - Post a survey request message asking for company feedback
   - Retrieve and display all replies to the survey message
   - Print the collected feedback responses to the console