# Examples

The `hubspot.marketing.events` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.events/tree/main/examples), covering use cases like event participation management and marketing event management.

1. [Event participation management](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.events/tree/main/examples/event_participation_management) - Manage and track participant registrations and attendance for marketing events.

2. [Marketing event management](https://github.com/ballerina-platform/module-ballerinax-hubspot.marketing.events/tree/main/examples/marketing_event_management) - Create, update, and manage marketing events within the HubSpot platform.

## Prerequisites

1. Generate HubSpot credentials to authenticate the connector as described in the [Setup guide](https://central.ballerina.io/ballerinax/hubspot.marketing.events/latest#setup-guide).

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