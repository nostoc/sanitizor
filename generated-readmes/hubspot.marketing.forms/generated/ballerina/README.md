## Overview

[HubSpot](https://www.hubspot.com/) is a comprehensive customer platform that provides marketing, sales, customer service, and CRM software to help businesses grow and manage customer relationships effectively.

The `ballerinax/hubspot.marketing.forms` package offers APIs to connect and interact with [HubSpot API](https://developers.hubspot.com/docs/api/overview) endpoints, specifically based on [HubSpot Marketing Forms API v3](https://developers.hubspot.com/docs/api/marketing/forms).
## Setup guide

To use the HubSpot Marketing Forms connector, you must have access to the HubSpot API through a [HubSpot developer account](https://developers.hubspot.com/) and obtain an API access token. If you do not have a HubSpot account, you can sign up for one [here](https://www.hubspot.com/products/get-started).

### Step 1: Create a HubSpot Account

1. Navigate to the [HubSpot website](https://www.hubspot.com/) and sign up for an account or log in if you already have one.

2. Note that while HubSpot offers a free tier, certain API functionality may require a paid subscription plan (Starter, Professional, or Enterprise) depending on your usage needs.

### Step 2: Generate an API Access Token

1. Log in to your HubSpot account.

2. In the main navigation, click the settings icon (gear icon) in the top right corner to access your account settings.

3. In the left sidebar menu, navigate to Integrations > Private Apps.

4. Click "Create a private app" button.

5. Fill in the basic information for your app (name, description) in the "Basic Info" tab.

6. Navigate to the "Scopes" tab and select the required scopes for forms access, including `forms` and any other permissions your application needs.

7. Click "Create app" and then "Continue creating" to confirm.

8. Once created, you'll see your access token in the "Auth" tab of your private app.

> **Tip:** You must copy and store this key somewhere safe. It won't be visible again in your account settings for security reasons.
## Quickstart

To use the `HubSpot Marketing Forms` connector in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

Import the `hubspot.marketing.forms` module.

```ballerina
import ballerinax/hubspot.marketing.forms;
```

### Step 2: Instantiate a new connector

1. Create a `Config.toml` file and configure the obtained access token as follows:

```toml
token = "<Your_HubSpot_Marketing_Forms_Access_Token>"
```

2. Create a `hubspot.marketing.forms:ConnectionConfig` with the obtained access token and initialize the connector with it.

```ballerina
configurable string token = ?;

final hubspot.marketing.forms:Client hubspotForms = check new({
    auth: {
        token
    }
});
```

### Step 3: Invoke the connector operation

Now, utilize the available connector operations.

#### Create a new form

```ballerina
public function main() returns error? {
    hubspot.marketing.forms:HubSpotFormDefinitionCreateRequest newForm = {
        formType: "HUBSPOT",
        name: "Contact Us Form",
        createdAt: "2024-01-01T00:00:00.000Z",
        updatedAt: "2024-01-01T00:00:00.000Z",
        archived: false,
        fieldGroups: [
            {
                fields: [
                    {
                        fieldType: "single_line_text",
                        name: "firstname",
                        label: "First Name",
                        required: true
                    },
                    {
                        fieldType: "single_line_text", 
                        name: "lastname",
                        label: "Last Name",
                        required: true
                    },
                    {
                        fieldType: "email",
                        name: "email",
                        label: "Email Address",
                        required: true
                    }
                ]
            }
        ],
        configuration: {
            language: "en"
        },
        displayOptions: {
            renderRawHtml: false,
            theme: "default"
        }
    };

    hubspot.marketing.forms:HubSpotFormDefinition response = check hubspotForms->/marketing/v3/forms.post(newForm);
}
```

### Step 4: Run the Ballerina application

```bash
bal run
```
## Examples

The `hubspot.marketing.forms` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/tree/main/examples), covering the following use cases:

1. [Sign-up form](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/tree/main/examples/sign-up-form) - Demonstrates how to create and manage sign-up forms using the HubSpot Marketing Forms connector.
2. [Contact us form](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/tree/main/examples/contact-us-form) - Illustrates building and handling contact us forms for customer inquiries.