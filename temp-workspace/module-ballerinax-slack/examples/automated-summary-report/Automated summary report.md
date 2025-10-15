# Automated Summary Report

This example demonstrates how to automate the generation and distribution of summary reports using Ballerina connector for Slack. The system creates formatted summary reports and sends them as messages to designated Slack channels for team communication and reporting purposes.

## Prerequisites

1. **Slack Setup**
   - Refer the [Slack setup guide](`https://github.com/ballerina-platform/module-ballerinax-slack/blob/main/ballerina/README.md`) here.

2. For this example, create a `Config.toml` file with your credentials. Here's an example of how your `Config.toml` file should look:

```toml
slackToken = "YOUR_SLACK_BOT_TOKEN"
slackChannel = "YOUR_SLACK_CHANNEL_ID"
```

## Run the Example

1. Execute the following command to run the example:

```bash
bal run
```

2. The service will start on port 8080. You can test the integration by sending a POST request to generate and send a summary report:

```bash
curl -X POST http://localhost:8080/report \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Weekly Performance Summary",
    "period": "Week 34, 2024",
    "metrics": {
      "totalTasks": 45,
      "completedTasks": 38,
      "pendingTasks": 7
    },
    "summary": "Great progress this week with 84% task completion rate."
  }'
```