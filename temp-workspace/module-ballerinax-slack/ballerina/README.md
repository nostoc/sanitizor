## Overview

[Slack](https://slack.com/) is a cloud-based collaboration platform that brings teams together through organized conversations in channels, direct messaging, file sharing, and integrated workflows to enhance workplace productivity and communication.

The `ballerinax/slack` package offers APIs to connect and interact with [Slack API](https://api.slack.com/) endpoints, specifically based on [Slack Web API](https://api.slack.com/web).
## Setup guide

To use the Slack connector, you must have access to the Slack API through a [Slack developer account](https://api.slack.com/) and obtain an API access token. If you do not have a Slack account, you can sign up for one [here](https://slack.com/get-started).

### Step 1: Create a Slack Account

1. Navigate to the [Slack website](https://slack.com/) and sign up for an account or log in if you already have one.

2. Create or have access to a Slack workspace where you have administrative privileges to install apps and generate API tokens.

### Step 2: Generate an API Access Token

1. Log in to your Slack account and navigate to the [Slack API website](https://api.slack.com/).

2. Click on "Your Apps" in the top right corner, then select "Create New App".

3. Choose "From scratch", provide an app name, and select the workspace where you want to install the app.

4. In the app settings, navigate to "OAuth & Permissions" from the left sidebar.

5. Scroll down to the "Scopes" section and add the necessary OAuth scopes for your application requirements.

6. Scroll back up and click "Install to Workspace" to generate the access tokens.

7. Copy the "Bot User OAuth Token" (starts with `xoxb-`) or "User OAuth Token" (starts with `xoxp-`) depending on your needs.

> **Tip:** You must copy and store this key somewhere safe. It won't be visible again in your account settings for security reasons.
## Quickstart

To use the `slack` connector in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

```ballerina
import ballerinax/slack;
```

### Step 2: Instantiate a new connector

1. Create a `Config.toml` file and configure the obtained access token:

```toml
token = "<Your_Slack_Access_Token>"
```

2. Create a `slack:ConnectionConfig` and initialize the client:

```ballerina
configurable string token = ?;

final slack:Client slackClient = check new({
    auth: {
        token
    }
});
```

### Step 3: Invoke the connector operation

Now, utilize the available connector operations.

#### Post a message

```ballerina
public function main() returns error? {
    slack:ChatPostMessageResponse response = check slackClient->/chat\.postMessage.post({
        channel: "general", 
        text: "Hello from Ballerina!"
    });
}
```

### Step 4: Run the Ballerina application

```bash
bal run
```
## Examples

The `Slack` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-slack/tree/main/examples), covering the following use cases:

1. [Automated summary report](https://github.com/ballerina-platform/module-ballerinax-slack/tree/main/examples/automated-summary-report) - Demonstrates how to generate and send automated summary reports using Ballerina connector for Slack.
2. [Survey feedback analysis](https://github.com/ballerina-platform/module-ballerinax-slack/tree/main/examples/survey-feedback-analysis) - Illustrates analyzing and processing survey feedback data through Slack integration.