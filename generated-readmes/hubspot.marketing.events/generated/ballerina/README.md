## Overview

[HubSpot](https://www.hubspot.com/) is a comprehensive customer relationship management (CRM) platform that provides marketing, sales, service, and content management tools to help businesses attract, engage, and delight customers throughout their entire customer journey.

The `ballerinax/hubspot.marketing.events` package offers APIs to connect and interact with [HubSpot API](https://developers.hubspot.com/docs/api/overview) endpoints, specifically based on [HubSpot API v3](https://developers.hubspot.com/docs/api/marketing/events).
## Setup guide

To use the HubSpot Marketing Events connector, you must have access to the HubSpot API through a [HubSpot developer account](https://developers.hubspot.com/) and obtain a private app access token. If you do not have a HubSpot account, you can sign up for one [here](https://www.hubspot.com/products/get-started).

### Step 1: Create a HubSpot Account

1. Navigate to the [HubSpot website](https://www.hubspot.com/) and sign up for an account or log in if you already have one.

2. Ensure you have appropriate permissions to create private apps in your HubSpot account. Super admin permissions are typically required for creating private apps and accessing developer features.

### Step 2: Generate an API Access Token

1. Log in to your HubSpot account.

2. In the main navigation, click the settings icon (gear icon) in the top right corner to access your account settings.

3. In the left sidebar menu, navigate to Integrations > Private Apps.

4. Click Create a private app in the top right corner.

5. On the Basic Info tab, configure your app name and description.

6. Click the Scopes tab and select the required scopes for marketing events, including `marketing-events.read` and `marketing-events.write`.

7. Click Create app in the top right corner, then click Continue creating to confirm.

8. Copy the generated access token from the app details page.

> **Tip:** You must copy and store this key somewhere safe. It won't be visible again in your account settings for security reasons.
## Quickstart

To use the `HubSpot Marketing Events` connector in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

```ballerina
import ballerina/oauth2;
import ballerinax/hubspot.marketing.events as hsme;
```

### Step 2: Instantiate a new connector

1. Create a `Config.toml` file with your credentials:

```toml
clientId = "<Your_Client_Id>"
clientSecret = "<Your_Client_Secret>"
refreshToken = "<Your_Refresh_Token>"
```

2. Create a `hsme:ConnectionConfig` and initialize the client:

```ballerina
configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string refreshToken = ?;

final hsme:Client hubspotMarketingEventsClient = check new({
    auth: {
        clientId,
        clientSecret,
        refreshToken
    }
});
```

### Step 3: Invoke the connector operation

Now, utilize the available connector operations.

#### Create a marketing event

```ballerina
public function main() returns error? {
    hsme:MarketingEventCreateRequestParams newEvent = {
        eventName: "Product Launch Webinar",
        eventOrganizer: "Marketing Team",
        eventType: "WEBINAR",
        externalAccountId: "company-123",
        externalEventId: "webinar-2024-001",
        eventDescription: "Join us for the launch of our latest product features",
        startDateTime: "2024-06-15T10:00:00Z",
        endDateTime: "2024-06-15T11:00:00Z",
        eventUrl: "https://example.com/webinar/product-launch"
    };

    hsme:MarketingEventDefaultResponse response = check hubspotMarketingEventsClient->postEventsCreate(newEvent);
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