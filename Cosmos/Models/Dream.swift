import Foundation
import FirebaseFirestore

struct Dream: Codable, Identifiable {
    @DocumentID var id: String?
    var authorId: String
    var dreamText: String
    var encouragements: [String] = []
    var createdAt: Date = Date()
}
