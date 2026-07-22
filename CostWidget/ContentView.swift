import SwiftUI

struct ContentView: View {
    @StateObject private var model = UsageViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Token Cost", systemImage: "chart.bar.xaxis")
                .font(.title2.weight(.semibold))

            Text("All detected local sources are aggregated by ccusage. Claude Code's 5-hour block is shown separately because it is not an all-source metric.")
                .foregroundStyle(.secondary)

            HStack(spacing: 28) {
                metric("Today", model.snapshot.today)
                metric("This month", model.snapshot.month)
                if let block = model.snapshot.claudeBlock {
                    metric("Claude 5-hour block", UsageMetric(costUSD: block.costUSD, totalTokens: block.totalTokens))
                }
            }

            if !model.snapshot.agents.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This month by source")
                        .font(.headline)
                    ForEach(model.snapshot.agents.prefix(5)) { agent in
                        HStack {
                            Text(agent.agent.capitalized)
                            Spacer()
                            Text(agent.metric.costUSD, format: .currency(code: "USD"))
                                .monospacedDigit()
                        }
                        .font(.callout)
                    }
                }
            }

            if let message = model.snapshot.statusMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button("Choose home folder…") { model.chooseHomeFolder() }
                Button(model.isRefreshing ? "Refreshing…" : "Refresh") { model.refresh() }
                    .disabled(model.isRefreshing)
                Spacer()
                Text("Updated \(model.snapshot.updatedAt, style: .time)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(minWidth: 520, minHeight: 310)
    }

    private func metric(_ title: String, _ metric: UsageMetric) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(metric.costUSD, format: .currency(code: "USD"))
                .font(.title3.weight(.semibold))
            Text("\(metric.totalTokens.formatted()) tokens")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }
}

#Preview { ContentView() }