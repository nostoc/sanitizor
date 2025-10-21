import ballerina/io;
import ballerinax/smartsheet;

configurable string accessToken = ?;

public function main() returns error? {
    smartsheet:Client smartsheetClient = check new({
        auth: {
            token: accessToken
        }
    });

    io:println("Starting project workspace setup...");

    // Create a sample CSV content for the project sheet
    string csvContent = "Task Name,Assigned To,Status,Due Date\nProject Planning,John Doe,In Progress,2024-01-15\nRequirements Gathering,Jane Smith,Not Started,2024-01-20\nDesign Phase,Mike Johnson,Not Started,2024-02-01";
    byte[] csvBytes = csvContent.toBytes();

    // For this example, we'll use placeholder IDs since we can't create workspaces and folders with the provided definitions
    string workspaceId = "12345";
    decimal folderId = 67890;

    io:println("Creating project tracking sheet in workspace...");

    smartsheet:ImportSheetIntoWorkspaceHeaders workspaceHeaders = {
        authorization: "Bearer " + accessToken,
        contentDisposition: "attachment; filename=\"project_tasks.csv\"",
        contentType: "text/csv"
    };

    smartsheet:ImportSheetIntoWorkspaceQueries workspaceQueries = {
        sheetName: "Project Tasks and Milestones",
        headerRowIndex: 0,
        primaryColumnIndex: 0
    };

    smartsheet:WebhookListResponse workspaceSheetResponse = check smartsheetClient->/workspaces/[workspaceId]/sheets/'import.post(
        workspaceHeaders,
        csvBytes,
        workspaceQueries
    );

    io:println("Workspace sheet created successfully:");
    io:println("Result Code: ", workspaceSheetResponse.resultCode);
    io:println("Message: ", workspaceSheetResponse.message);
    if workspaceSheetResponse.result is smartsheet:SheetImported {
        smartsheet:SheetImported sheet = <smartsheet:SheetImported>workspaceSheetResponse.result;
        io:println("Sheet ID: ", sheet.id);
        io:println("Sheet Name: ", sheet.name);
        io:println("Sheet Type: ", sheet.'type);
    }

    io:println("\nCreating project tracking sheet in folder...");

    smartsheet:ImportSheetIntoFolderHeaders folderHeaders = {
        authorization: "Bearer " + accessToken,
        contentDisposition: "attachment; filename=\"folder_project_tasks.csv\"",
        contentType: "text/csv"
    };

    smartsheet:ImportSheetIntoFolderQueries folderQueries = {
        sheetName: "Folder Project Tasks",
        headerRowIndex: 0,
        primaryColumnIndex: 0
    };

    smartsheet:WebhookListResponse folderSheetResponse = check smartsheetClient->/folders/[folderId]/sheets/'import.post(
        folderHeaders,
        csvBytes,
        folderQueries
    );

    io:println("Folder sheet created successfully:");
    io:println("Result Code: ", folderSheetResponse.resultCode);
    io:println("Message: ", folderSheetResponse.message);
    if folderSheetResponse.result is smartsheet:SheetImported {
        smartsheet:SheetImported sheet = <smartsheet:SheetImported>folderSheetResponse.result;
        io:println("Sheet ID: ", sheet.id);
        io:println("Sheet Name: ", sheet.name);
        io:println("Sheet Type: ", sheet.'type);
    }

    io:println("\nProject workspace setup completed successfully!");
}