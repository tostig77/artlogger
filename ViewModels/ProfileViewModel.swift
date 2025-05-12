import Foundation
import Firebase
import FirebaseFirestore

class ProfileViewModel: ObservableObject {
    @Published var userProfile = UserProfile.empty
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var topArtists: [(url: String, count: Int, imageURL: String?)] = []
    @Published var isLoadingArtists = false

    @Published var userReviews: [ArtReview] = []
    @Published var isLoadingReviews = false

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

                let username = data["username"] as? String ?? ""
                let bio = data["bio"] as? String ?? ""

                self?.userProfile = UserProfile(username: username, bio: bio)
            }
        }
    }

    func fetchTopArtists(userId: String) {
        isLoadingArtists = true
        print("Fetching top artists for user: \(userId)")

        let firestoreService = FirestoreService()
        firestoreService.getTopArtists(userId: userId, limit: 5) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoadingArtists = false
                
                switch result {
                case .success(let artists):
                    self?.topArtists = artists
                case .failure(let error):
                    print("Error fetching top artists: \(error.localizedDescription)")
                    self?.topArtists = []
                }
            }
        }
    }

    func fetchUserReviews(userId: String) {
        isLoadingReviews = true
        print("Fetching reviews for user: \(userId)")
        
        let firestoreService = FirestoreService()
        firestoreService.getUserReviews(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoadingReviews = false
                
                switch result {
                case .success(let reviews):
                    // Sort reviews by date (most recent first)
                    let sortedReviews = reviews.sorted {
                        $0.dateViewed > $1.dateViewed
                    }
                    
                    self?.userReviews = sortedReviews
                    print("Fetched \(sortedReviews.count) reviews")
                    
                case .failure(let error):
                    print("Error fetching reviews: \(error.localizedDescription)")
                    self?.errorMessage = "Failed to load reviews: \(error.localizedDescription)"
                    self?.userReviews = []
                }
            }
        }
    }
}
