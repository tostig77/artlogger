import Foundation
import Firebase
import FirebaseFirestore

// View Model for Profile
class ProfileViewModel: ObservableObject {
    @Published var userProfile = UserProfile.empty
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Top artists (just URLs and counts)
    @Published var topArtists: [(url: String, count: Int)] = []
    @Published var isLoadingArtists = false
    
    func fetchUserProfile(userId: String) {
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Failed to load profile: \(error.localizedDescription)"
                    return
                }
                
                guard let data = snapshot?.data() else {
                    self?.errorMessage = "No profile data found"
                    return
                }
                
                // Extract profile data
                let username = data["username"] as? String ?? ""
                let bio = data["bio"] as? String ?? ""
                
                self?.userProfile = UserProfile(username: username, bio: bio)
            }
        }
    }
    
    func fetchTopArtists(userId: String) {
        isLoadingArtists = true
        
        // Access the artists collection to get the top 5 artists by count
        let db = Firestore.firestore()
        let artistsRef = db.collection("artists").document(userId)
        
        artistsRef.getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                self?.isLoadingArtists = false
                
                if let error = error {
                    print("Error fetching artists: \(error.localizedDescription)")
                    return
                }
                
                guard let document = document, document.exists, let data = document.data() else {
                    // No artists data
                    return
                }
                
                // Convert data to array of (url, count) tuples
                var artistCounts: [(url: String, count: Int)] = []
                
                for (url, value) in data {
                    if let count = value as? Int {
                        artistCounts.append((url: url, count: count))
                    }
                }
                
                // Sort by count (descending) and take the top 5
                let sortedArtists = artistCounts.sorted { $0.count > $1.count }
                let top5Artists = sortedArtists.prefix(5)
                
                self?.topArtists = Array(top5Artists)
            }
        }
    }
}
