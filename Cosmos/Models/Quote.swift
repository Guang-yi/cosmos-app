import Foundation
import FirebaseFirestore

struct Quote: Codable, Identifiable {
    @DocumentID var id: String?
    var personName: String
    var quote: String
    var category: String
    var source: String?
    var personBio: String?
}
