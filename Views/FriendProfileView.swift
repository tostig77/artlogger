//
//  FriendProfileView.swift
//  artlogger
//
//  Created by Me on 5/12/25.
//


import SwiftUI
import Firebase


struct FriendProfileView: View {
    let friendId: String
    @EnvironmentObject var session: SessionStore
    @StateObject private var viewModel = FriendViewModel()
    @State private var selectedArtistUrl: String? = nil
    @State private var selectedReview: ArtReview? = nil
    @State private var artistImages: [String: String] = [:]
    @State private var showFollowAlert = false
    @State private var followAlertMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if viewModel.isLoadingSelectedProfile {
                    loadingView
                } else if let profile = viewModel.selectedFriendProfile {
                    // Profile header
                    profileHeaderView(profile: profile)
                    
                    Divider()
                    
                    // Top Artists Section
                    topArtistsSection
                    
                    Divider()
                    
                    // Recent Logs Section
                    recentLogsSection
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadFriendData()
        }
        .alert(isPresented: $showFollowAlert) {
            Alert(
                title: Text("Follow Status"),
                message: Text(followAlertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .navigationDestination(isPresented: Binding(
            get: { selectedArtistUrl != nil },
            set: { if !$0 { selectedArtistUrl = nil } }
        )) {
            if let artistUrl = selectedArtistUrl {
                ArtistDetailView(artistUrl: artistUrl)
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { selectedReview != nil },
            set: { if !$0 { selectedReview = nil } }
        )) {
            if let review = selectedReview {
                ArtworkReviewDetailView(review: review)
            }
        }
    }
    
    // Loading view
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            Text("Loading profile...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
    
    // Profile header with follow button
    private func profileHeaderView(profile: UserProfile) -> some View {
        HStack(spacing: 20) {
            // Profile image
            let hash = stableHash(profile.username)
            let emoji = emojiList[hash % emojiList.count]
            let backgroundColor = pastelColors[hash % pastelColors.count]

            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 80, height: 80)
                Text(emoji)
                    .font(.system(size: 36))
            }
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.username)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if !profile.bio.isEmpty {
                    Text(profile.bio)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Follow button
            followButton
        }
        .padding(.vertical, 8)
    }
    
    // Follow/Unfollow button
    private var followButton: some View {
        Button(action: {
            toggleFollowStatus()
        }) {
            if viewModel.isCheckingFollowStatus || viewModel.isUpdatingFollowStatus {
                ProgressView()
                    .frame(width: 24, height: 24)
            } else {
                Text(viewModel.isFollowing ? "Unfollow" : "Follow")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(viewModel.isFollowing ? .white : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(viewModel.isFollowing ? Color.gray : Color("MutedGreenAccent"))
                    .cornerRadius(20)
            }
        }
        .disabled(viewModel.isCheckingFollowStatus || viewModel.isUpdatingFollowStatus)
    }
    
    // Top artists section
    private var topArtistsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top artists")
                .font(.title2)
                .fontWeight(.bold)
            
            if viewModel.isLoadingFriendArtists {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else if viewModel.friendTopArtists.isEmpty {
                Text("No artists yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                // Horizontal scrolling artist circles
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.friendTopArtists, id: \.url) { artist in
                            artistCircle(url: artist.url, count: artist.count, imageURL: artist.imageURL)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // Artist circle
    private func artistCircle(url: String, count: Int, imageURL: String?) -> some View {
        Button {
            selectedArtistUrl = url
        } label: {
            VStack {
                // Artist Image Circle
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .shadow(radius: 2)
                        )
                    
                    if let imageURL = imageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 70, height: 70)
                                    .clipShape(Circle())
                            case .failure:
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.gray)
                            @unknown default:
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.gray)
                            }
                        }
                    } else {
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.gray)
                    }
                }
                
                // Artist name - fetch and show dynamically
                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Recent logs section
    private var recentLogsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent art logs")
                .font(.title2)
                .fontWeight(.bold)
            
            if viewModel.isLoadingFriendLogs {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.friendRecentLogs.isEmpty {
                Text("No art logs yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                // Vertical list of artwork logs - limited to most recent
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.friendRecentLogs, id: \.id) { review in
                        Button {
                            selectedReview = review
                        } label: {
                            ArtworkLogItem(review: review)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func loadFriendData() {
        // Load friend profile
        viewModel.loadFriendProfile(friendId: friendId)
        
        // Check if already following
        if let currentUserId = session.user?.uid {
            viewModel.checkFollowStatus(currentUserId: currentUserId, friendUserId: friendId)
        }
    }
    
    // Toggle follow status
    private func toggleFollowStatus() {
        guard let currentUserId = session.user?.uid else {
            followAlertMessage = "You must be logged in to follow users"
            showFollowAlert = true
            return
        }
        
        if viewModel.isFollowing {
            // Unfollow
            viewModel.unfollowUser(currentUserId: currentUserId, friendUserId: friendId) { success in
                if success {
                    followAlertMessage = "You have unfollowed this user"
                } else {
                    followAlertMessage = "Failed to unfollow this user. Please try again."
                }
                showFollowAlert = true
            }
        } else {
            // Follow
            viewModel.followUser(currentUserId: currentUserId, friendUserId: friendId) { success in
                if success {
                    followAlertMessage = "You are now following this user"
                } else {
                    followAlertMessage = "Failed to follow this user. Please try again."
                }
                showFollowAlert = true
            }
        }
    }
}
