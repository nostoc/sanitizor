import ballerina/io;
import ballerinax/openai.chat;

configurable string openaiToken = ?;

public function main() returns error? {
    chat:Client chatClient = check new({
        auth: {token: openaiToken}
    });

    chat:ChatCompletionRequestMessage[] messages = [
        {
            role: "user",
            content: "Hi, I need help with my recent order. It hasn't arrived yet and I'm getting worried."
        }
    ];

    chat:CreateChatCompletionRequest request1 = {
        model: "gpt-3.5-turbo",
        messages: messages
    };

    chat:CreateChatCompletionResponse response1 = check chatClient->/chat/completions.post(request1);
    string assistantResponse1 = response1.choices[0].message.content ?: "";
    io:println("Customer: Hi, I need help with my recent order. It hasn't arrived yet and I'm getting worried.");
    io:println("Assistant: " + assistantResponse1);

    messages.push({
        role: "assistant",
        content: assistantResponse1
    });

    messages.push({
        role: "user",
        content: "My order number is ORD-12345 and I placed it 5 days ago. The tracking shows it's stuck in transit."
    });

    chat:CreateChatCompletionRequest request2 = {
        model: "gpt-3.5-turbo",
        messages: messages
    };

    chat:CreateChatCompletionResponse response2 = check chatClient->/chat/completions.post(request2);
    string assistantResponse2 = response2.choices[0].message.content ?: "";
    io:println("\nCustomer: My order number is ORD-12345 and I placed it 5 days ago. The tracking shows it's stuck in transit.");
    io:println("Assistant: " + assistantResponse2);

    messages.push({
        role: "assistant",
        content: assistantResponse2
    });

    messages.push({
        role: "user",
        content: "Thank you for checking. Should I be concerned about the delay? When can I expect to receive my order?"
    });

    chat:CreateChatCompletionRequest request3 = {
        model: "gpt-3.5-turbo",
        messages: messages
    };

    chat:CreateChatCompletionResponse response3 = check chatClient->/chat/completions.post(request3);
    string assistantResponse3 = response3.choices[0].message.content ?: "";
    io:println("\nCustomer: Thank you for checking. Should I be concerned about the delay? When can I expect to receive my order?");
    io:println("Assistant: " + assistantResponse3);
}