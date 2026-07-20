import Foundation

struct UsageMetric: Codable, Sendable {
    let costUSD: Double
    let totalTokens: Int

    static let empty = UsageMetric(costUSD: 0, totalTokens: 0)
}

struct AgentBreakdown: Codable, Identifiable, Sendable {
    let agent: String
    let metric: UsageMetric

    var id: String { agent }
}

struct ClaudeBlock: Codable, Sendable {
    let costUSD: Double
    let totalTokens: Int
    let remainingMinutes: Int?
    let range: String?
}

struct UsageSnapshot: Codable, Sendable {
    let updatedAt: Date
    let today: UsageMetric
    let month: UsageMetric
    let agents: [AgentBreakdown]
    let claudeBlock: ClaudeBlock?
    let statusMessage: String?

    static let notConfigured = UsageSnapshot(
        updatedAt: .now,
        today: .empty,
        month: .empty,
        agents: [],
        claudeBlock: nil,
        statusMessage: "Open Cost Widget and allow access to your home folder to read local AI CLI usage logs."
    )
}

enum UsageSnapshotStore {
    static let appGroupID = "group.com.moritalous.cost-widget"
    private static let snapshotKey = "usageSnapshot"

    static func load() -> UsageSnapshot {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(UsageSnapshot.self, from: data) else {
            return .notConfigured
        }
        return snapshot
    }

    static func save(_ snapshot: UsageSnapshot) {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = try? JSONEncoder().encode(snapshot) else {
            return
        }
        defaults.set(data, forKey: snapshotKey)
    }
}