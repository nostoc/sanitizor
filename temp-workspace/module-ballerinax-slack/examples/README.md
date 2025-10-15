# Examples

The `slack` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-slack/tree/main/examples), covering use cases like automated summary report generation and survey feedback analysis.

1. [Automated summary report](https://github.com/ballerina-platform/module-ballerinax-slack/tree/main/examples/automated-summary-report) - Generate and send automated summary reports to Slack channels.

2. [Survey feedback analysis](https://github.com/ballerina-platform/module-ballerinax-slack/tree/main/examples/survey-feedback-analysis) - Analyze survey feedback data and share insights through Slack messages.

## Prerequisites

1. Generate Slack credentials to authenticate the connector as described in the [Setup guide](https://central.ballerina.io/ballerinax/slack/latest#setup-guide).

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