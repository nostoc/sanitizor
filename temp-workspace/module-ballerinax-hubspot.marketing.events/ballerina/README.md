## Overview

[HubSpot](https://www.hubspot.com/) is a comprehensive customer relationship management (CRM) platform that provides tools for marketing, sales, customer service, and content management to help businesses attract, engage, and delight customers.

The `ballerinax/hubspot.marketing.events` package offers APIs to connect and interact with [HubSpot API](https://developers.hubspot.com/docs/api/overview) endpoints, specifically based on [HubSpot Marketing Events API v3](https://developers.hubspot.com/docs/api/marketing/marketing-events).
## Setup guide

To use the HubSpot Marketing Events connector, you must have access to the HubSpot API through a [HubSpot developer account](https://developers.hubspot.com/) and obtain an API access token. If you do not have a HubSpot account, you can sign up for one [here](https://www.hubspot.com/products/get-started).

### Step 1: Create a HubSpot Account

1. Navigate to the [HubSpot website](https://www.hubspot.com/) and sign up for an account or log in if you already have one.

2. Ensure you have a Professional or Enterprise plan, as the HubSpot Marketing Events API requires access to HubSpot's premium marketing features which are available on these plans.

### Step 2: Generate an API Access Token

1. Log in to your HubSpot account.

2. Click on the settings icon (gear icon) in the top navigation bar to access your account settings.

3. In the left sidebar, navigate to Integrations and select Private Apps.

4. Click Create a private app and provide a name and description for your app.

5. Navigate to the Scopes tab and select the necessary scopes for marketing events, including `marketing-events.read` and `marketing-events.write`.

6. Click Create app and then Show token to reveal your access token.

> **Tip:** You must copy and store this key somewhere safe. It won't be visible again in your account settings for security reasons.
## Quickstart

To use the `HubSpot Marketing Events` connector in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

```ballerina
import ballerina/oauth2;
import ballerinax/hubspot.marketing.events as hsevents;
```

### Step 2: Instantiate a new connector

1. Create a `Config.toml` file with your credentials:

```toml
clientId = "<Your_Client_Id>"
clientSecret = "<Your_Client_Secret>"
refreshToken = "<Your_Refresh_Token>"
```

2. Create a `hsevents:ConnectionConfig` and initialize the client:

```ballerina
configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string refreshToken = ?;

final hsevents:Client hubspotEventsClient = check new({
    auth: {
        clientId,
        clientSecret,
        refreshToken
    }
});
```

### Step 3: Invoke the connector operation

Now, utilize the available connector operations.

#### Create a new marketing event

```ballerina
public function main() returns error? {
    hsevents:MarketingEventCreateRequestParams newEvent = {
        eventName: "Product Launch Webinar",
        eventOrganizer: "Marketing Team",
        externalEventId: "webinar-2024-001",
        externalAccountId: "marketing-app-123",
        eventDescription: "Join us for an exciting product launch presentation",
        eventType: "WEBINAR",
        startDateTime: "2024-03-15T14:00:00Z",
        endDateTime: "2024-03-15T15:30:00Z",
        eventUrl: "https://example.com/events/webinar-2024-001"
    };

    hsevents:MarketingEventDefaultResponse response = check hubspotEventsClient->postEventsCreate(newEvent);
}
```

### Step 4: Run the Ballerina application

```bash
bal run
```
## Examples

The `hubspot.marketing.events` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.events/tree/main/examples), covering the following use cases:

1. [Event participation management](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.events/tree/main/examples/event_participation_management) - Demonstrates how to manage participant registration and attendance for marketing events.
2. [Marketing event management](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.events/tree/main/examples/marketing_event_management) - Illustrates creating, updating, and managing marketing events in HubSpot.