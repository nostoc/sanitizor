# Database Upgrade Workflow

This example demonstrates how to implement a database upgrade workflow using Supabase, including schema migrations, data transformations, and rollback capabilities.

## Prerequisites

1. **Supabase Setup**
   > Refer the [Supabase setup guide](https://central.ballerina.io/ballerinax/supabase/latest#setup-guide) here.

2. For this example, create a `Config.toml` file with your credentials:

```toml
supabaseUrl = "<Your Supabase URL>"
supabaseKey = "<Your Supabase Anon Key>"
```

## Run the example

Execute the following command to run the example. The script will print its progress to the console.

```shell
bal run
```

The workflow will:
1. Connect to your Supabase database
2. Execute schema upgrade scripts
3. Perform data migrations
4. Validate the upgrade process
5. Provide rollback options if needed