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

import ballerina/http;
import ballerina/log;

listener http:Listener httpListener = new (9090);

http:Service mockService = service object {
    resource function get marketing/v3/forms() returns CollectionResponseFormDefinitionBaseForwardPaging {
        return {
            results: [
                {
                    id: "b6336282-50ec-465e-894e-e368146fa25f",
                    formType: "hubspot",
                    name: "Contact Form",
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
            ]

        };
    }
    resource function get marketing/v3/forms/[string mockFormId]() returns FormDefinitionBase {
        return {
            id: mockFormId,
            formType: "hubspot",
            name: "Contact Form",
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
    }
};

function init() returns error? {
    log:printInfo("Initializing mock service");
    check httpListener.attach(mockService, "/");
    check httpListener.'start();
}
