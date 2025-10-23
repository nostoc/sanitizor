## Overview

[Supabase](https://supabase.com/) is an open-source Firebase alternative that provides a complete backend-as-a-service platform with a PostgreSQL database, authentication, real-time subscriptions, edge functions, and storage capabilities.

The `ballerinax/supabase` package offers APIs to connect and interact with [Supabase API](https://supabase.com/docs/reference/api) endpoints, specifically based on a recent version of the API.
## Setup guide

To use the Supabase connector, you must have access to the Supabase API through a [Supabase project](https://supabase.com/docs) and obtain API credentials including your project URL and anon/service role key. If you do not have a Supabase account, you can sign up for one [here](https://supabase.com/dashboard).

### Step 1: Create a Supabase Account

1. Navigate to the [Supabase website](https://supabase.com/) and sign up for an account or log in if you already have one.

2. Create a new project or select an existing project. API access is available on all Supabase plans including the free tier.

### Step 2: Generate API Credentials

1. Log in to your Supabase dashboard.

2. Select your project from the dashboard.

3. In the left sidebar, navigate to Settings, then select API.

4. In the API settings page, you will find your Project URL and API Keys (anon public key and service_role secret key).

> **Tip:** You must copy and store these credentials somewhere safe. The service_role key provides full access to your database and should be kept secure.
## Quickstart

To use the `supabase` connector in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

```ballerina
import ballerinax/supabase;
```

### Step 2: Instantiate a new connector

1. Create a `Config.toml` file and configure the obtained access token:

```toml
token = "<Your_Supabase_Access_Token>"
```

2. Create a `supabase:ConnectionConfig` and initialize the client:

```ballerina
configurable string token = ?;

final supabase:Client supabaseClient = check new({
    auth: {
        token
    }
}, "https://api.supabase.com");
```

### Step 3: Invoke the connector operation

Now, utilize the available connector operations.

#### Create a new project

```ballerina
public function main() returns error? {
    supabase:V1CreateProjectBody newProject = {
        name: "My New Project",
        organizationId: "my-organization-id",
        dbPass: "securePassword123"
    };

    supabase:V1ProjectResponse response = check supabaseClient->/v1/projects.post(newProject);
}
```

### Step 4: Run the Ballerina application

```bash
bal run
```
## Examples

The `Supabase` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples), covering the following use cases:

1. [Security monitoring setup](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples/security-monitoring-setup) - Demonstrates how to configure and implement security monitoring for Supabase applications.
2. [Database migration workflow](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples/database-migration-workflow) - Illustrates the process of migrating database schemas and data using Supabase.
3. [Database upgrade workflow](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples/database-upgrade-workflow) - Shows how to upgrade database versions and apply schema changes in Supabase.
4. [Branch cleanup workflow](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples/branch-cleanup-workflow) - Demonstrates automated cleanup of database branches and temporary resources.