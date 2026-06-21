import SwiftUI

@main
struct KindleShareApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 860, minHeight: 560)
        }
        .windowToolbarStyle(.unified)
    }
}
