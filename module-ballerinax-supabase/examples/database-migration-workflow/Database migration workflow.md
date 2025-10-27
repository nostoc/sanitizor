# Database Migration Workflow

This example demonstrates how to perform database migration operations using Supabase, including creating tables, inserting sample data, and managing database schema changes.

## Prerequisites

1. **Supabase Setup**
   > Refer the [Supabase setup guide](https://central.ballerina.io/ballerinax/supabase/latest) here.

2. For this example, create a `Config.toml` file with your credentials:

```toml
supabaseUrl = "<Your Supabase Project URL>"
supabaseKey = "<Your Supabase API Key>"
```

## Run the example

Execute the following command to run the example. The script will print its progress to the console.

```shell
bal run
```

The migration workflow will:
- Connect to your Supabase database
- Execute migration scripts to create or update database tables
- Insert or update sample data as needed
- Display the results of the migration operations