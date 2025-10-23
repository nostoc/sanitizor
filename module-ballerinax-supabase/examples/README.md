# Examples

The `supabase` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples), covering use cases like security monitoring setup, database migration workflow, and database upgrade workflow.

1. [Security monitoring setup](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples/security-monitoring-setup) - Configure and implement security monitoring for Supabase database operations and access patterns.

2. [Database migration workflow](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples/database-migration-workflow) - Automate database schema migrations and data transfers between Supabase environments.

3. [Database upgrade workflow](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples/database-upgrade-workflow) - Manage database version upgrades and schema changes in Supabase projects.

4. [Branch cleanup workflow](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples/branch-cleanup-workflow) - Automatically clean up database branches and temporary resources in Supabase development environments.

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