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

    static let notConfigured = UsageSnapshot(updatedAt: .now, today: .empty, month: .empty, agents: [], claudeBlock: nil, statusMessage: "Launch Cost Widget from the menu bar to read local AI CLI usage logs.")
}

enum UsageSnapshotStore {
    private static let widgetBundleID = "com.moritalous.cost-widget.widget"

    private static var snapshotURL: URL {
        let fileManager = FileManager.default
        if Bundle.main.bundleURL.pathExtension == "appex" {
            let directory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("CostWidget", isDirectory: true)
            return directory.appendingPathComponent("usage-snapshot.json")
        }
        let home = fileManager.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Library/Containers/\(widgetBundleID)/Data/Library/Application Support/CostWidget/usage-snapshot.json")
    }

    static func load() -> UsageSnapshot {
        guard let data = try? Data(contentsOf: snapshotURL),
              let snapshot = try? JSONDecoder().decode(UsageSnapshot.self, from: data) else { return .notConfigured }
        return snapshot
    }

    static func save(_ snapshot: UsageSnapshot) {
        let url = snapshotURL
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: url, options: .atomic)
    }
}