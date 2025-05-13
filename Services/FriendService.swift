//
//  FriendService.swift
//  artlogger
//
//  Created by Me on 5/12/25.
//


import Foundation
import Firebase
import FirebaseFirestore

class FriendService {
    static let shared = FriendService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // Search for a user by username
    func searchUserByUsername(username: String, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        db.collection("users")
            .whereField("username", isEqualTo: username)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let documents = snapshot?.documents, !documents.isEmpty {
                    // Return the first user found with this username
                    let userData = documents[0].data()
                    let userId = documents[0].documentID
                    
                    var result = userData
                    result["userId"] = userId
                    
                    completion(.success(result))
                } else {
                    // No user found with this username
                    completion(.success(nil))
                }
            }
    }
    
    // Follow a user (add to friends collection)
    func followUser(currentUserId: String, friendUserId: String, completion: @escaping (Bool, Error?) -> Void) {
        // Reference to the current user's friends document
        let friendsRef = db.collection("friends").document(currentUserId)
        
        // Get the current friends list
        friendsRef.getDocument { snapshot, error in
            if let error = error {
                completion(false, error)
                return
            }
            
            if let snapshot = snapshot, snapshot.exists {
                // Document exists, update the friends array
                friendsRef.updateData([
                    "friendIds": FieldValue.arrayUnion([friendUserId])
                ]) { error in
                    if let error = error {
                        completion(false, error)
                    } else {
                        completion(true, nil)
                    }
                }
            } else {
                // Document doesn't exist yet, create it
                friendsRef.setData([
                    "friendIds": [friendUserId]
                ]) { error in
                    if let error = error {
                        completion(false, error)
                    } else {
                        completion(true, nil)
                    }
                }
            }
        }
    }
    
    // Unfollow a user (remove from friends collection)
    func unfollowUser(currentUserId: String, friendUserId: String, completion: @escaping (Bool, Error?) -> Void) {
        let friendsRef = db.collection("friends").document(currentUserId)
        
        friendsRef.updateData([
            "friendIds": FieldValue.arrayRemove([friendUserId])
        ]) { error in
            if let error = error {
                completion(false, error)
            } else {
                completion(true, nil)
            }
        }
    }
    
    // Check if a user is being followed
    func isFollowing(currentUserId: String, friendUserId: String, completion: @escaping (Bool) -> Void) {
        let friendsRef = db.collection("friends").document(currentUserId)
        
        friendsRef.getDocument { snapshot, error in
            if let error = error {
                print("Error checking if following: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let snapshot = snapshot, snapshot.exists,
               let friendIds = snapshot.data()?["friendIds"] as? [String] {
                completion(friendIds.contains(friendUserId))
            } else {
                completion(false)
            }
        }
    }
    
    // Get all friends for a user
    func getFriends(userId: String, completion: @escaping (Result<[String], Error>) -> Void) {
        let friendsRef = db.collection("friends").document(userId)
        
        friendsRef.getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let snapshot = snapshot, snapshot.exists,
               let friendIds = snapshot.data()?["friendIds"] as? [String] {
                completion(.success(friendIds))
            } else {
                completion(.success([]))
            }
        }
    }
    
    // Get friend profile data
    func getFriendProfile(userId: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = snapshot?.data() else {
                let error = NSError(domain: "FriendService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
                completion(.failure(error))
                return
            }
            
            let username = data["username"] as? String ?? "Unknown User"
            let bio = data["bio"] as? String ?? ""
            
            let profile = UserProfile(username: username, bio: bio)
            completion(.success(profile))
        }
    }
    
    // Get a list of all friends with their profile data
    func getFriendsWithProfiles(userId: String, completion: @escaping (Result<[(id: String, profile: UserProfile)], Error>) -> Void) {
        getFriends(userId: userId) { result in
            switch result {
            case .success(let friendIds):
                if friendIds.isEmpty {
                    completion(.success([]))
                    return
                }
                
                var friendProfiles: [(id: String, profile: UserProfile)] = []
                let group = DispatchGroup()
                
                for friendId in friendIds {
                    group.enter()
                    self.getFriendProfile(userId: friendId) { profileResult in
                        switch profileResult {
                        case .success(let profile):
                            friendProfiles.append((id: friendId, profile: profile))
                        case .failure(let error):
                            print("Error fetching profile for \(friendId): \(error.localizedDescription)")
                            // Still add a basic profile with just the ID
                            friendProfiles.append((id: friendId, profile: UserProfile(username: "User \(friendId)", bio: "")))
                        }
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    completion(.success(friendProfiles))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Get recent logs from friends
    func getFriendActivityLogs(friendIds: [String], limit: Int = 20, completion: @escaping (Result<[(userId: String, username: String, review: ArtReview)], Error>) -> Void) {
        if friendIds.isEmpty {
            completion(.success([]))
            return
        }
        
        print("Fetching friend logs for: \(friendIds)")
        
        db.collection("reviews")
            .whereField("userId", in: friendIds)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                // Process all reviews and match with usernames
                var reviewsWithUsers: [(userId: String, username: String, review: ArtReview)] = []
                let group = DispatchGroup()
                
                for document in documents {
                    let data = document.data()
                    
                    guard let userId = data["userId"] as? String else {
                        continue
                    }

                    let artworkId: UUID? = {
                        if let idStr = data["artworkId"] as? String {
                            return UUID(uuidString: idStr)
                        } else {
                            return nil
                        }
                    }()

                    let metSourceId: String? = data["metSourceId"] as? String

                    // If neither ID is available, skip the document
                    if artworkId == nil && metSourceId == nil {
                        continue
                    }

                    
                    // Extract date
                    let dateViewed: Date
                    if let timestamp = data["dateViewed"] as? Timestamp {
                        dateViewed = timestamp.dateValue()
                    } else {
                        dateViewed = Date()
                    }
                    
                    // Create the review object
                    var review = ArtReview(
                        artworkId: artworkId ?? UUID(), // fallback UUID to satisfy struct; you can handle nil more gracefully if needed
                        dateViewed: dateViewed,
                        location: data["location"] as? String ?? "",
                        reviewText: data["reviewText"] as? String ?? "",
                        imageURL: data["imageURL"] as? String,
                        artistWikidataURL: data["artistWikidataURL"] as? String,
                        artistULANURL: data["artistULANURL"] as? String,
                        metSourceId: metSourceId
                    )
                    
                    // Set the metSourceId if it exists
                    if let metId = data["metSourceId"] as? String {
                        review = ArtReview(
                            artworkId: review.artworkId,
                            dateViewed: review.dateViewed,
                            location: review.location,
                            reviewText: review.reviewText,
                            imageURL: review.imageURL,
                            artistWikidataURL: review.artistWikidataURL,
                            artistULANURL: review.artistULANURL,
                            metSourceId: metId
                        )
                    }
                    
                    // Get the username for this user
                    group.enter()
                    self.getUsernameById(userId: userId) { username in
                        reviewsWithUsers.append((userId: userId, username: username, review: review))
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    // Sort by date (most recent first)
                    let sortedReviews = reviewsWithUsers.sorted {
                        $0.review.dateViewed > $1.review.dateViewed
                    }
                    
                    completion(.success(sortedReviews))
                }
            }
    }
    
    // Helper function to get a username by user ID
    private func getUsernameById(userId: String, completion: @escaping (String) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching username: \(error.localizedDescription)")
                completion("User \(userId)")
                return
            }
            
            if let data = snapshot?.data(), let username = data["username"] as? String {
                completion(username)
            } else {
                completion("User \(userId)")
            }
        }
    }
}
