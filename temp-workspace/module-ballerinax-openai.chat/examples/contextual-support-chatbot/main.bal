import ballerina/io;
import ballerinax/openai.chat;

configurable string openaiApiKey = ?;

public function main() returns error? {
    chat:Client openaiClient = check new ({
        auth: {
            token: openaiApiKey
        }
    });

    chat:ChatCompletionRequestMessage[] conversationHistory = [];

    chat:ChatCompletionRequestSystemMessage systemMessage = {
        role: "system",
        content: "You are a helpful customer support assistant with expertise in technology products. Provide clear, friendly, and accurate responses to customer inquiries."
    };
    conversationHistory.push(systemMessage);

    string initialQuery = "I'm having trouble connecting my smart TV to WiFi. It keeps saying 'connection failed' when I try to connect.";
    chat:ChatCompletionRequestUserMessage userMessage1 = {
        role: "user",
        content: initialQuery
    };
    conversationHistory.push(userMessage1);

    chat:CreateChatCompletionRequest request1 = {
        model: "gpt-3.5-turbo",
        messages: conversationHistory,
        temperature: 0.7,
        max_tokens: 200
    };

    chat:CreateChatCompletionResponse response1 = check openaiClient->/chat/completions.post(request1);
    string assistantResponse1 = response1.choices[0].message.content ?: "";
    
    io:println("=== Initial Customer Query ===");
    io:println("Customer: " + initialQuery);
    io:println("Assistant: " + assistantResponse1);
    io:println();

    chat:ChatCompletionRequestAssistantMessage assistantMessage1 = {
        role: "assistant",
        content: assistantResponse1
    };
    conversationHistory.push(assistantMessage1);

    string followUpQuery = "I tried those steps but it's still not working. My TV model is Samsung QN55Q60A and my router is about 15 feet away. Could the distance be an issue?";
    chat:ChatCompletionRequestUserMessage userMessage2 = {
        role: "user",
        content: followUpQuery
    };
    conversationHistory.push(userMessage2);

    chat:CreateChatCompletionRequest request2 = {
        model: "gpt-3.5-turbo",
        messages: conversationHistory,
        temperature: 0.6,
        max_tokens: 250
    };

    chat:CreateChatCompletionResponse response2 = check openaiClient->/chat/completions.post(request2);
    string assistantResponse2 = response2.choices[0].message.content ?: "";

    io:println("=== Follow-up with Context ===");
    io:println("Customer: " + followUpQuery);
    io:println("Assistant: " + assistantResponse2);
    io:println();

    chat:ChatCompletionRequestAssistantMessage assistantMessage2 = {
        role: "assistant",
        content: assistantResponse2
    };
    conversationHistory.push(assistantMessage2);

    string technicalQuery = "You mentioned WiFi frequency bands. Can you explain what 2.4GHz and 5GHz mean and how they affect my connection? I'm not very technical.";
    chat:ChatCompletionRequestUserMessage userMessage3 = {
        role: "user",
        content: technicalQuery
    };
    conversationHistory.push(userMessage3);

    chat:ChatCompletionRequestSystemMessage technicalSystemMessage = {
        role: "system",
        content: "The customer is asking about technical concepts. Break down complex technical information into simple, easy-to-understand terms. Use analogies and avoid jargon. Build upon the previous conversation context about their WiFi connection issue."
    };

    chat:ChatCompletionRequestMessage[] technicalConversation = [technicalSystemMessage];
    foreach var msg in conversationHistory {
        if msg.role != "system" {
            technicalConversation.push(msg);
        }
    }

    chat:CreateChatCompletionRequest request3 = {
        model: "gpt-3.5-turbo",
        messages: technicalConversation,
        temperature: 0.5,
        max_tokens: 300
    };

    chat:CreateChatCompletionResponse response3 = check openaiClient->/chat/completions.post(request3);
    string assistantResponse3 = response3.choices[0].message.content ?: "";

    io:println("=== Technical Explanation Request ===");
    io:println("Customer: " + technicalQuery);
    io:println("Assistant: " + assistantResponse3);
    io:println();

    io:println("=== Conversation Summary ===");
    io:println("Total requests made: 3");
    io:println("Conversation flow: Initial support -> Contextual follow-up -> Technical explanation");
    io:println("Each response built upon previous context to provide personalized assistance");
}