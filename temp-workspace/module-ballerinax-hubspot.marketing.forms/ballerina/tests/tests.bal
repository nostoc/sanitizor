// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).
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

import ballerina/oauth2;
import ballerina/os;
import ballerina/test;
import ballerina/time;

configurable boolean enableClient0auth2 = os:getEnv("IS_LIVE_SERVER") == "false";
configurable string clientId = enableClient0auth2 ? os:getEnv("CLIENT_ID") : "test";
configurable string clientSecret = enableClient0auth2 ? os:getEnv("CLIENT_SECRET") : "test";
configurable string refreshToken = enableClient0auth2 ? os:getEnv("REFRESH_TOKEN") : "test";

OAuth2RefreshTokenGrantConfig auth = {
    clientId,
    clientSecret,
    refreshToken,
    credentialBearer: oauth2:POST_BODY_BEARER

};

ConnectionConfig config = {auth: enableClient0auth2 ? auth : {token: "Bearer token"}};
final Client baseClient = check new Client(config);

final time:Utc currentUtc = time:utcNow();
string formId = "";

@test:Config {
    groups: ["live_service_test"],
    enable: enableClient0auth2
}
isolated function testGetForm() returns error? {
    CollectionResponseFormDefinitionBaseForwardPaging response = check baseClient->/.get();
    test:assertTrue(response?.results.length() > 0);
}

@test:Config {
    groups: ["live_service_test"],
    enable: enableClient0auth2
}
function testCreateForm() returns error? {
    FormDefinitionBase response = check baseClient->/.post(
        {
            formType: "hubspot",
            name: "form" + currentUtc.toString(),
            createdAt: "2024-12-23T07:13:28.102Z",
            updatedAt: "2024-12-23T07:13:28.102Z",
            archived: false,
            fieldGroups: [
                {
                    groupType: "default_group",
                    richTextType: "text",
                    fields: [
                        {
                            objectTypeId: "0-1",
                            name: "email",
                            label: "Email",
                            required: true,
                            hidden: false,
                            fieldType: "email",
                            validation: {
                                blockedEmailDomains: [],
                                useDefaultBlockList: false
                            }

                        }
                    ]
                }
            ],
            configuration: {
                language: "en",
                createNewContactForNewEmail: true,
                editable: true,
                allowLinkToResetKnownValues: true,
                lifecycleStages: [],
                postSubmitAction: {
                    'type: "thank_you",
                    value: "Thank you for subscribing!"
                },
                prePopulateKnownValues: true,
                cloneable: true,
                notifyContactOwner: true,
                recaptchaEnabled: false,
                archivable: true,
                notifyRecipients: ["example@example.com"]
            },
            displayOptions: {
                renderRawHtml: false,
                cssClass: "hs-form stacked",
                theme: "default_style",
                submitButtonText: "Submit",
                style: {
                    labelTextSize: "13px",
                    legalConsentTextColor: "#33475b",
                    fontFamily: "arial, helvetica, sans-serif",
                    legalConsentTextSize: "14px",
                    backgroundWidth: "100%",
                    helpTextSize: "11px",
                    submitFontColor: "#ffffff",
                    labelTextColor: "#33475b",
                    submitAlignment: "left",
                    submitSize: "12px",
                    helpTextColor: "#7C98B6",
                    submitColor: "#ff7a59"
                }
            },
            legalConsentOptions: {
                'type: "none"
            }
        }
    );

    formId = response?.id;

    test:assertTrue(response?.id !is "");
}

@test:Config {
    dependsOn: [testCreateForm],
    groups: ["live_service_test"],
    enable: enableClient0auth2
}
function testGetFormById() returns error? {
    FormDefinitionBase response = check baseClient->/[formId]();
    test:assertEquals(response?.id, formId);

}

@test:Config {
    dependsOn: [testCreateForm],
    groups: ["live_service_test"],
    enable: enableClient0auth2
}
function testUpdateEntireForm() returns error? {
    FormDefinitionBase response = check baseClient->/[formId].put(
        {
            formType: "hubspot",
            id: formId,
            name: "form" + currentUtc.toString() + "updated",
            createdAt: "2024-12-23T07:13:28.102Z",
            updatedAt: "2024-12-23T07:13:28.102Z",
            archived: true,
            archivedAt: "2024-12-23T07:13:28.102Z",
            fieldGroups: [
                {
                    groupType: "default_group",
                    richTextType: "text",
                    fields: [
                        {
                            objectTypeId: "0-1",
                            name: "email",
                            label: "Email",
                            required: true,
                            hidden: false,
                            fieldType: "email",
                            validation: {
                                blockedEmailDomains: [],
                                useDefaultBlockList: false
                            }

                        }
                    ]
                }
            ],
            configuration: {
                language: "en",
                createNewContactForNewEmail: true,
                editable: true,
                allowLinkToResetKnownValues: true,
                lifecycleStages: [],
                postSubmitAction: {
                    'type: "thank_you",
                    value: "Thank you for subscribing!"
                },
                prePopulateKnownValues: true,
                cloneable: true,
                notifyContactOwner: true,
                recaptchaEnabled: false,
                archivable: true,
                notifyRecipients: ["example@example.com"]
            },
            displayOptions: {
                renderRawHtml: false,
                cssClass: "hs-form stacked",
                theme: "default_style",
                submitButtonText: "Submit",
                style: {
                    labelTextSize: "13px",
                    legalConsentTextColor: "#33475b",
                    fontFamily: "arial, helvetica, sans-serif",
                    legalConsentTextSize: "14px",
                    backgroundWidth: "100%",
                    helpTextSize: "11px",
                    submitFontColor: "#ffffff",
                    labelTextColor: "#33475b",
                    submitAlignment: "left",
                    submitSize: "12px",
                    helpTextColor: "#7C98B6",
                    submitColor: "#ff7a59"
                }
            },
            legalConsentOptions: {
                'type: "none"
            }
        }
    );
    test:assertTrue(response?.id == formId);
    test:assertEquals(response?.archived, true);
}

@test:Config {
    dependsOn: [testCreateForm],
    groups: ["live_service_test"],
    enable: enableClient0auth2
}
function testUpdateForm() returns error? {
    FormDefinitionBase response = check baseClient->/[formId].patch(
        {
            name: "form" + currentUtc.toString() + "updated_form"
        }
    );
    test:assertEquals(response?.id, formId);
}

@test:Config {
    dependsOn: [testCreateForm],
    groups: ["live_service_test"],
    enable: enableClient0auth2
}
function testDeleteForm() returns error? {
    json response = check baseClient->/[formId].delete();
    test:assertEquals(response, ());
}
