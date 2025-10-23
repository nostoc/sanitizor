# Examples

The `smartsheet` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-smartsheet/tree/main/examples), covering use cases like project audit setup, sheet collaboration audit, and compliance audit trail.

1. [Project audit setup](https://github.com/ballerina-platform/module-ballerinax-smartsheet/tree/main/examples/project-audit-setup) - Set up automated project auditing workflows to track project progress and milestones.

2. [Sheet collaboration audit](https://github.com/ballerina-platform/module-ballerinax-smartsheet/tree/main/examples/sheet-collaboration-audit) - Monitor and audit collaboration activities across shared Smartsheet workspaces.

3. [Compliance audit trail](https://github.com/ballerina-platform/module-ballerinax-smartsheet/tree/main/examples/compliance-audit-trail) - Create comprehensive audit trails for compliance tracking and regulatory reporting.

4. [Project dashboard setup](https://github.com/ballerina-platform/module-ballerinax-smartsheet/tree/main/examples/project-dashboard-setup) - Build interactive project dashboards to visualize key metrics and performance indicators.

## Prerequisites

1. Generate Smartsheet credentials to authenticate the connector as described in the [Setup guide](https://central.ballerina.io/ballerinax/smartsheet/latest#setup-guide).

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