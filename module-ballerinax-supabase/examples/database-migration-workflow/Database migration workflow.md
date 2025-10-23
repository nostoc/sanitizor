# Database Migration Workflow

This example demonstrates how to perform database migration operations using Supabase, including creating tables, inserting data, and managing database schema changes programmatically.

## Prerequisites

1. **Supabase Setup**
   > Refer the [Supabase setup guide](https://central.ballerina.io/ballerinax/supabase/latest#setup-guide) here.

2. For this example, create a `Config.toml` file with your credentials:

```toml
supabaseUrl = "<Your Supabase URL>"
supabaseKey = "<Your Supabase API Key>"
```

## Run the example

Execute the following command to run the example. The script will print its progress to the console.

```shell
bal run
```

The script will perform database migration operations and display the results of each step in the migration workflow.