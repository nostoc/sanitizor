# Examples

The `hubspot.marketing.forms` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/tree/main/examples), covering use cases like sign-up form management and contact us form handling.

1. [Sign-up form](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/tree/main/examples/ign-up-form) - Integrate HubSpot to manage and process sign-up form submissions.

2. [Contact us form](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.forms/tree/main/examples/ontact-us-form) - Handle contact us form submissions through HubSpot marketing forms.

## Prerequisites

1. Generate HubSpot credentials to authenticate the connector as described in the [Setup guide](https://central.ballerina.io/ballerinax/hubspot.marketing.forms/latest#setup-guide).

2. For each example, create a `Config.toml` file the related configuration. Here's an example of how your `Config.toml` file should look:

    ```toml
    token = "<Access Token>"
    ```

## Running an Example

Execute the following commands to build an example from the source:

* To build an example:

    ```bash
    bal build
    ```

* To run an example:

    ```bash
    bal run
    ```