import Foundation
import FirebaseFirestore

struct CheckIn: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var date: Date
    var objectives: [Objective]
    var journalPrompt: String
    var journalResponse: String
    var createdAt: Date = Date()

    struct Objective: Codable {
        var text: String
        var completed: Bool
    }
}
