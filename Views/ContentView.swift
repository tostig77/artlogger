import SwiftUI

struct ContentView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var viewModel = ArtworkViewModel()

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "MutedGreenLight") ?? UIColor(named: "MutedGreenDark")

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        NavigationStack {
            TabView {
                ProfileView()
                    .tabItem {
                        VStack {
                            Image(systemName: "person.fill")
                                .font(.system(size: 32))
                                .padding(.top, 12)
                        }
                    }

                NavigationStack {
                    LogArtOptionsView(viewModel: viewModel)
                }
                .tabItem {
                    VStack {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 32))
                            .padding(.top, 12)
                    }
                }

                FriendActivityView()
                    .tabItem {
                        VStack {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 32))
                                .padding(.top, 12)
                        }
                    }
            }
        }
    }
}
