import ballerina/http;
import ballerina/lang.'string as strings;
import ballerina/log;
import ballerina/regex;
import ballerina/time;
import ballerinax/slack;
import ballerinax/smartsheet;

//configurations
configurable string smartsheetToken = ?;
configurable string projectsSheetName = ?;
configurable string tasksSheetName = ?;

configurable string slackToken = ?;
configurable string slackChannel = ?;

// Column titles
const COL_PROJ_NAME = "Project Name";
const COL_PROJ_START = "Start Date";
const COL_PROJ_STATUS = "Status";

const COL_TASK_NAME = "Task Name";
const COL_TASK_ASSIGNEE = "Assigned To";
const COL_TASK_DUE = "Due Date";
const COL_TASK_PROJECT = "Project Name";

// Predefined initial tasks
type TaskTemplate record {|
    string name;
    int dueOffsetDays; // startDate + offset days
|};

final TaskTemplate[] TASKS = [
    {name: "Kick-off Meeting", dueOffsetDays: 1},
    {name: "Requirement Gathering", dueOffsetDays: 3},
    {name: "Resource Allocation", dueOffsetDays: 5}
];

// default assignee (can be overridden in request)
configurable string defaultAssignee = "pm@example.com";

// initialize clients
final smartsheet:Client smartsheetClient = check new ({
    auth: {token: smartsheetToken}
});

final slack:Client slackClient = check new ({
    auth: {token: slackToken}
});

// types
type NewProjectRequest record {|
    string projectName;
    string startDate;
    string assignedTo?;
    string status;
|};

// helper functions
function findSheetIdByName(string sheetName) returns decimal|error {
    // Get list of all sheets that the user has access to
    smartsheet:AlternateEmailListResponse response = check smartsheetClient->/sheets();

    // Check if we have sheet data
    smartsheet:SchemasSheet[]? sheetsData = response.data;
    if sheetsData is smartsheet:SchemasSheet[] {
        // Search for the sheet by name
        foreach smartsheet:SchemasSheet sheet in sheetsData {
            string? name = sheet.name;
            decimal? id = sheet.id;
            if name is string && id is decimal && name == sheetName {
                return id;
            }
        }
    }
    return error(string `Sheet not found: ${sheetName}`);
}

function getColumnIds(decimal sheetId, string[] wantedTitles) returns map<decimal>|error {
    smartsheet:ColumnListResponse response = check smartsheetClient->/sheets/[sheetId]/columns();
    smartsheet:GetColumn[]? columnsData = response.data;

    if columnsData is smartsheet:GetColumn[] {
        map<decimal> out = {};
        foreach smartsheet:GetColumn c in columnsData {
            string? columnTitle = c.title;
            decimal? columnId = c.id;
            if columnTitle is string && columnId is decimal {
                foreach string title in wantedTitles {
                    if columnTitle == title {
                        out[columnTitle] = columnId;
                    }
                }
            }
        }
        // ensure all wanted titles were found
        foreach string title in wantedTitles {
            if out[title] is () {
                return error(string `Column not found: ${title}`);
            }
        }
        return out;
    }
    return error(string `Failed to get columns for sheet ${sheetId}`);
}

// Extracts date part from datetime string
function onlyDate(string dateOrDateTime) returns string {
    // Accepts "YYYY-MM-DD" or "YYYY-MM-DDTHH:mm:ssZ"
    if dateOrDateTime.length() >= 10 {
        return dateOrDateTime.substring(0, 10);
    }
    return dateOrDateTime;
}

// Adds specified number of days to a date
function addDays(string ymd, int days) returns string|error {
    // ymd is "YYYY-MM-DD"
    string[] parts = regex:split(ymd, "-");
    if parts.length() != 3 {
        return error("Invalid date format; expected YYYY-MM-DD");
    }
    int y = check int:fromString(parts[0]);
    int m = check int:fromString(parts[1]);
    int d = check int:fromString(parts[2]);

    time:Date date = {year: y, month: m, day: d};
    // time:Utc utc = time:utcNow();
    time:Civil civil = {year: date.year, month: date.month, day: date.day, hour: 0, minute: 0, second: 0};
    time:Utc|time:Error timeUtc = time:utcFromCivil(civil);
    if timeUtc is time:Error {
        return error("Failed to convert date");
    }

    time:Utc newUtc = time:utcAddSeconds(timeUtc, days * 86400);
    time:Civil newCivil = time:utcToCivil(newUtc);

    string mm = newCivil.month < 10 ? "0" + newCivil.month.toString() : newCivil.month.toString();
    string dd = newCivil.day < 10 ? "0" + newCivil.day.toString() : newCivil.day.toString();

    return string `${newCivil.year}-${mm}-${dd}`;
}

