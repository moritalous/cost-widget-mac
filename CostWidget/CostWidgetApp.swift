import SwiftUI

@main
struct CostWidgetApp: App {
    @StateObject private var model = UsageViewModel()

    var body: some Scene {
        MenuBarExtra("Cost Widget", systemImage: "chart.bar.xaxis") {
            ContentView(model: model)
        }
        .menuBarExtraStyle(.window)
    }
}
