# Survey Feedback Analysis

This example demonstrates how to analyze survey feedback using Ballerina connector for Slack. The system processes survey responses, performs sentiment analysis, and sends detailed feedback summaries and insights to designated Slack channels for team review and action.

## Prerequisites

1. **Slack Setup**
   - Refer the [Slack setup guide](`https://github.com/ballerina-platform/module-ballerinax-slack/blob/main/ballerina/README.md`) here.

2. For this example, create a `Config.toml` file with your credentials. Here's an example of how your `Config.toml` file should look:

```toml
slackToken = "YOUR_SLACK_BOT_TOKEN"
slackChannel = "YOUR_FEEDBACK_CHANNEL"
```

## Run the Example

1. Execute the following command to run the example:

```bash
bal run
```

2. The service will start on port 8080. You can test the survey feedback analysis by sending a POST request with survey data:

```bash
curl -X POST http://localhost:8080/survey/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "surveyId": "SURVEY_2025_Q1",
    "responses": [
      {
        "question": "How satisfied are you with our service?",
        "answer": "Very satisfied, excellent support team!",
        "rating": 5
      },
      {
        "question": "What can we improve?",
        "answer": "The response time could be faster",
        "rating": 3
      }
    ],
    "respondentEmail": "customer@example.com"
  }'
```