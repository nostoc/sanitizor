
# Ballerina hubspot.marketing.forms connector

[![Build](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/actions/workflows/ci.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/actions/workflows/ci.yml)
[![Trivy](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/actions/workflows/trivy-scan.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/actions/workflows/trivy-scan.yml)
[![GraalVM Check](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/actions/workflows/build-with-bal-test-graalvm.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/actions/workflows/build-with-bal-test-graalvm.yml)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-hubspot.marketing.forms.svg)](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/commits/master)
[![GitHub Issues](https://img.shields.io/github/issues/ballerina-platform/ballerina-library/module/hubspot.marketing.forms.svg?label=Open%20Issues)](https://github.com/ballerina-platform/ballerina-library/labels/module%hubspot.marketing.forms)

## Overview

[HubSpot](https://www.hubspot.com/) is a comprehensive customer relationship management (CRM) platform that provides marketing, sales, and service software to help businesses attract, engage, and delight customers throughout their entire customer journey.

The `ballerinax/hubspot.marketing.forms` package offers APIs to connect and interact with [HubSpot API](https://developers.hubspot.com/docs/api/overview) endpoints, specifically based on [HubSpot Marketing Forms API v3](https://developers.hubspot.com/docs/api/marketing/forms).
## Setup guide

To use the HubSpot Marketing Forms connector, you must have access to the HubSpot API through a [HubSpot developer account](https://developers.hubspot.com/) and obtain an API access token. If you do not have a HubSpot account, you can sign up for one [here](https://www.hubspot.com/products/get-started).

### Step 1: Create a HubSpot Account

1. Navigate to the [HubSpot website](https://www.hubspot.com/) and sign up for an account or log in if you already have one.

2. Note that while HubSpot offers free accounts, certain API features may require a paid subscription plan for full access to advanced functionality.

### Step 2: Generate an API Access Token

1. Log in to your HubSpot account.

2. Click on the settings icon (gear icon) in the top navigation bar to access your account settings.

3. In the left sidebar, navigate to Integrations and select Private Apps.

4. Click Create a private app button.

5. Configure your private app by providing a name and description, then navigate to the Scopes tab.

6. Select the necessary scopes for forms access (typically under "CRM" scopes, select "Forms").

7. Click Create app and then Show token to reveal your access token.

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
        formType: "hubspot",
        name: "Contact Us Form",
        createdAt: "",
        updatedAt: "",
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
        ]
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

1. [Sign-up form](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/tree/main/examples/sign-up-form) - Demonstrates how to create and manage user registration forms using HubSpot Marketing Forms.
2. [Contact us form](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/tree/main/examples/contact-us-form) - Illustrates building contact forms for customer inquiries and lead generation.
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
