
# Ballerina hubspot.marketing.forms connector

[![Build](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/actions/workflows/ci.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/actions/workflows/ci.yml)
[![Trivy](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/actions/workflows/trivy-scan.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/actions/workflows/trivy-scan.yml)
[![GraalVM Check](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/actions/workflows/build-with-bal-test-graalvm.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/actions/workflows/build-with-bal-test-graalvm.yml)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-hubspot.marketing.forms.svg)](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/commits/master)
[![GitHub Issues](https://img.shields.io/github/issues/ballerina-platform/ballerina-library/module/hubspot.marketing.forms.svg?label=Open%20Issues)](https://github.com/ballerina-platform/ballerina-library/labels/module%hubspot.marketing.forms)

## Overview

[HubSpot](https://www.hubspot.com/) is a comprehensive customer relationship management (CRM) platform that provides marketing, sales, customer service, and content management tools to help businesses attract, engage, and delight customers throughout their entire lifecycle.

The `ballerinax/hubspot.marketing.forms` package offers APIs to connect and interact with [HubSpot API](https://developers.hubspot.com/docs/api/overview) endpoints, specifically based on [HubSpot Forms API v3](https://developers.hubspot.com/docs/api/marketing/forms).
## Setup guide

To use the HubSpot Marketing Forms connector, you must have access to the HubSpot API through a [HubSpot developer account](https://developers.hubspot.com/) and obtain an API access token. If you do not have a HubSpot account, you can sign up for one [here](https://www.hubspot.com/products/get-started).

### Step 1: Create a HubSpot Account

1. Navigate to the [HubSpot website](https://www.hubspot.com/) and sign up for an account or log in if you already have one.

2. Ensure you have access to HubSpot's API features. Private app access tokens are available on all HubSpot subscription tiers, including the free tier.

### Step 2: Generate an API Access Token

1. Log in to your HubSpot account.

2. In your HubSpot account, navigate to Settings by clicking the settings icon in the main navigation bar.

3. In the left sidebar menu, navigate to Integrations > Private Apps.

4. Click Create a private app in the upper right.

5. On the Basic Info tab, configure the details of your app including the name and description.

6. Click the Scopes tab and select the required scopes for your integration, including forms permissions.

7. Click Create app in the upper right to create your private app and generate the access token.

> **Tip:** You must copy and store this key somewhere safe. It won't be visible again in your account settings for security reasons.
## Quickstart

To use the `hubspot.marketing.forms` connector in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module
```ballerina
import ballerinax/hubspot.marketing.forms;
```

### Step 2: Instantiate a new connector
1. Create a `Config.toml` file and configure the obtained credentials:
```toml
[hubspot.marketing.forms]
privateAppLegacy = "<Private App Token>"
```

2. Create a `forms:ConnectionConfig` with the above credentials and initialize the connector:
```ballerina
configurable string privateAppLegacy = ?;

forms:ApiKeysConfig auth = {
    privateAppLegacy: privateAppLegacy
};

forms:ConnectionConfig config = {
    auth: auth
};

forms:Client hubspotForms = check new forms:Client(config);
```

### Step 3: Invoke the connector operation
```ballerina
public function main() returns error? {
    // Create a new form definition
    forms:FormDefinitionCreateRequestBase formRequest = {
        name: "Contact Us Form",
        formType: "hubspot",
        archived: false,
        createdAt: "2024-01-01T00:00:00Z",
        updatedAt: "2024-01-01T00:00:00Z",
        fieldGroups: [
            {
                groupType: "default_group",
                richTextType: "text",
                fields: [
                    {
                        fieldType: "single_line_text",
                        name: "firstname",
                        label: "First Name",
                        objectTypeId: "0-1",
                        required: true,
                        hidden: false
                    },
                    {
                        fieldType: "email",
                        name: "email",
                        label: "Email Address",
                        objectTypeId: "0-1",
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
                submitFontColor: "#ffffff",
                labelTextColor: "#000000",
                submitAlignment: "left",
                submitSize: "medium",
                helpTextColor: "#666666",
                submitColor: "#007cba"
            }
        }
    };

    forms:FormDefinitionBase createdForm = check hubspotForms->post(formRequest);
    
    // Get the created form
    forms:FormDefinitionBase retrievedForm = check hubspotForms->get(createdForm.id);
    
    // List all forms
    forms:CollectionResponseFormDefinitionBaseForwardPaging forms = check hubspotForms->get();
    
    io:println("Created form: ", createdForm.name);
    io:println("Total forms: ", forms.results.length());
}
```

### Step 4: Run the Ballerina application
```bash
bal run
```
## Examples

The `hubspot.marketing.forms` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/tree/main/examples), covering the following use cases:

1. [Ign-up form](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/tree/main/examples/ign-up-form) - Demonstrates how to create and manage sign-up forms using the HubSpot Marketing Forms connector.
2. [Ontact us form](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/tree/main/examples/ontact-us-form) - Illustrates creating and handling contact us forms for lead generation.
## Build from the source

### Setting up the prerequisites

1. Download and install Java SE Development Kit (JDK) version 17. You can download it from either of the following sources:

    * [Oracle JDK](https://www.oracle.com/java/technologies/downloads/)
    * [OpenJDK](https://adoptium.net/)

    > **Note:** After installation, remember to set the `JAVA_HOME` environment variable to the directory where JDK was installed.

2. Download and install [Ballerina Swan Lake](https://ballerina.io/).

3. Download and install [Docker](https://www.docker.com/get-started).

    > **Note**: Ensure that the Docker daemon is running before executing any tests.

4. Export Github Personal access token with read package permissions as follows,

    ```bash
    export packageUser=<Username>
    export packagePAT=<Personal access token>
    ```

### Build options

Execute the commands below to build from the source.

1. To build the package:

    ```bash
    ./gradlew clean build
    ```

2. To run the tests:

    ```bash
    ./gradlew clean test
    ```

3. To build the without the tests:

    ```bash
    ./gradlew clean build -x test
    ```

4. To run tests against different environments:

    ```bash
    ./gradlew clean test -Pgroups=<Comma separated groups/test cases>
    ```

5. To debug the package with a remote debugger:

    ```bash
    ./gradlew clean build -Pdebug=<port>
    ```

6. To debug with the Ballerina language:

    ```bash
    ./gradlew clean build -PbalJavaDebug=<port>
    ```

7. Publish the generated artifacts to the local Ballerina Central repository:

    ```bash
    ./gradlew clean build -PpublishToLocalCentral=true
    ```

8. Publish the generated artifacts to the Ballerina Central repository:

    ```bash
    ./gradlew clean build -PpublishToCentral=true
    ```

## Contribute to Ballerina

As an open-source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All the contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).


## Useful links

* For more information go to the [`hubspot.marketing.forms` package](https://central.ballerina.io/ballerinax/hubspot.marketing.forms/latest).
* For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/learn/by-example/).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
