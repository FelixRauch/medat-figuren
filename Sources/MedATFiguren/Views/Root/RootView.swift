#if canImport(SwiftUI)
import SwiftUI

/// Top-level router. Decides whether to show onboarding or the main tab interface.
public struct RootView: View {

    @Environment(AppEnvironment.self) private var env

    public init() {}

    public var body: some View {
        MainTabView()
            .onAppear { env.beginSession() }
    }
}

#endif // canImport(SwiftUI)
