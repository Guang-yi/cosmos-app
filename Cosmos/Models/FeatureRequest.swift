import Foundation
import FirebaseFirestore

struct FeatureRequest: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var authorId: String
    var status: Status = .suggested
    var voteCount: Int = 0
    var createdAt: Date = Date()

    enum Status: String, Codable {
        case suggested, underReview, inProgress, shipped
    }
}

struct FeatureVote: Codable, Identifiable {
    @DocumentID var id: String?
    var featureId: String
    var userId: String
    var createdAt: Date = Date()
}
