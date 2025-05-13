import SwiftUI

struct FriendActivityView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var viewModel = FriendViewModel()
    @State private var searchText = ""
    @State private var selectedFriendId: String? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: Search UI (always stays on top)
                VStack(spacing: 16) {
                    HStack {
                        TextField("Search by username", text: $searchText, onCommit: {
                            viewModel.searchUser(username: searchText.trimmingCharacters(in: .whitespacesAndNewlines))
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        if viewModel.isSearching {
                            ProgressView()
                                .padding(.leading, 8)
                        }
                    }
                    .padding(.horizontal)
                    
                    if let result = viewModel.searchResult {
                        NavigationLink(destination: FriendProfileView(friendId: result.userId)) {
                            HStack {
                                Image(systemName: "person.crop.circle")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                VStack(alignment: .leading) {
                                    Text(result.profile.username)
                                        .font(.headline)
                                    if !result.profile.bio.isEmpty {
                                        Text(result.profile.bio)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Text("View")
                                    .foregroundColor(Color("MutedGreenAccent"))
                            }
                            .padding(.horizontal)
                        }
                    } else if let error = viewModel.searchError {
                        Text(error)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    Divider()
                }
                .padding(.vertical, 12)
                .background(Color(UIColor.systemBackground))
                .zIndex(1)
                
                // MARK: Friend Activity Feed (scrollable)
                ScrollView {
                    VStack(spacing: 20) {
                        if viewModel.friends.isEmpty {
                            Text("Add friends to see updates!")
                                .foregroundColor(.secondary)
                                .padding()
                        } else if viewModel.isLoadingActivity {
                            ProgressView("Loading updates...")
                                .padding()
                        } else {
                            LazyVStack(spacing: 20) {
                                ForEach(viewModel.friendActivityLogs, id: \.review.id) { activity in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(activity.username)
                                            .font(.headline)
                                        
                                        if let imageURL = activity.review.imageURL, let url = URL(string: imageURL) {
                                            NavigationLink(destination: ArtworkReviewDetailView(review: activity.review)) {
                                                AsyncImage(url: url) { image in
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(height: 300)
                                                        .frame(maxWidth: .infinity)
                                                        .clipped()
                                                        .cornerRadius(12)
                                                } placeholder: {
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color.gray.opacity(0.2))
                                                        .frame(height: 300)
                                                        .overlay(ProgressView())
                                                }
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.top)
                        }
                    }
                }
            }
            .navigationTitle("Friends")
            .onAppear {
                if let userId = session.user?.uid {
                    viewModel.loadFriends(userId: userId)
                }
            }
        }
    }
}
