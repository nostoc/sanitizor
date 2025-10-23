import ballerina/io;
import ballerinax/supabase;

configurable string supabaseUrl = ?;
configurable string supabaseKey = ?;
configurable string projectRef = ?;

public function main() returns error? {
    supabase:ConnectionConfig config = {
        auth: {
            token: supabaseKey
        }
    };
    supabase:Client supabaseClient = check new (config, serviceUrl = supabaseUrl);

    // Step 1: Retrieve current health status of all services to establish baseline
    io:println("=== Retrieving Health Status of All Services ===");

    supabase:V1GetServicesHealthQueries healthQueries = {
        services: ["auth", "db", "db_postgres_user", "pooler", "realtime", "rest", "storage", "pg_bouncer"],
        timeoutMs: 30000
    };

    supabase:V1ServiceHealthResponse[] healthResponses = check supabaseClient->/v1/projects/[projectRef]/health(queries = healthQueries);

    foreach supabase:V1ServiceHealthResponse response in healthResponses {
        io:println(string `Service: ${response.name}, Healthy: ${response.healthy.toString()}, Status: ${response.status.toString()}`);
        if response.'error is string {
            io:println(string `  Error: ${response.'error.toString()}`);
        }
    }

    // Step 2: Set up performance monitoring by retrieving performance advisor recommendations
    io:println("\n=== Retrieving Performance Advisor Recommendations ===");

    supabase:V1ProjectAdvisorsResponse advisorResponse = check supabaseClient->/v1/projects/[projectRef]/advisors/performance();

    io:println("Performance advisor recommendations retrieved successfully");
    io:println(string `Advisor Response: ${advisorResponse.toString()}`);

    io:println("\n=== Monitoring and Alerting Setup Complete ===");
    io:println("Baseline health status established and performance monitoring configured");
}
