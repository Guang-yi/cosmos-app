import Foundation
import FirebaseFirestore

struct Referral: Codable, Identifiable {
    @DocumentID var id: String?
    var referrerId: String
    var referredUserId: String
    var createdAt: Date = Date()
}
