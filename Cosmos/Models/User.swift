import Foundation
import FirebaseFirestore

struct CosmosUser: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var domain: String
    var dreamGoal: String
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var subscriptionTier: SubscriptionTier = .free
    var referralCode: String = UUID().uuidString.prefix(8).lowercased().description
    var createdAt: Date = Date()

    enum SubscriptionTier: String, Codable {
        case free, premium
    }
}
