import AppKit
import Foundation
import WidgetKit

@MainActor
final class UsageViewModel: ObservableObject {
    @Published private(set) var snapshot = UsageSnapshotStore.load()
    @Published private(set) var isRefreshing = false
    @Published private(set) var selectedHomePath: String?

    private let service = UsageService()
    private let bookmarkKey = "usageHomeBookmark"

    init() {
        selectedHomePath = restoreHomeURL()?.path
    }

    func chooseHomeFolder() {
        let panel = NSOpenPanel()
        panel.title = "Allow access to your home folder"
        panel.message = "Cost Widget reads local AI CLI usage logs (such as .claude and .codex) only from the folder you allow."
        panel.prompt = "Allow access"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser

        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let bookmark = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(bookmark, forKey: bookmarkKey)
            selectedHomePath = url.path
            refresh()
        } catch {
            snapshot = failureSnapshot("Could not save folder access: \(error.localizedDescription)")
        }
    }

    func refresh() {
        guard let homeURL = restoreHomeURL() else {
            snapshot = .notConfigured
            return
        }
        isRefreshing = true
        Task {
            defer { isRefreshing = false }
            do {
                let refreshed = try await service.load(homeURL: homeURL)
                snapshot = refreshed
                UsageSnapshotStore.save(refreshed)
                WidgetCenter.shared.reloadAllTimelines()
            } catch {
                let failed = failureSnapshot(error.localizedDescription)
                snapshot = failed
                UsageSnapshotStore.save(failed)
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    private func restoreHomeURL() -> URL? {
        guard let bookmark = UserDefaults.standard.data(forKey: bookmarkKey) else { return nil }
        var stale = false
        guard let url = try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &stale) else {
            return nil
        }
        return url
    }

    private func failureSnapshot(_ message: String) -> UsageSnapshot {
        UsageSnapshot(
            updatedAt: .now,
            today: snapshot.today,
            month: snapshot.month,
            agents: snapshot.agents,
            claudeBlock: snapshot.claudeBlock,
            statusMessage: message
        )
    }
}

actor UsageService {
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()

    func load(homeURL: URL) throws -> UsageSnapshot {
        guard homeURL.startAccessingSecurityScopedResource() else {
            throw UsageError.accessDenied
        }
        defer { homeURL.stopAccessingSecurityScopedResource() }

        let calendar = Calendar.current
        let now = Date.now
        let today = dateFormatter.string(from: now)
        let monthStart = dateFormatter.string(from: calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now)

        let daily = try run(arguments: ["daily", "--json", "--by-agent", "--since", today], homeURL: homeURL)
        let monthly = try run(arguments: ["monthly", "--json", "--by-agent", "--since", monthStart], homeURL: homeURL)
        let blockResult = try? run(arguments: ["claude", "blocks", "--json", "--active"], homeURL: homeURL)

        let dayReport = try JSONDecoder().decode(CCUsageReport.self, from: daily)
        let monthReport = try JSONDecoder().decode(CCUsageReport.self, from: monthly)
        let agents = (monthReport.monthly?.first?.agents ?? dayReport.daily?.first?.agents ?? [])
            .map { AgentBreakdown(agent: $0.agent, metric: UsageMetric(costUSD: $0.totalCost, totalTokens: $0.totalTokens)) }
            .sorted { $0.metric.costUSD > $1.metric.costUSD }
        let block = blockResult.flatMap { try? JSONDecoder().decode(CCUsageBlocks.self, from: $0) }?
            .blocks.first(where: \.isActive)
            .map { ClaudeBlock(costUSD: $0.costUSD, totalTokens: $0.totalTokens, remainingMinutes: $0.projection?.remainingMinutes, range: $0.timeRange) }

        return UsageSnapshot(
            updatedAt: now,
            today: UsageMetric(costUSD: dayReport.totals.totalCost, totalTokens: dayReport.totals.totalTokens),
            month: UsageMetric(costUSD: monthReport.totals.totalCost, totalTokens: monthReport.totals.totalTokens),
            agents: agents,
            claudeBlock: block,
            statusMessage: agents.isEmpty ? "No supported local AI CLI usage logs were found in the selected folder." : nil
        )
    }

    private func run(arguments: [String], homeURL: URL) throws -> Data {
        guard let executableURL = Bundle.main.url(forResource: "ccusage", withExtension: nil) else {
            throw UsageError.toolMissing
        }
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
        process.currentDirectoryURL = homeURL
        var environment = ProcessInfo.processInfo.environment
        environment["HOME"] = homeURL.path
        environment["CCUSAGE_TIMEZONE"] = TimeZone.current.identifier
        environment["NO_COLOR"] = "1"
        process.environment = environment

        let output = Pipe()
        let error = Pipe()
        process.standardOutput = output
        process.standardError = error
        try process.run()
        process.waitUntilExit()
        let errorData = error.fileHandleForReading.readDataToEndOfFile()
        guard process.terminationStatus == 0 else {
            let detail = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "unknown error"
            throw UsageError.commandFailed(detail)
        }
        return output.fileHandleForReading.readDataToEndOfFile()
    }
}

private struct CCUsageReport: Decodable {
    let daily: [CCUsagePeriod]?
    let monthly: [CCUsagePeriod]?
    let totals: CCUsageTotals
}

private struct CCUsagePeriod: Decodable {
    let agents: [CCUsageAgent]?
}

private struct CCUsageAgent: Decodable {
    let agent: String
    let totalCost: Double
    let totalTokens: Int
}

private struct CCUsageTotals: Decodable {
    let totalCost: Double
    let totalTokens: Int
}

private struct CCUsageBlocks: Decodable {
    let blocks: [CCUsageBlock]
}

private struct CCUsageBlock: Decodable {
    let isActive: Bool
    let costUSD: Double
    let totalTokens: Int
    let timeRange: String?
    let projection: CCUsageProjection?
}

private struct CCUsageProjection: Decodable {
    let remainingMinutes: Int?
}

private enum UsageError: LocalizedError {
    case accessDenied
    case toolMissing
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .accessDenied: "Folder access was not granted. Choose your home folder again."
        case .toolMissing: "The bundled ccusage executable is missing. Download a new Cost Widget build."
        case let .commandFailed(detail): "ccusage failed: \(detail)"
        }
    }
}