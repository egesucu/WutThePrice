import SwiftUI
import WidgetKit

@main
struct MyApp: App {
    @Environment(\.scenePhase) private var phase
    var body: some Scene {
        WindowGroup { ContentView() }
            .onChange(of: phase) { _, phase in
                if phase == .background { WidgetCenter.shared.reloadTimelines(ofKind: CurrencyStore.widgetKind) }
            }
    }
}
