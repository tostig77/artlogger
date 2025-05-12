import SwiftUI
import Firebase

struct AppEntryView: View {
    @StateObject var session = SessionStore()
    @State private var needsProfileSetup = false
    
    var body: some View {
        NavigationView {
            Group {
                if session.user != nil {
                    if needsProfileSetup {
                        ProfileSetupView(isNewUser: true) { success in
                            // When profile setup is complete, update the state
                            if success {
                                needsProfileSetup = false
                            }
                        }
                        .environmentObject(session)
                    } else {
                        ContentView().environmentObject(session)
                    }
                } else {
                    LoginView(onSignupComplete: { requiresSetup in
                        // This closure will be called after successful signup
                        needsProfileSetup = requiresSetup
                    })
                    .environmentObject(session)
                }
            }
        }
    }
}
