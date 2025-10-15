## Overview

[Slack](https://slack.com/) is a cloud-based collaboration platform that brings teams together through organized conversations in channels, direct messages, and integrated workflows to enhance productivity and communication.

The `ballerinax/slack` package offers APIs to connect and interact with [Slack API](https://api.slack.com/) endpoints, specifically based on [Slack Web API](https://api.slack.com/web).
## Setup guide

To use the Slack connector, you must have access to the Slack API through a [Slack developer account](https://api.slack.com/) and obtain an API access token. If you do not have a Slack account, you can sign up for one [here](https://slack.com/get-started).

### Step 1: Create a Slack Account

1. Navigate to the [Slack website](https://slack.com/) and sign up for an account or log in if you already have one.

2. Ensure you have the necessary permissions to create apps in your workspace, as workspace owners and admins can restrict app creation and installation.

### Step 2: Generate an API Access Token

1. Log in to your Slack account and navigate to the [Slack API website](https://api.slack.com/).

2. Click on "Your Apps" in the top right corner, then select "Create New App".

3. Choose "From scratch" and provide an app name and select the workspace where you want to develop the app.

4. In your app's settings, navigate to "OAuth & Permissions" from the left sidebar.

5. Scroll down to the "Scopes" section and add the required OAuth scopes for your application.

6. At the top of the "OAuth & Permissions" page, click "Install to Workspace" and authorize the app.

7. Once installed, copy the "Bot User OAuth Token" that starts with `xoxb-`.

> **Tip:** You must copy and store this key somewhere safe. It won't be visible again in your account settings for security reasons.
## Quickstart

To use the `Slack` connector in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

Import the `slack` module.

```ballerina
import ballerinax/slack;
```

### Step 2: Instantiate a new connector

1. Create a `Config.toml` file and configure the obtained access token as follows:

```toml
token = "<Your_Slack_Access_Token>"
```

2. Create a `slack:ConnectionConfig` with the obtained access token and initialize the connector with it.

```ballerina
configurable string token = ?;

final slack:Client slack = check new({
    auth: {
        token
    }
});
```

### Step 3: Invoke the connector operation

Now, utilize the available connector operations.

#### Create a new channel

```ballerina
public function main() returns error? {
    slack:ConversationsCreateBody newChannel = {
        name: "project-discussions",
        is_private: false
    };

    slack:ConversationsCreateResponse response = check slack->/conversations.create.post(newChannel);
}
```

### Step 4: Run the Ballerina application

```bash
bal run
```
## Examples

The `Slack` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-slack/tree/main/examples), covering the following use cases:

1. [Automated summary report](https://github.com/ballerina-platform/module-ballerinax-slack/tree/main/examples/automated-summary-report) - Demonstrates how to generate and send automated summary reports using Ballerina connector for Slack.
2. [Survey feedback analysis](https://github.com/ballerina-platform/module-ballerinax-slack/tree/main/examples/survey-feedback-analysis) - Illustrates collecting and analyzing survey feedback through Slack channels.