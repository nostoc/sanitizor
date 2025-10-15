## Overview

[HubSpot](https://www.hubspot.com/) is a comprehensive customer relationship management (CRM) platform that provides tools for marketing, sales, customer service, and content management to help businesses attract, engage, and delight customers.

The `ballerinax/hubspot.marketing.forms` package offers APIs to connect and interact with [HubSpot API](https://developers.hubspot.com/docs/api/overview) endpoints, specifically based on [HubSpot Forms API v3](https://developers.hubspot.com/docs/api/marketing/forms).
## Setup guide

To use the HubSpot Marketing Forms connector, you must have access to the HubSpot API through a [HubSpot developer account](https://developers.hubspot.com/) and obtain an API access token. If you do not have a HubSpot account, you can sign up for one [here](https://www.hubspot.com/products/get-started).

### Step 1: Create a HubSpot Account

1. Navigate to the [HubSpot website](https://www.hubspot.com/) and sign up for an account or log in if you already have one.

2. Note that while HubSpot offers free accounts, some API features may require a paid subscription plan (Starter, Professional, or Enterprise) depending on your usage requirements.

### Step 2: Generate an API Access Token

1. Log in to your HubSpot account.

2. In the main navigation, click the settings icon (gear icon) in the top right corner to access your account settings.

3. In the left sidebar menu, navigate to Integrations > Private Apps.

4. Click Create a private app in the top right corner.

5. On the Basic Info tab, give your app a name and description.

6. Click the Scopes tab and select the required scopes for forms access (typically `forms` and any other scopes you need).

7. Click Create app in the top right corner, then review and accept the terms to generate your access token.

> **Tip:** You must copy and store this key somewhere safe. It won't be visible again in your account settings for security reasons.
## Quickstart

To use the `HubSpot Marketing Forms` connector in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

```ballerina
import ballerina/oauth2;
import ballerinax/hubspot.marketing.forms as hsmforms;
```

### Step 2: Instantiate a new connector

1. Create a `Config.toml` file with your credentials:

```toml
clientId = "<Your_Client_Id>"
clientSecret = "<Your_Client_Secret>"
refreshToken = "<Your_Refresh_Token>"
```

2. Create a `hsmforms:ConnectionConfig` and initialize the client:

```ballerina
configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string refreshToken = ?;

final hsmforms:Client hsmformsClient = check new({
    auth: {
        clientId,
        clientSecret,
        refreshToken
    }
});
```

### Step 3: Invoke the connector operation

Now, utilize the available connector operations.

#### Create a new form

```ballerina
public function main() returns error? {
    hsmforms:FormDefinitionCreateRequestBase newForm = {
        formType: "hubspot",
        name: "New Lead Capture Form",
        archived: false,
        fieldGroups: [
            {
                groupType: "default_group",
                richTextType: "text",
                fields: [
                    {
                        objectTypeId: "0-1",
                        name: "email",
                        label: "Email Address",
                        fieldType: "email",
                        required: true,
                        hidden: false,
                        validation: {
                            useDefaultBlockList: true,
                            blockedEmailDomains: []
                        }
                    }
                ]
            }
        ],
        configuration: {
            createNewContactForNewEmail: true,
            editable: true,
            allowLinkToResetKnownValues: false,
            postSubmitAction: {
                'type: "thank_you",
                value: "Thank you for your submission!"
            },
            language: "en",
            prePopulateKnownValues: true,
            cloneable: true,
            notifyContactOwner: false,
            recaptchaEnabled: false,
            archivable: true,
            notifyRecipients: []
        },
        legalConsentOptions: {
            'type: "none"
        },
        displayOptions: {
            renderRawHtml: false,
            theme: "default_style",
            submitButtonText: "Submit",
            style: {
                labelTextSize: "14px",
                legalConsentTextColor: "#000000",
                fontFamily: "Arial",
                legalConsentTextSize: "12px",
                backgroundWidth: "100%",
                helpTextSize: "12px",
                submitFontColor: "#FFFFFF",
                labelTextColor: "#000000",
                submitAlignment: "center",
                submitSize: "medium",
                helpTextColor: "#666666",
                submitColor: "#007ACC"
            }
        },
        createdAt: "",
        updatedAt: ""
    };

    hsmforms:FormDefinitionBase response = check hsmformsClient->/.post(newForm);
}
```

### Step 4: Run the Ballerina application

```bash
bal run
```
## Examples

The `hubspot.marketing.forms` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/tree/main/examples), covering the following use cases:

1. [Sign-up form](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/tree/main/examples/sign-up-form) - Demonstrates how to create and manage sign-up forms using the HubSpot Marketing Forms connector.
2. [Contact us form](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/tree/main/examples/contact-us-form) - Illustrates creating and handling contact us forms for lead generation and customer inquiries.