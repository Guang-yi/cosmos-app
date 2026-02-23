import Foundation
import FirebaseFirestore

@Observable
class FirestoreService {
    private let db = Firestore.firestore()

    // MARK: - User
    func saveUser(_ user: CosmosUser) async throws {
        guard let id = user.id else { return }
        try db.collection("users").document(id).setData(from: user)
    }

    func getUser(id: String) async throws -> CosmosUser? {
        try await db.collection("users").document(id).getDocument(as: CosmosUser.self)
    }

    // MARK: - Check-Ins
    func saveCheckIn(_ checkIn: CheckIn) async throws {
        try db.collection("checkIns").addDocument(from: checkIn)
    }

    func getCheckIns(userId: String, limit: Int = 30) async throws -> [CheckIn] {
        let snapshot = try await db.collection("checkIns")
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .limit(to: limit)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: CheckIn.self) }
    }

    // MARK: - Cosmos Scores
    func saveCosmosScore(_ score: CosmosScore) async throws {
        try db.collection("cosmosScores").addDocument(from: score)
    }

    func getCosmosScores(userId: String, limit: Int = 30) async throws -> [CosmosScore] {
        let snapshot = try await db.collection("cosmosScores")
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .limit(to: limit)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: CosmosScore.self) }
    }

    // MARK: - Quotes
    func getRandomQuotes(count: Int = 5) async throws -> [Quote] {
        let snapshot = try await db.collection("quotes")
            .limit(to: count)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Quote.self) }
    }

    // MARK: - Feature Requests
    func getFeatureRequests() async throws -> [FeatureRequest] {
        let snapshot = try await db.collection("featureRequests")
            .order(by: "voteCount", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: FeatureRequest.self) }
    }

    func submitFeatureRequest(_ request: FeatureRequest) async throws {
        try db.collection("featureRequests").addDocument(from: request)
    }

    func upvoteFeature(featureId: String, userId: String) async throws {
        let vote = FeatureVote(featureId: featureId, userId: userId)
        try db.collection("featureVotes").addDocument(from: vote)
        try await db.collection("featureRequests").document(featureId)
            .updateData(["voteCount": FieldValue.increment(Int64(1))])
    }

    // MARK: - Referrals
    func createReferral(referrerId: String, referredUserId: String) async throws {
        let referral = Referral(referrerId: referrerId, referredUserId: referredUserId)
        try db.collection("referrals").addDocument(from: referral)
    }

    func getReferralCount(userId: String) async throws -> Int {
        let snapshot = try await db.collection("referrals")
            .whereField("referrerId", isEqualTo: userId)
            .getDocuments()
        return snapshot.count
    }
}
