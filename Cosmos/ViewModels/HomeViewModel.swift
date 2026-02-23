import Foundation

@Observable
class HomeViewModel {
    var user: CosmosUser?
    var todayScore: CosmosScore?
    var hasCheckedInToday = false
    var todayQuote: Quote?
    var isLoading = true

    private var firestore: FirestoreService

    init(firestore: FirestoreService) {
        self.firestore = firestore
    }

    func loadToday(userId: String) async {
        isLoading = true
        user = try? await firestore.getUser(id: userId)
        let scores = try? await firestore.getCosmosScores(userId: userId, limit: 1)
        if let latest = scores?.first, Calendar.current.isDateInToday(latest.date) {
            todayScore = latest
            hasCheckedInToday = true
        }
        let quotes = try? await firestore.getRandomQuotes(count: 1)
        todayQuote = quotes?.first
        isLoading = false
    }
}
