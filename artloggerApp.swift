import SwiftUI
import Firebase

@main
struct ArtLoggerApp: App {
    @StateObject private var session = SessionStore() // Create the SessionStore object

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
            WindowGroup {
                AppEntryView()
                    .environmentObject(session) // Inject it into the environment here
            }
    }
}
