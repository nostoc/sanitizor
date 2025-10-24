# Examples

The `supabase` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples), covering use cases like database backup and recovery, database migration workflows, and security audit processes.

1. [Database backup recovery](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples/database-backup-recovery) - Implement automated database backup and recovery procedures for Supabase databases.

2. [Database migration workflow](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples/database-migration-workflow) - Execute database schema migrations and data transformations in Supabase environments.

3. [Project health optimization](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples/project-health-optimization) - Monitor and optimize Supabase project performance and resource utilization.

4. [Security audit workflow](https://github.com/ballerina-platform/module-ballerinax-supabase/tree/main/examples/security-audit-workflow) - Perform comprehensive security audits and compliance checks on Supabase projects.

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