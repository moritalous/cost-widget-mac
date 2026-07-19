import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Cost Widget", systemImage: "chart.bar.xaxis")
                .font(.title2.weight(.semibold))

            Text("The widget is ready to add from Notification Center or the desktop.")
                .foregroundStyle(.secondary)

            Text("This preview build uses sample data. Claude Code log integration will be added next.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(minWidth: 360, minHeight: 150)
    }
}

#Preview {
    ContentView()
}
