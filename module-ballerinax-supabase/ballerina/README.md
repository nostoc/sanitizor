## Overview

[Supabase](https://supabase.com/) is an open-source Firebase alternative that provides a complete backend-as-a-service platform with real-time databases, authentication, instant APIs, edge functions, and storage solutions for modern applications.

The `ballerinax/supabase` package offers APIs to connect and interact with [Supabase API](https://supabase.com/docs/reference/api) endpoints, specifically based on [Supabase REST API](https://supabase.com/docs/reference/api/rest).
## Setup guide

To use the Supabase connector, you must have access to the Supabase API through a [Supabase project](https://supabase.com/docs) and obtain API credentials including your project URL and service role key. If you do not have a Supabase account, you can sign up for one [here](https://supabase.com).

### Step 1: Create a Supabase Account

1. Navigate to the [Supabase website](https://supabase.com) and sign up for an account or log in if you already have one.

2. Create a new project or select an existing project. API access is available on all Supabase plans including the free tier.

### Step 2: Generate API Credentials

1. Log in to your Supabase account and navigate to your project dashboard.

2. In the left sidebar, go to Settings, then select API.

3. In the API Settings page, you will find your Project URL and API Keys section containing your `anon public` key and `service_role` key.

4. Copy the Project URL and the service_role key (for server-side operations) or anon key (for client-side operations with RLS enabled).

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
        name: "My New Project",
        organizationId: "my-organization",
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

The `supabase` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples), covering the following use cases:

1. [Database backup recovery](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples/database-backup-recovery) - Demonstrates how to implement database backup and recovery operations using the Supabase connector.
2. [Database migration workflow](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples/database-migration-workflow) - Illustrates managing database schema migrations and data transfer workflows.
3. [Project health optimization](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples/project-health-optimization) - Shows how to monitor and optimize project health metrics using Supabase analytics.
4. [Security audit workflow](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples/security-audit-workflow) - Demonstrates implementing security auditing and compliance monitoring workflows.