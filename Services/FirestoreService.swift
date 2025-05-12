import Foundation
import Firebase
import FirebaseFirestore

class FirestoreService {
    private let db = Firestore.firestore()
    
    // MARK: - Artwork Methods
    
    /// Save manually entered artwork to Firestore
    func saveArtwork(userId: String, artwork: Artwork, completion: @escaping (Result<String, Error>) -> Void) {
        // Create artwork data
        var artworkData: [String: Any] = [
            "userId": userId,
            "title": artwork.title,
            "artist": artwork.artist,
            "date": artwork.date,
            "medium": artwork.medium,
            "movement": artwork.movement,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        // Add optional fields if available
        if let metSourceId = artwork.metSourceId {
            artworkData["metSourceId"] = metSourceId
        }
        
        if let imageURL = artwork.imageURL {
            artworkData["imageURL"] = imageURL
        }
        
        if let artistWikidataURL = artwork.artistWikidataURL {
            artworkData["artistWikidataURL"] = artistWikidataURL
        }
        
        if let artistULANURL = artwork.artistULANURL {
            artworkData["artistULANURL"] = artistULANURL
        }
        
        // Use the artwork's UUID string as the document ID
        let artworkId = artwork.id.uuidString
        
        // Save to Firestore
        db.collection("artworks").document(artworkId).setData(artworkData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(artworkId))
            }
        }
    }
    
    /// Get artwork by ID
    func getArtwork(id: String, completion: @escaping (Result<Artwork, Error>) -> Void) {
        db.collection("artworks").document(id).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = snapshot?.data() else {
                completion(.failure(NSError(domain: "FirestoreError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Artwork not found"])))
                return
            }
            
            // Convert to Artwork
            let artwork = Artwork(
                title: data["title"] as? String ?? "",
                artist: data["artist"] as? String ?? "",
                date: data["date"] as? String ?? "",
                medium: data["medium"] as? String ?? "",
                movement: data["movement"] as? String ?? "",
                metSourceId: data["metSourceId"] as? String,
                imageURL: data["imageURL"] as? String,
                artistWikidataURL: data["artistWikidataURL"] as? String,
                artistULANURL: data["artistULANURL"] as? String
            )
            
            completion(.success(artwork))
        }
    }
    
    // MARK: - Review Methods
    
    /// Save review for manually entered artwork
    func saveReviewForManualArtwork(userId: String, artworkId: String, review: ArtReview, completion: @escaping (Result<String, Error>) -> Void) {
        // Create the review data
        let reviewId = review.id.uuidString
        var reviewData: [String: Any] = [
            "userId": userId,
            "artworkId": artworkId,
            "dateViewed": review.dateViewed,
            "location": review.location,
            "reviewText": review.reviewText,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        // Add optional fields if available
        if let imageURL = review.imageURL {
            reviewData["imageURL"] = imageURL
        }
        
        if let artistWikidataURL = review.artistWikidataURL {
            reviewData["artistWikidataURL"] = artistWikidataURL
        }
        
        if let artistULANURL = review.artistULANURL {
            reviewData["artistULANURL"] = artistULANURL
        }
        
        // Save to Firestore
        db.collection("reviews").document(reviewId).setData(reviewData) { [weak self] error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // After successfully saving the review, increment the artist count if Wikidata URL exists
            if let wikidataURL = review.artistWikidataURL {
                self?.incrementArtistCount(userId: userId, artistWikidataURL: wikidataURL) { error in
                    if let error = error {
                        print("Warning: Failed to increment artist count: \(error.localizedDescription)")
                        // Continue with success even if this fails - it's not critical
                    }
                }
            }
            
            completion(.success(reviewId))
        }
    }
    
    /// Save review for Met artwork
    func saveReviewForMetArtwork(userId: String, metSourceId: String, review: ArtReview, completion: @escaping (Result<String, Error>) -> Void) {
        // Create the review data
        let reviewId = review.id.uuidString
        var reviewData: [String: Any] = [
            "userId": userId,
            "metSourceId": metSourceId,
            "dateViewed": review.dateViewed,
            "location": review.location,
            "reviewText": review.reviewText,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        // Add optional fields if available
        if let imageURL = review.imageURL {
            reviewData["imageURL"] = imageURL
        }
        
        if let artistWikidataURL = review.artistWikidataURL {
            reviewData["artistWikidataURL"] = artistWikidataURL
        }
        
        if let artistULANURL = review.artistULANURL {
            reviewData["artistULANURL"] = artistULANURL
        }
        
        // Save to Firestore
        db.collection("reviews").document(reviewId).setData(reviewData) { [weak self] error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // After successfully saving the review, increment the artist count if Wikidata URL exists
            if let wikidataURL = review.artistWikidataURL {
                self?.incrementArtistCount(userId: userId, artistWikidataURL: wikidataURL) { error in
                    if let error = error {
                        print("Warning: Failed to increment artist count: \(error.localizedDescription)")
                        // Continue with success even if this fails - it's not critical
                    }
                }
            }
            
            completion(.success(reviewId))
        }
    }
    
    /// Get user's reviews
    func getUserReviews(userId: String, completion: @escaping (Result<[ArtReview], Error>) -> Void) {
        db.collection("reviews")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                var reviews: [ArtReview] = []
                
                for document in snapshot?.documents ?? [] {
                    let data = document.data()
                    
                    // Extract artworkId (could be manual or Met)
                    let artworkId = UUID(uuidString: data["artworkId"] as? String ?? "") ?? UUID()
                    
                    // Extract date
                    let dateViewed: Date
                    if let timestamp = data["dateViewed"] as? Timestamp {
                        dateViewed = timestamp.dateValue()
                    } else {
                        dateViewed = Date()
                    }
                    
                    let review = ArtReview(
                        artworkId: artworkId,
                        dateViewed: dateViewed,
                        location: data["location"] as? String ?? "",
                        reviewText: data["reviewText"] as? String ?? "",
                        imageURL: data["imageURL"] as? String,
                        artistWikidataURL: data["artistWikidataURL"] as? String,
                        artistULANURL: data["artistULANURL"] as? String
                    )
                    
                    reviews.append(review)
                }
                
                completion(.success(reviews))
            }
    }
    
    // MARK: - Artist Tracking Methods
    
    /// Increment the count for an artist in the user's artist tracking document
    func incrementArtistCount(userId: String, artistWikidataURL: String, completion: @escaping (Error?) -> Void) {
        // Skip if no Wikidata URL
        guard !artistWikidataURL.isEmpty else {
            completion(nil)
            return
        }
        
        // Reference to the user's artist document
        let userArtistDocRef = db.collection("artists").document(userId)
        
        // Use a transaction to safely update the artist count
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let documentSnapshot: DocumentSnapshot
            do {
                try documentSnapshot = transaction.getDocument(userArtistDocRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            // Get the current artist data or create a new empty map
            var artistData: [String: Any] = documentSnapshot.exists ?
                (documentSnapshot.data() ?? [:]) : [:]
            
            // Get the current count for this artist or default to 0
            let currentCount = artistData[artistWikidataURL] as? Int ?? 0
            
            // Update the count
            artistData[artistWikidataURL] = currentCount + 1
            
            // Update the document
            transaction.setData(artistData, forDocument: userArtistDocRef)
            
            return nil
        }) { (_, error) in
            completion(error)
        }
    }
    
    /// Get the user's artist counts
    func getArtistCounts(userId: String, completion: @escaping (Result<[String: Int], Error>) -> Void) {
        let artistsDocRef = db.collection("artists").document(userId)
        
        artistsDocRef.getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists else {
                // No document found - return empty dictionary
                completion(.success([:]))
                return
            }
            
            guard let data = document.data() else {
                completion(.success([:]))
                return
            }
            
            // Convert all values to Int (handle potential type issues)
            var artistCounts: [String: Int] = [:]
            for (url, value) in data {
                if let count = value as? Int {
                    artistCounts[url] = count
                }
            }
            
            completion(.success(artistCounts))
        }
    }
    
    /// Get top artists for a user
    func getTopArtists(userId: String, limit: Int = 5, completion: @escaping (Result<[(url: String, count: Int)], Error>) -> Void) {
        getArtistCounts(userId: userId) { result in
            switch result {
            case .success(let counts):
                // Sort by count (descending) and take the top n
                let sortedArtists = counts.sorted { $0.value > $1.value }
                let topArtists = sortedArtists.prefix(limit).map { (url: $0.key, count: $0.value) }
                completion(.success(Array(topArtists)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
