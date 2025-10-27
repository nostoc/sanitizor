import ballerina/io;
import ballerinax/supabase;
import ballerina/http;

configurable string supabaseUrl = ?;
configurable string supabaseToken = ?;
configurable string projectRef = ?;

public function main() returns error? {
    supabase:ConnectionConfig config = {
        auth: {
            token: supabaseToken
        },
        httpVersion: http:HTTP_2_0,
        http1Settings: {},
        http2Settings: {},
        timeout: 30
    };

    supabase:Client supabaseClient = check new (config, supabaseUrl);

    io:println("=== Step 1: Retrieving Health Status ===");
    supabase:V1GetServicesHealthQueries healthQueries = {
        services: ["auth", "db", "db_postgres_user", "pooler", "realtime", "rest", "storage", "pg_bouncer"]
    };

    supabase:V1ServiceHealthResponse[] healthResponse = check supabaseClient->/v1/projects/[projectRef]/health(queries = healthQueries);
    
    io:println("Health Status Results:");
    foreach supabase:V1ServiceHealthResponse svc in healthResponse {
        io:println(string `Service: ${svc.name}, Healthy: ${svc.healthy}, Status: ${svc.status}`);
        if svc.'error is string {
            io:println(string `  Error: ${svc.'error.toString()}`);
        }
    }

    io:println("\n=== Step 2: Fetching Performance Advisor Recommendations ===");
    supabase:V1ProjectAdvisorsResponse advisorResponse = check supabaseClient->/v1/projects/[projectRef]/advisors/performance();
    
    io:println("Performance Advisor Recommendations:");
    io:println(advisorResponse.toString());

    io:println("\n=== Step 3: Applying Database Configuration Changes ===");
    map<string|string[]> configUpdate = {
        "maxParallelWorkers": "4",
        "sessionReplicationRole": "origin",
        "sharedBuffers": "256MB",
        "maxWalSenders": "10",
        "walSenderTimeout": "60s"
    };

    supabase:PostgresConfigResponse configResponse = check supabaseClient->/v1/projects/[projectRef]/config/database/postgres(configUpdate);
    
    io:println("Database Configuration Update Results:");
    if configResponse.maxConnections is int {
        io:println(string `Max Connections: ${configResponse.maxConnections.toString()}`);
    }
    if configResponse.maxParallelWorkers is int {
        io:println(string `Max Parallel Workers: ${configResponse.maxParallelWorkers.toString()}`);
    }
    if configResponse.sessionReplicationRole is string {
        io:println(string `Session Replication Role: ${configResponse.sessionReplicationRole.toString()}`);
    }
    if configResponse.sharedBuffers is string {
        io:println(string `Shared Buffers: ${configResponse.sharedBuffers.toString()}`);
    }

    io:println("\n=== Project Monitoring and Maintenance Workflow Completed ===");
}