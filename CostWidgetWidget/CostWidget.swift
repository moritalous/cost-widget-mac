import SwiftUI
import WidgetKit

struct CostEntry: TimelineEntry {
    let date: Date
    let snapshot: UsageSnapshot
}

struct CostTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> CostEntry {
        CostEntry(date: .now, snapshot: UsageSnapshot(updatedAt: .now, today: UsageMetric(costUSD: 3.87, totalTokens: 120_000), month: UsageMetric(costUSD: 42.16, totalTokens: 1_800_000), agents: [AgentBreakdown(agent: "claude", metric: UsageMetric(costUSD: 30, totalTokens: 1_100_000)), AgentBreakdown(agent: "codex", metric: UsageMetric(costUSD: 12.16, totalTokens: 700_000))], claudeBlock: ClaudeBlock(costUSD: 1.24, totalTokens: 42_000, remainingMinutes: 160, range: "10:00–15:00"), statusMessage: nil))
    }

    func getSnapshot(in context: Context, completion: @escaping (CostEntry) -> Void) {
        completion(CostEntry(date: .now, snapshot: UsageSnapshotStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CostEntry>) -> Void) {
        let entry = CostEntry(date: .now, snapshot: UsageSnapshotStore.load())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: entry.date) ?? entry.date.addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct CostWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CostEntry

    var body: some View {
        switch family {
        case .systemSmall: smallView
        case .systemLarge: largeView
        default: mediumView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Token Cost", systemImage: "chart.bar.fill").font(.caption).foregroundStyle(.secondary)
            Text(entry.snapshot.today.costUSD, format: .currency(code: "USD")).font(.title2.weight(.bold))
            Text("today · all sources").font(.caption2).foregroundStyle(.secondary)
            if let message = entry.snapshot.statusMessage { Text(message).font(.caption2).lineLimit(3).foregroundStyle(.secondary) }
        }
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            HStack(spacing: 20) {
                metric("Today", entry.snapshot.today)
                metric("This month", entry.snapshot.month)
                if let block = entry.snapshot.claudeBlock { metric("Claude 5h", UsageMetric(costUSD: block.costUSD, totalTokens: block.totalTokens)) }
            }
            footer
        }
    }

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            metric("Today · all sources", entry.snapshot.today)
            metric("This month · all sources", entry.snapshot.month)
            if let block = entry.snapshot.claudeBlock { metric("Claude Code 5-hour block", UsageMetric(costUSD: block.costUSD, totalTokens: block.totalTokens)) }
            if !entry.snapshot.agents.isEmpty {
                Divider()
                ForEach(entry.snapshot.agents.prefix(3)) { agent in
                    HStack { Text(agent.agent.capitalized); Spacer(); Text(agent.metric.costUSD, format: .currency(code: "USD")) }.font(.caption)
                }
            }
            Spacer(minLength: 0)
            footer
        }
    }

    private var header: some View { Label("Token Cost", systemImage: "chart.bar.xaxis").font(.headline) }

    private var footer: some View {
        Group {
            if let message = entry.snapshot.statusMessage { Text(message) } else { Text("Updated \(entry.snapshot.updatedAt, style: .time)") }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .lineLimit(2)
    }

    private func metric(_ title: String, _ value: UsageMetric) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value.costUSD, format: .currency(code: "USD")).font(.title3.weight(.semibold))
            Text("\(value.totalTokens.formatted()) tokens").font(.caption2).foregroundStyle(.secondary)
        }
    }
}

struct CostWidget: Widget {
    let kind = "com.moritalous.cost-widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CostTimelineProvider()) { entry in
            CostWidgetView(entry: entry).containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Token Cost")
        .description("Shows local AI CLI usage and costs across supported sources.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct CostWidgetWidgetBundle: WidgetBundle { var body: some Widget { CostWidget() } }

#Preview(as: .systemMedium) { CostWidget() } timeline: { CostTimelineProvider().placeholder(in: .init()) }