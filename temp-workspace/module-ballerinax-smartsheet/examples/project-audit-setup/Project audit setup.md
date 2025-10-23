# Project Audit Setup

This example demonstrates how to set up a project audit by creating a new workspace and sheet in Smartsheet with predefined columns for tracking project information.

## Prerequisites

1. **Smartsheet Setup**
   > Refer the [Smartsheet setup guide](https://central.ballerina.io/ballerinax/smartsheet/latest#setup-guide) here.

2. For this example, create a `Config.toml` file with your credentials:

```toml
token = "<Your Smartsheet Access Token>"
```

## Run the example

Execute the following command to run the example. The script will create a new workspace and sheet with audit columns, then print the results to the console.

```shell
bal run
```

The script will:
1. Create a new workspace named "Project Audit Workspace"
2. Create a new sheet within that workspace with columns for project tracking
3. Display the created workspace and sheet information