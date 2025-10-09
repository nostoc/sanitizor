# Examples

The `ballerinax/smartsheet` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-smartsheet/tree/main/examples), covering use cases like project task management integration.

1. [Project task management integration](https://github.com/ballerina-platform/module-ballerinax-smartsheet/tree/main/examples/project_task_management) - Automate project task creation using Ballerina connector for Smartsheet. When a new project is created, the system automatically creates initial tasks in Smartsheet and sends a summary notification message to Slack.

## Prerequisites

1. Generate Smartsheet credentials to authenticate the connector as described in the [Setup guide](https://central.ballerina.io/ballerinax/smartsheet/latest#setup-guide).

2. For each example, create a `Config.toml` file the related configuration. Here's an example of how your `Config.toml` file should look:

    ```toml
    smartsheetToken = "SMARTSHEET_ACCESS_TOKEN"
    ```
## Running an example

Execute the following commands to build an example from the source:

* To build an example:

    ```bash
    bal build
    ```

* To run an example:

    ```bash
    bal run
    ```

## Building the examples with the local module

**Warning**: Due to the absence of support for reading local repositories for single Ballerina files, the Bala of the module is manually written to the central repository as a workaround. Consequently, the bash script may modify your local Ballerina repositories.

Execute the following commands to build all the examples against the changes you have made to the module locally:

* To build all the examples:

    ```bash
    ./build.sh build
    ```

* To run all the examples:

    ```bash
    ./build.sh run
    ```
