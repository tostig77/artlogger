import SwiftUI

struct ContentView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var viewModel = ArtworkViewModel()

    var body: some View {
        NavigationStack {
            TabView {
                ProfileView().tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                
                NavigationStack {
                    LogArtOptionsView(viewModel: viewModel)
                }
                .tabItem {
                    Label("Log Art", systemImage: "plus.circle")
                }

                FriendActivityView()
                    .tabItem {
                        Label("Friends", systemImage: "person.2.fill")
                    }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Logout") {
                        session.signOut()
                    }
                }
            }
        }
    }
}
