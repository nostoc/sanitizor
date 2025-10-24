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
    
    io:println("=== DevOps Monitoring and Alerting System Setup ===");
    
    // Step 1: Retrieve current database configuration
    io:println("\n1. Retrieving current database configuration...");
    supabase:PostgresConfigResponse dbConfig = check supabaseClient->/v1/projects/[projectRef]/config/database/postgres();
    io:println("Database Configuration Retrieved:");
    io:println("Max Connections: " + (dbConfig.maxConnections ?: 0).toString());
    io:println("Max Parallel Workers: " + (dbConfig.maxParallelWorkers ?: 0).toString());
    io:println("Max Locks Per Transaction: " + (dbConfig.maxLocksPerTransaction ?: 0).toString());
    io:println("Session Replication Role: " + (dbConfig.sessionReplicationRole ?: "unknown"));
    io:println("Shared Buffers: " + (dbConfig.sharedBuffers ?: "unknown"));
    
    // Step 2: Check project health status across all services
    io:println("\n2. Checking project health status across all services...");
    supabase:V1GetServicesHealthQueries healthQueries = {
        services: ["auth", "db", "db_postgres_user", "pooler", "realtime", "rest", "storage", "pg_bouncer"],
        timeoutMs: 30000
    };
    
    supabase:V1ServiceHealthResponse[] healthResponses = check supabaseClient->/v1/projects/[projectRef]/health(queries = healthQueries);
    
    io:println("Health Status Summary:");
    foreach supabase:V1ServiceHealthResponse response in healthResponses {
        string statusValue = response.status is string ? response.status : "unknown";
        io:println("Service: " + response.name + " | Healthy: " + response.healthy.toString() + " | Status: " + statusValue);
        if response.'error is string {
            io:println("  Error: " + <string>response.'error);
        }
    }
    
    // Step 3: Display baseline metrics summary
    io:println("\n3. Baseline Metrics Established:");
    int healthyServices = 0;
    int totalServices = healthResponses.length();
    
    foreach supabase:V1ServiceHealthResponse response in healthResponses {
        if response.healthy {
            healthyServices += 1;
        }
    }
    
    io:println("Total Services Monitored: " + totalServices.toString());
    io:println("Healthy Services: " + healthyServices.toString());
    io:println("Service Health Percentage: " + ((healthyServices * 100) / totalServices).toString() + "%");
    
    io:println("\n=== Monitoring Setup Complete ===");
    io:println("Database configuration retrieved and baseline health metrics established.");
    io:println("SSL enforcement and security compliance should be configured through Supabase dashboard.");
}