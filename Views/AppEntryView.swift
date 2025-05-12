import SwiftUI

struct AppEntryView: View {
    @StateObject var session = SessionStore()

    var body: some View {
        NavigationView {
            Group {
                if session.user != nil {
                    ContentView().environmentObject(session)
                } else {
                    LoginView().environmentObject(session)
                }
            }
        }
    }
}
