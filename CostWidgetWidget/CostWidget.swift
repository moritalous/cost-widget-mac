import SwiftUI
import WidgetKit

struct CostEntry: TimelineEntry {
    let date: Date
    let currentBlock: String
    let today: String
    let month: String
}

struct CostTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> CostEntry {
        CostEntry(date: .now, currentBlock: "$1.24", today: "$3.87", month: "$42.16")
    }

    func getSnapshot(in context: Context, completion: @escaping (CostEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CostEntry>) -> Void) {
        let entry = CostEntry(
            date: .now,
            currentBlock: "$1.24",
            today: "$3.87",
            month: "$42.16"
        )
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: entry.date) ?? entry.date.addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct CostWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CostEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemLarge:
            largeView
        default:
            mediumView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Cost", systemImage: "chart.bar.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(entry.currentBlock)
                .font(.title2.weight(.bold))
            Text("current block")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            HStack(spacing: 20) {
                metric("Current block", entry.currentBlock)
                metric("Today", entry.today)
                metric("This month", entry.month)
            }
        }
    }

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            metric("Current 5-hour block", entry.currentBlock)
            metric("Today", entry.today)
            metric("This month", entry.month)
            Spacer(minLength: 0)
            Text("Sample data · integration pending")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var header: some View {
        Label("Token Cost", systemImage: "chart.bar.xaxis")
            .font(.headline)
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
        }
    }
}

struct CostWidget: Widget {
    let kind = "com.moritalous.cost-widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CostTimelineProvider()) { entry in
            CostWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Token Cost")
        .description("Shows Claude Code token usage and costs.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct CostWidgetWidgetBundle: WidgetBundle {
    var body: some Widget {
        CostWidget()
    }
}

#Preview(as: .systemMedium) {
    CostWidget()
} timeline: {
    CostEntry(date: .now, currentBlock: "$1.24", today: "$3.87", month: "$42.16")
}
