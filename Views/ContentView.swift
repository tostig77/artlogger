import SwiftUI

struct ContentView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var viewModel = ArtworkViewModel()

    var body: some View {
        TabView {
            

            ProfileView().tabItem {
                                    Label("Profile", systemImage: "person.fill")
                                }
            
            LogNewArtworkView(viewModel: viewModel)
                .tabItem {
                    Label("Log", systemImage: "plus.circle")
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
