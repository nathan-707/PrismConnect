//
//  ChatGPT.swift
//  Prism Connect
//
//  Created by Nathan Eriksen on 8/30/25.
//

import Foundation

// a change to be tracked.
// MARK: - ChatGPT Client
// A minimal, self-contained client for OpenAI's Chat Completions API.
// Uses URLSession + Swift Concurrency, no external dependencies.
// You can move the API key handling to a more secure location later.

enum ChatGPTError: Error, LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case httpStatus(Int, String)
    case decodingError
    case emptyContent

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "OpenAI API key is missing."
        case .invalidURL: return "Invalid OpenAI API URL."
        case .invalidResponse: return "Invalid response from OpenAI."
        case .httpStatus(let code, let body): return "HTTP \(code): \(body)"
        case .decodingError: return "Failed to decode response."
        case .emptyContent: return "No content in the response."
        }
    }
}

final class ChatGPTClient {
    static let shared = ChatGPTClient()

    // IMPORTANT: Replace this with your actual API key, or load from Keychain/Info.plist.
    // For Info.plist, consider reading with: Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String

    //    private var apiKey: String? = "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"

    //
    private var apiKey: String? = ""

    // You can change the model as needed (e.g., "gpt-4o-mini", "gpt-4o", "gpt-4.1-mini").
    //    var model: String = "gpt-4o-mini"
    var model: String = "gpt-4.1-mini"

    // API base URL for chat completions
    private let endpoint = URL(
        string: "https://api.openai.com/v1/chat/completions"
    )

    private init() {}

    // General-purpose function to send a single-user message and return assistant text.
    func sendMessage(_ message: String) async throws -> String {
        guard let apiKey, !apiKey.isEmpty else {
            throw ChatGPTError.missingAPIKey
        }
        guard let endpoint else { throw ChatGPTError.invalidURL }

        let requestBody = ChatCompletionsRequest(
            model: model,
            messages: [
                .init(role: "user", content: message)
            ],
            temperature: 0.8
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(
            "Bearer \(apiKey)",
            forHTTPHeaderField: "Authorization"
        )
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ChatGPTError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw ChatGPTError.httpStatus(http.statusCode, body)
        }

        let decoded = try JSONDecoder().decode(
            ChatCompletionsResponse.self,
            from: data
        )

        // Extract assistant content (handles both "content" and tool/array shapes defensively).
        if let firstChoice = decoded.choices.first {
            if let content = firstChoice.message.content,
                content.isEmpty == false
            {
                return content
            } else if let contentArray = firstChoice.message.multiContent,
                !contentArray.isEmpty
            {
                // Join any text parts if present
                let textJoined = contentArray.compactMap { $0.text }.joined(
                    separator: " "
                )
                if !textJoined.isEmpty { return textJoined }
            }
        }

        throw ChatGPTError.emptyContent
    }
}

// MARK: - Models

// Request models
struct ChatCompletionsRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double?
    // You can add other parameters (max_tokens, top_p, etc.) as needed.
}

struct ChatMessage: Codable {
    let role: String  // "system" | "user" | "assistant" | "tool"
    let content: String?

    // Some responses may use a content array for multimodal; request can be simple string content.
    // Keeping it simple on the request side for now.
    init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

// Response models
struct ChatCompletionsResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage?
}

struct Choice: Codable {
    let index: Int
    let message: AssistantMessage
    let finish_reason: String?
}

struct AssistantMessage: Codable {
    let role: String
    let content: String?

    // Some models may return an array of content parts (for multimodal/tool outputs).
    // Implement a fallback to decode either a string or an array of parts.
    let multiContent: [ContentPart]?

    enum CodingKeys: String, CodingKey {
        case role
        case content
    }

    init(role: String, content: String?, multiContent: [ContentPart]?) {
        self.role = role
        self.content = content
        self.multiContent = multiContent
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        role = try container.decode(String.self, forKey: .role)

        // Try decoding as a simple string first
        if let stringContent = try? container.decode(
            String.self,
            forKey: .content
        ) {
            content = stringContent
            multiContent = nil
            return
        }

        // Else try decoding as an array of content parts
        if let arrayContent = try? container.decode(
            [ContentPart].self,
            forKey: .content
        ) {
            content = nil
            multiContent = arrayContent
            return
        }

        // Fallback
        content = nil
        multiContent = nil
    }
}

struct ContentPart: Codable {
    let type: String?
    let text: String?
}

struct Usage: Codable {
    let prompt_tokens: Int?
    let completion_tokens: Int?
    let total_tokens: Int?
}

// MARK: - Example usage
// You can call this from anywhere, e.g. inside a Task in a SwiftUI View:
// Task {
//     do {
//         let result = try await ChatGPTClient.shared.sendHi()
//         // Assign to your variable:
//         self.response = result
//     } catch {
//         print("ChatGPT error: \(error)")
//     }
// }
