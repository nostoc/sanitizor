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

import ballerina/io;
import ballerina/oauth2;
import ballerinax/hubspot.marketing.forms;

configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string refreshToken = ?;

forms:OAuth2RefreshTokenGrantConfig auth = {
    clientId,
    clientSecret,
    refreshToken,
    credentialBearer: oauth2:POST_BODY_BEARER 
};
final forms:Client formsClient = check new ({auth});
public function main() returns error? {
    forms:FormDefinitionCreateRequestBase inputFormDefinition = {
        formType: "hubspot",
        name: "Contact Us Form New",
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
    };
    forms:FormDefinitionBase response = check formsClient->/.post(
        inputFormDefinition
    );
    string formId = response?.id;
    io:println("Form is created  with ID:  " + formId);
    forms:FormDefinitionBase updateResponse = check formsClient->/[formId].patch(
        {
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
                },
                {
                    groupType: "default_group",
                    richTextType: "text",
                    fields: [
                        {
                            objectTypeId: "0-1",
                            name: "firstname",
                            label: "First name",
                            required: true,
                            hidden: false,
                            fieldType: "single_line_text"
                        },
                        {
                            objectTypeId: "0-1",
                            name: "lastname",
                            label: "Last name",
                            required: true,
                            hidden: false,
                            fieldType: "single_line_text"
                        }
                    ]
                },
                {
                    groupType: "default_group",
                    richTextType: "text",
                    fields: [
                        {
                            objectTypeId: "0-1",
                            name: "phone",
                            label: "Phone Number",
                            required: false,
                            hidden: false,
                            fieldType: "phone",
                            useCountryCodeSelect: true,
                            validation: {
                                minAllowedDigits: 10,
                                maxAllowedDigits: 10
                            }
                        }
                    ]
                },
                {
                    groupType: "default_group",
                    richTextType: "text",
                    fields: [
                        {
                            objectTypeId: "0-1",
                            name: "message",
                            label: "Message",
                            required: true,
                            hidden: false,
                            fieldType: "multi_line_text"
                        }
                    ]
                }
            ]
        }
    );
    io:println("Form is updated at" + updateResponse?.updatedAt);
    forms:FormDefinitionBase getResponse = check formsClient->/[formId]();
    io:println("Form is created at" + getResponse?.createdAt);
    json deleteResponse = check formsClient->/[formId].delete();
    io:println(formId+ "Form is deleted at" + deleteResponse.toString());
};
