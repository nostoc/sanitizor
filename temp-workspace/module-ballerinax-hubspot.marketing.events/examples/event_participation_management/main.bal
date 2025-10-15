// Copyright (c) 2025 WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/io;
import ballerina/oauth2;
import ballerinax/hubspot.marketing.events as hsmevents;

configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string refreshToken = ?;

public function main() returns error? {

    hsmevents:OAuth2RefreshTokenGrantConfig auth = {
        clientId,
        clientSecret,
        refreshToken,
        credentialBearer: oauth2:POST_BODY_BEARER // this line should be added in to when you are going to create auth object.
    };
    hsmevents:ConnectionConfig config = {auth};

    final hsmevents:Client hubspotMarketingClient = check new (config);

    // Step 1: Create a new event

    hsmevents:MarketingEventCreateRequestParams createPayload = {
        externalAccountId: "11111",
        externalEventId: "12000",
        eventName: "Winter webinar",
        eventOrganizer: "Snowman Fellowship",
        eventCancelled: false,
        eventUrl: "https://example.com/holiday-jam",
        eventType: "WEBINAR",
        eventDescription: "Let's get together to plan for the holidays",
        eventCompleted: false,
        startDateTime: "2024-08-06T12:36:59.286Z",
        endDateTime: "2024-08-08T12:36:59.286Z",
        customProperties: []
    };

    hsmevents:MarketingEventDefaultResponse createResp = check hubspotMarketingClient->postEventsCreate(createPayload);

    string eventObjId = createResp?.objectId ?: "-1";

    io:println("Event Created: ", eventObjId);

    // Step 2: Register Participants to the event using event id

    // NOTE: Registering participants to an event takes some time to process. The data might not be populated at once.

    hsmevents:BatchInputMarketingEventEmailSubscriber dummyParticipants = {
        inputs: [
            {
                email: "john.doe@example.com",
                interactionDateTime: 23423234234
            }
        ]
    };

    hsmevents:BatchResponseSubscriberVidResponse registerResp = check
    hubspotMarketingClient->postObjectIdAttendanceSubscriberStateEmailCreate(eventObjId, "register", dummyParticipants);

    io:println("Participants Registered: ", registerResp?.results.toJson() ?: "Failed");

    // Step 3: Change Participant Status using external ids

    // NOTE: Changing participant state takes some time to process. The changes might not be visible immediately.

    http:Response attendResp = check
    hubspotMarketingClient->postEventsExternalEventIdSubscriberStateEmailUpsertUpsertByContactEmail(
        "12000", "attend", dummyParticipants, externalAccountId = "11111");

    io:println("Participant Status Changed: ", attendResp.statusCode == 202 ? "Success" : "Failed");

    // Step 4: Get Participant Breakdown of a particular event

    hsmevents:CollectionResponseWithTotalParticipationBreakdownForwardPaging participants = check hubspotMarketingClient->
    getParticipationsExternalAccountIdExternalEventIdBreakdownGetParticipationsBreakdownByExternalEventId(
        "11111", "12000");

    io:println(participants);

    io:println("Participants Breakdown: ", participants?.results.toJson() ?: "Failed");

    // Step 5: Delete Event

    error? deleteResp = hubspotMarketingClient->deleteObjectId(eventObjId);

    io:println("Event Deleted: ", deleteResp is () ? "Success" : "Failed");
}
