import Foundation

struct SharedDataService {
    private static let suiteName = "group.com.cosmos.shared"

    static func saveWidgetData(score: Int?, streak: Int) {
        let defaults = UserDefaults(suiteName: suiteName)
        if let score { defaults?.set(score, forKey: "cosmosScore") }
        defaults?.set(streak, forKey: "currentStreak")
        defaults?.set(Date().timeIntervalSince1970, forKey: "lastUpdated")
    }

    static func getWidgetData() -> (score: Int?, streak: Int, lastUpdated: Date?) {
        let defaults = UserDefaults(suiteName: suiteName)
        let score = defaults?.object(forKey: "cosmosScore") as? Int
        let streak = defaults?.integer(forKey: "currentStreak") ?? 0
        let timestamp = defaults?.double(forKey: "lastUpdated")
        let lastUpdated = timestamp.map { Date(timeIntervalSince1970: $0) }
        return (score, streak, lastUpdated)
    }
}
