# Security Monitoring Setup

This example demonstrates how to set up security monitoring using Supabase to track and manage security events in your application.

## Prerequisites

1. **Supabase Setup**
   > Refer to the [Supabase setup guide](https://central.ballerina.io/ballerinax/supabase/latest#setup-guide) to obtain the necessary credentials and configure your Supabase project.

2. For this example, create a `Config.toml` file with your credentials:

```toml
# Add your Supabase configuration here
supabaseUrl = "<Your Supabase URL>"
supabaseKey = "<Your Supabase API Key>"
```

## Run the example

Execute the following command to run the example. The script will set up security monitoring and print its progress to the console.

```shell
bal run
```