//
//  FriendViewModel.swift
//  artlogger
//
//  Created by Me on 5/12/25.
//


import Foundation
import Combine

class FriendViewModel: ObservableObject {
    // Search state
    @Published var searchQuery = ""
    @Published var isSearching = false
    @Published var searchResult: (userId: String, profile: UserProfile)? = nil
    @Published var searchError: String? = nil
    
    // Friend list state
    @Published var friends: [(id: String, profile: UserProfile)] = []
    @Published var isLoadingFriends = false
    @Published var friendsError: String? = nil
    
    // Friend activity state
    @Published var friendActivityLogs: [(userId: String, username: String, review: ArtReview)] = []
    @Published var isLoadingActivity = false
    @Published var activityError: String? = nil
    
    // Follow state
    @Published var isFollowing = false
    @Published var isCheckingFollowStatus = false
    @Published var isUpdatingFollowStatus = false
    
    // Selected friend profile
    @Published var selectedFriendProfile: UserProfile? = nil
    @Published var selectedFriendId: String? = nil
    @Published var isLoadingSelectedProfile = false
    @Published var selectedProfileError: String? = nil
    
    // Friend top artists state
    @Published var friendTopArtists: [(url: String, count: Int, imageURL: String?)] = []
    @Published var isLoadingFriendArtists = false
    
    // Friend recent logs state
    @Published var friendRecentLogs: [ArtReview] = []
    @Published var isLoadingFriendLogs = false
    
    // Services
    private let friendService = FriendService.shared
    private let firestoreService = FirestoreService()
    
    // Search for a user by username
    func searchUser(username: String) {
        guard !username.isEmpty else {
            searchResult = nil
            searchError = nil
            return
        }
        
        isSearching = true
        searchError = nil
        
        friendService.searchUserByUsername(username: username) { result in
            DispatchQueue.main.async {
                self.isSearching = false
                
                switch result {
                case .success(let userData):
                    if let userData = userData, let userId = userData["userId"] as? String {
                        let username = userData["username"] as? String ?? "Unknown User"
                        let bio = userData["bio"] as? String ?? ""
                        let profile = UserProfile(username: username, bio: bio)
                        
                        self.searchResult = (userId: userId, profile: profile)
                    } else {
                        self.searchResult = nil
                        self.searchError = "No user found with username: \(username)"
                    }
                    
                case .failure(let error):
                    self.searchResult = nil
                    self.searchError = "Error searching for user: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // Load friends list
    func loadFriends(userId: String) {
        isLoadingFriends = true
        friendsError = nil
        
        friendService.getFriendsWithProfiles(userId: userId) { result in
            DispatchQueue.main.async {
                self.isLoadingFriends = false
                
                switch result {
                case .success(let friendProfiles):
                    self.friends = friendProfiles
                    
                    // If we have friends, load their activity
                    if !friendProfiles.isEmpty {
                        let friendIds = friendProfiles.map { $0.id }
                        self.loadFriendActivity(friendIds: friendIds)
                    } else {
                        self.friendActivityLogs = []
                    }
                    
                case .failure(let error):
                    self.friendsError = "Failed to load friends: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // Load friend activity
    func loadFriendActivity(friendIds: [String]) {
        if friendIds.isEmpty {
            friendActivityLogs = []
            return
        }
        
        isLoadingActivity = true
        activityError = nil
        
        friendService.getFriendActivityLogs(friendIds: friendIds) { result in
            DispatchQueue.main.async {
                self.isLoadingActivity = false
                
                switch result {
                case .success(let logs):
                    self.friendActivityLogs = logs
                case .failure(let error):
                    self.activityError = "Failed to load friend activity: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // Check if following a specific user
    func checkFollowStatus(currentUserId: String, friendUserId: String) {
        isCheckingFollowStatus = true
        
        friendService.isFollowing(currentUserId: currentUserId, friendUserId: friendUserId) { isFollowing in
            DispatchQueue.main.async {
                self.isFollowing = isFollowing
                self.isCheckingFollowStatus = false
            }
        }
    }
    
    // Follow a user
    func followUser(currentUserId: String, friendUserId: String, completion: @escaping (Bool) -> Void) {
        isUpdatingFollowStatus = true
        
        friendService.followUser(currentUserId: currentUserId, friendUserId: friendUserId) { success, error in
            DispatchQueue.main.async {
                self.isUpdatingFollowStatus = false
                
                if success {
                    self.isFollowing = true
                    
                    // Refresh friends list
                    self.loadFriends(userId: currentUserId)
                }
                
                completion(success)
            }
        }
    }
    
    // Unfollow a user
    func unfollowUser(currentUserId: String, friendUserId: String, completion: @escaping (Bool) -> Void) {
        isUpdatingFollowStatus = true
        
        friendService.unfollowUser(currentUserId: currentUserId, friendUserId: friendUserId) { success, error in
            DispatchQueue.main.async {
                self.isUpdatingFollowStatus = false
                
                if success {
                    self.isFollowing = false
                    
                    // Refresh friends list
                    self.loadFriends(userId: currentUserId)
                }
                
                completion(success)
            }
        }
    }
    
    // Load friend profile, top artists, and recent logs
    func loadFriendProfile(friendId: String) {
        isLoadingSelectedProfile = true
        selectedProfileError = nil
        
        // Load friend profile
        friendService.getFriendProfile(userId: friendId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let profile):
                    self.selectedFriendProfile = profile
                    self.selectedFriendId = friendId
                    
                    // Now load top artists and recent logs
                    self.loadFriendTopArtists(userId: friendId)
                    self.loadFriendRecentLogs(userId: friendId)
                    
                case .failure(let error):
                    self.selectedProfileError = "Failed to load profile: \(error.localizedDescription)"
                }
                
                self.isLoadingSelectedProfile = false
            }
        }
    }
    
    // Load friend's top artists
    func loadFriendTopArtists(userId: String) {
        isLoadingFriendArtists = true
        
        firestoreService.getTopArtists(userId: userId, limit: 5) { result in
            DispatchQueue.main.async {
                self.isLoadingFriendArtists = false
                
                switch result {
                case .success(let artists):
                    self.friendTopArtists = artists
                case .failure(let error):
                    print("Error fetching friend's top artists: \(error.localizedDescription)")
                    self.friendTopArtists = []
                }
            }
        }
    }
    
    // Load friend's recent logs
    func loadFriendRecentLogs(userId: String) {
        isLoadingFriendLogs = true
        
        firestoreService.fetchReviewsForCurrentUser(userId: userId) { reviews in
            DispatchQueue.main.async {
                self.isLoadingFriendLogs = false
                
                // Sort reviews by date (most recent first) and limit to 5
                let sortedReviews = reviews.sorted { $0.dateViewed > $1.dateViewed }
                self.friendRecentLogs = Array(sortedReviews.prefix(5))
                
            }
        }
    }
}