// Create initial tasks for a new project
function createInitialTasksForProject(NewProjectRequest req) returns json|error {
    // Resolve sheets
    decimal projectsSheetId = check findSheetIdByName(projectsSheetName);
    decimal tasksSheetId = check findSheetIdByName(tasksSheetName);

    // Resolve required columns
    map<decimal> projCols = check getColumnIds(projectsSheetId, [COL_PROJ_NAME, COL_PROJ_START, COL_PROJ_STATUS]);
    map<decimal> taskCols = check getColumnIds(tasksSheetId, [COL_TASK_NAME, COL_TASK_ASSIGNEE, COL_TASK_DUE, COL_TASK_PROJECT]);

    // Normalize inputs
    string projName = strings:trim(req.projectName);
    string startDate = onlyDate(req.startDate);
    string status = strings:trim(req.status);

    // determine assignee
    string assignee = defaultAssignee;
    string? assignedToValue = req.assignedTo;
    if assignedToValue is string {
        string trimmed = strings:trim(assignedToValue);
        if trimmed != "" {
            assignee = trimmed;
        }
    }

    // first add the project to the projects sheet
    smartsheet:Cell[] projectCells = [
        {columnId: projCols[COL_PROJ_NAME], value: projName},
        {columnId: projCols[COL_PROJ_START], value: startDate},
        {columnId: projCols[COL_PROJ_STATUS], value: status}
    ];
    smartsheet:Row projectRow = {cells: projectCells};
    smartsheet:Row[] projectRows = [projectRow];

    smartsheet:RowMoveResponse projectResponse = check smartsheetClient->/sheets/[projectsSheetId]/rows.post(projectRows);

    // Build Smartsheet rows for tasks
    smartsheet:Row[] newRows = [];
    foreach TaskTemplate t in TASKS {
        string|error due = addDays(startDate, t.dueOffsetDays);
        if due is error {
            return due;
        }
        smartsheet:Cell[] cells = [
            {columnId: taskCols[COL_TASK_NAME], value: t.name},
            {columnId: taskCols[COL_TASK_ASSIGNEE], value: assignee},
            {columnId: taskCols[COL_TASK_DUE], value: due},
            {columnId: taskCols[COL_TASK_PROJECT], value: projName}
        ];
        newRows.push({cells: cells});
    }
    smartsheet:RowMoveResponse taskResponse = check smartsheetClient->/sheets/[tasksSheetId]/rows.post(newRows);

    // Notify via Slack (single summary message)
    string summary = string `Created ${newRows.length()} initial tasks for project "${projName}" (start: ${startDate}). Assignee: ${assignee}`;
    error? slackResult = sendSlackMessage(slackChannel, summary);
    if slackResult is error {
        log:printWarn("Failed to send Slack notification: " + slackResult.message());
    }
    return {
        "message": "Initial tasks created",
        "project": projName,
        "startDate": startDate,
        "tasksCreated": newRows.length(),
        "assignee": assignee
    };
}

// notify slack
function sendSlackMessage(string channel, string text) returns error? {
    log:printInfo("Sending Slack message to channel: ", channel = channel);
    slack:ChatPostMessageResponse|error result = slackClient->/chat\.postMessage.post({
        channel: channel,
        text: text
    });
    if result is error {
        log:printError("Failed to send Slack message", 'error = result);
        return result;
    }
    log:printInfo("Slack notification sent to channel: ", channel = channel);
}

service / on new http:Listener(8080) {
    resource function post projects(NewProjectRequest req) returns http:Ok|http:BadRequest|http:InternalServerError {
        log:printInfo("Received project creation request: ", projectName = req.projectName);

        var res = createInitialTasksForProject(req);
        if res is json {
            return <http:Ok>{body: res};
        } else {
            log:printError("Failed to create initial tasks", res);
            return <http:InternalServerError>{
                body: {"error": res.message()}
            };
        }
    }
}
