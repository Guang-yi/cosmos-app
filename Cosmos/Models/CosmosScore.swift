import Foundation
import FirebaseFirestore

struct CosmosScore: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var date: Date
    var pathScore: Int  // 0-100, percentage of objectives completed
    var total: Int      // Same as pathScore for MVP
    var objectivesSet: Int
    var objectivesCompleted: Int
    var createdAt: Date = Date()

    /// Compute Cosmos Score from objective completion (Path only for MVP)
    static func compute(objectivesSet: Int, objectivesCompleted: Int) -> CosmosScore {
        let pathScore: Int
        if objectivesSet > 0 {
            pathScore = Int((Double(objectivesCompleted) / Double(objectivesSet)) * 100.0)
        } else {
            pathScore = 0
        }

        return CosmosScore(
            userId: "",
            date: Date(),
            pathScore: pathScore,
            total: pathScore,
            objectivesSet: objectivesSet,
            objectivesCompleted: objectivesCompleted
        )
    }
}
