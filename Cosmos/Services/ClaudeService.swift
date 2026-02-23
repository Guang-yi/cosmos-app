import Foundation
import FirebaseFunctions

@Observable
class ClaudeService {
    private let functions = Functions.functions()

    func chat(messages: [[String: String]], systemPrompt: String? = nil) async throws -> String {
        var data: [String: Any] = ["messages": messages]
        if let systemPrompt { data["systemPrompt"] = systemPrompt }

        let result = try await functions.httpsCallable("chatWithCoach").call(data)
        guard let response = result.data as? [String: Any],
              let content = response["content"] as? String else {
            throw ClaudeError.invalidResponse
        }
        return content
    }

    enum ClaudeError: Error {
        case invalidResponse
    }
}
