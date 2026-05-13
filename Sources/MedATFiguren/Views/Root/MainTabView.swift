#if canImport(SwiftUI)
import SwiftUI

public struct MainTabView: View {

    @Environment(AppEnvironment.self) private var env

    public init() {}

    public var body: some View {
        TabView {
            TrainingContainerView()
                .tabItem { Label("Training", systemImage: "puzzlepiece.fill") }

            DashboardView()
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(.indigo)
    }
}

#endif // canImport(SwiftUI)
