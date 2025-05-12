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

        let db = Firestore.firestore()
        let artistsRef = db.collection("artists").document(userId)

        artistsRef.getDocument { [weak self] document, error in
            if let error = error {
                print("Error fetching artists: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.isLoadingArtists = false
                }
                return
            }

            guard let document = document, document.exists, let data = document.data() else {
                print("No artist document found or it's empty")
                DispatchQueue.main.async {
                    self?.isLoadingArtists = false
                    self?.topArtists = []
                }
                return
            }

            print("Retrieved artist document with data: \(data)")
            var artistCounts: [(url: String, count: Int, imageURL: String?)] = []

            for (url, value) in data {
                if let artistInfo = value as? [String: Any] {
                    // Extract count and imageURL
                    let count = artistInfo["count"] as? Int ?? 0
                    let imageURL = artistInfo["imageURL"] as? String
                    print("Artist \(url): count=\(count), imageURL=\(imageURL ?? "nil")")
                    artistCounts.append((url: url, count: count, imageURL: imageURL))
                } else if let count = value as? Int {
                    // Legacy format - no image URL
                    print("Artist \(url): count=\(count) (legacy format, no image URL)")
                    artistCounts.append((url: url, count: count, imageURL: nil))
                }
            }

            let sortedArtists = artistCounts.sorted { $0.count > $1.count }
            print("Sorted artists (top 5): \(sortedArtists.prefix(5))")
            
            DispatchQueue.main.async {
                self?.topArtists = Array(sortedArtists.prefix(5))
                self?.isLoadingArtists = false
            }
        }
    }

    func fetchUserReviews(userId: String) {
        isLoadingReviews = true
        errorMessage = nil

        let db = Firestore.firestore()
        db.collection("reviews")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoadingReviews = false

                    if let error = error {
                        self?.errorMessage = "Error loading reviews: \(error.localizedDescription)"
                        return
                    }

                    guard let documents = snapshot?.documents else {
                        self?.userReviews = []
                        return
                    }

                    let reviews: [ArtReview] = documents.compactMap { doc in
                        let data = doc.data()

                        guard
                            let artworkIdStr = data["artworkId"] as? String,
                            let artworkId = UUID(uuidString: artworkIdStr),
                            let timestamp = data["dateViewed"] as? Timestamp,
                            let location = data["location"] as? String,
                            let reviewText = data["reviewText"] as? String
                        else {
                            return nil
                        }

                        return ArtReview(
                            artworkId: artworkId,
                            dateViewed: timestamp.dateValue(),
                            location: location,
                            reviewText: reviewText,
                            imageURL: data["imageURL"] as? String,
                            artistWikidataURL: data["artistWikidataURL"] as? String,
                            artistULANURL: data["artistULANURL"] as? String
                        )
                    }

                    self?.userReviews = reviews
                }
            }
    }
}
