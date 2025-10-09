# Project Task Management Integration

This example demonstrates how to automate project task creation using Ballerina connector for Smartsheet. When a new project is created, the system automatically creates initial tasks in Smartsheet and sends a summary notification message to Slack.

## Prerequisites

1. **Smartsheet Setup**
   - Create a Smartsheet account (Business/Enterprise plan required)
   - Generate an API access token
   - Create two sheets:
     - "Projects" sheet with columns: Project Name, Start Date, Status
     - "Tasks" sheet with columns: Task Name, Assigned To, Due Date, Project Name

   > Refer the [Smartsheet setup guide](https://github.com/ballerina-platform/module-ballerinax-smartsheet/blob/main/ballerina/README.md) here.

2. **Slack Setup**
   - Refer the [Slack setup guide](https://github.com/ballerina-platform/module-ballerinax-slack/blob/master/ballerina/README.md) here.

3. For this example, create a `Config.toml` file with your credentials. Here's an example of how your `Config.toml` file should look:

```toml
smartsheetToken = "SMARTSHEET_ACCESS_TOKEN"
projectsSheetName = "PROJECT_SHEET_NAME"
tasksSheetName = "TASK_SHEET_NAME"
slackToken = "SLACK_TOKEN"
slackChannel = "SLACK_CHANNEL"
```

## Run the Example

1. Execute the following command to run the example:

```bash
bal run
```

2. The service will start on port 8080. You can test the integration by sending a POST request to create a new project:

```bash
curl -X POST http://localhost:8080/projects \
  -H "Content-Type: application/json" \
  -d '{
    "projectName": "Website Redesign",
    "startDate": "2025-08-25",
    "status" : "ACTIVE",
    "assignedTo": "developer@example.com"
  }'
```

