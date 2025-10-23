# Examples

The `supabase` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples), covering use cases like feature branch workflow, postgres maintenance workflow, and supabase security monitoring.

1. [Feature branch workflow](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples/feature-branch-workflow) - Implement automated workflows for managing feature branches in Supabase projects.

2. [Postgres maintenance workflow](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples/postgres-maintenance-workflow) - Automate PostgreSQL database maintenance tasks and operations in Supabase.

3. [Supabase security monitoring](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples/supabase-security-monitoring) - Monitor and track security events and access patterns in Supabase applications.

4. [Production monitoring setup](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples/production-monitoring-setup) - Configure comprehensive monitoring and alerting for production Supabase environments.

## Prerequisites

1. Generate Supabase credentials to authenticate the connector as described in the [Setup guide](https://central.ballerina.io/ballerinax/supabase/latest#setup-guide).

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