import ballerina/io;
import ballerina/http;
import ballerinax/supabase;

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
    
    io:println("=== Starting Comprehensive Project Security Audit ===");
    
    io:println("\n1. Retrieving Security Advisors...");
    supabase:V1GetSecurityAdvisorsQueries securityQueries = {
        lintType: "sql"
    };
    
    supabase:V1ProjectAdvisorsResponse|error securityAdvisors = supabaseClient->/v1/projects/[projectRef]/advisors/security(queries = securityQueries);
    
    if securityAdvisors is supabase:V1ProjectAdvisorsResponse {
        io:println("Security advisors retrieved successfully:");
        io:println(securityAdvisors);
    } else {
        io:println("Error retrieving security advisors: " + securityAdvisors.message());
    }
    
    io:println("\n=== Security Audit Complete ===");
}