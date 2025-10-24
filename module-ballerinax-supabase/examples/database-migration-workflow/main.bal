import ballerina/io;
import ballerina/http;
import ballerinax/supabase;

configurable string serviceUrl = ?;
configurable string accessToken = ?;
configurable string projectRef = ?;

public function main() returns error? {
    supabase:ConnectionConfig config = {
        auth: {
            token: accessToken
        },
        httpVersion: http:HTTP_2_0,
        http1Settings: {},
        http2Settings: {},
        timeout: 30
    };

    supabase:Client supabaseClient = check new (config, serviceUrl);

    io:println("Starting comprehensive branch management workflow for database schema migrations...");

    io:println("\nStep 1: Creating new feature branch from main branch...");
    supabase:CreateBranchBody createBranchPayload = {
        branchName: "feature/schema-migration-v2",
        desiredInstanceSize: "micro",
        postgresEngine: "15",
        releaseChannel: "ga"
    };

    supabase:BranchResponse branchResponse = check supabaseClient->/v1/projects/[projectRef]/branches.post(createBranchPayload);
    io:println("Feature branch created successfully:");
    io:println("Branch Name: " + branchResponse.gitBranch.toString());
    io:println("Project Ref: " + branchResponse.projectRef);
    io:println("Created At: " + branchResponse.createdAt);
    io:println("Is Default: " + branchResponse.isDefault.toString());

    io:println("\nStep 2: Applying migration scripts to the feature branch...");
    supabase:V1CreateMigrationBody migrationPayload = {
        query: "CREATE TABLE user_profiles (id SERIAL PRIMARY KEY, user_id UUID NOT NULL, profile_data JSONB, created_at TIMESTAMP DEFAULT NOW()); CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);",
        name: "add_user_profiles_table_with_index"
    };

    supabase:V1ApplyAMigrationHeaders migrationHeaders = {
        idempotencyKey: "migration-user-profiles-v2-20241201"
    };

    check supabaseClient->/v1/projects/[projectRef]/database/migrations.post(migrationPayload, migrationHeaders);
    io:println("Migration scripts applied successfully to feature branch");
    io:println("Migration: " + migrationPayload.name.toString());

    io:println("\nStep 3: Testing additional schema changes...");
    supabase:V1CreateMigrationBody additionalMigrationPayload = {
        query: "ALTER TABLE user_profiles ADD COLUMN updated_at TIMESTAMP DEFAULT NOW(); CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();",
        name: "add_updated_at_trigger_user_profiles"
    };

    supabase:V1ApplyAMigrationHeaders additionalMigrationHeaders = {
        idempotencyKey: "migration-user-profiles-trigger-v2-20241201"
    };

    check supabaseClient->/v1/projects/[projectRef]/database/migrations.post(additionalMigrationPayload, additionalMigrationHeaders);
    io:println("Additional migration applied successfully");
    io:println("Migration: " + additionalMigrationPayload.name.toString());

    io:println("\nStep 4: Generating detailed diff report comparing feature branch against main branch...");
    supabase:V1DiffABranchQueries diffQueries = {
        includedSchemas: "public,auth"
    };

    string diffReport = check supabaseClient->/v1/branches/["feature/schema-migration-v2"]/diff(queries = diffQueries);
    
    io:println("Database schema diff report generated successfully:");
    io:println("=== SCHEMA DIFF REPORT ===");
    io:println(diffReport);
    io:println("=== END OF DIFF REPORT ===");

    io:println("\nBranch management workflow completed successfully!");
    io:println("Summary:");
    io:println("- Feature branch 'feature/schema-migration-v2' created from main");
    io:println("- Applied 2 migration scripts with schema changes");
    io:println("- Generated comprehensive diff report for code review");
    io:println("- Ready for code review and eventual merge to main branch");
}