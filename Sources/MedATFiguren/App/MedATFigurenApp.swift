#if canImport(SwiftUI)
import SwiftUI

/// App entry point.
///
/// To use in an Xcode iOS project:
/// 1. Create a new Xcode project (iOS App, SwiftUI interface).
/// 2. Add this Swift Package as a dependency (or drag the Sources folder in).
/// 3. Replace the generated `@main` struct body with the one below.
@main
public struct MedATFigurenApp: App {

    @State private var env = AppEnvironment()

    public init() {}

    public var body: some Scene {
        WindowGroup {
            RootView()
                .environment(env)
        }
    }
}

#endif // canImport(SwiftUI)
