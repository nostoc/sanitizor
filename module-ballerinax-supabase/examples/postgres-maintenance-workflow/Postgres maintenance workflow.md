# Postgres Maintenance Workflow

This example demonstrates a basic Postgres maintenance workflow setup using Ballerina.

## Prerequisites

1. **Supabase Setup**
   > Refer the [Supabase setup guide](https://central.ballerina.io/ballerinax/supabase/latest) here.

2. **Configuration**
   For this example, create a `Config.toml` file with your credentials:

```toml
# Add your Supabase configuration here
supabaseUrl = "<Your Supabase URL>"
supabaseKey = "<Your Supabase API Key>"
```

## Run the Example

Execute the following command to run the example. The script will execute the maintenance workflow and print its progress to the console.

```shell
bal run
```

The maintenance workflow will connect to your Postgres database through Supabase and perform the configured maintenance operations.