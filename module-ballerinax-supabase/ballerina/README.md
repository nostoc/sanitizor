## Overview

[Supabase](https://supabase.com/) is an open-source Firebase alternative that provides a complete backend-as-a-service platform with real-time databases, authentication, instant APIs, edge functions, and storage solutions for modern applications.

The `ballerinax/supabase` package offers APIs to connect and interact with [Supabase API](https://supabase.com/docs/reference/api) endpoints, specifically based on a recent version of the API.
## Setup guide

To use the Supabase connector, you must have access to the Supabase API through a [Supabase project](`https://supabase.com/docs`) and obtain an API key. If you do not have a Supabase account, you can sign up for one [here](`https://supabase.com/`).

### Step 1: Create a Supabase Account

1. Navigate to the [Supabase website](`https://supabase.com/`) and sign up for an account or log in if you already have one.

2. Create a new project or select an existing project. API access is available on all Supabase plans, including the free tier.

### Step 2: Generate an API Key

1. Log in to your Supabase account and navigate to your project dashboard.

2. In the left sidebar, click on Settings, then select API from the settings menu.

3. On the API settings page, you will find your project URL and API keys. Copy the `anon` key for public client access or the `service_role` key for server-side access with elevated privileges.

> **Tip:** You must copy and store this key somewhere safe. It won't be visible again in your account settings for security reasons.
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
        organizationId: "my-org-id",
        name: "My New Project",
        dbPass: "secure_password_123"
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

1. [Feature branch workflow](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples/feature-branch-workflow) - Demonstrates how to manage feature branch deployments and database migrations in Supabase.
2. [Postgres maintenance workflow](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples/postgres-maintenance-workflow) - Illustrates automated PostgreSQL database maintenance tasks and optimization procedures.
3. [Supabase security monitoring](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples/supabase-security-monitoring) - Shows how to implement security monitoring and threat detection for Supabase applications.
4. [Production monitoring setup](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples/production-monitoring-setup) - Demonstrates setting up comprehensive monitoring and alerting for production Supabase environments.