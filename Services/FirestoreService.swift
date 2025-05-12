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
    /// Increment the count for an artist in the user's artist tracking document
    /// Increment the count for an artist in the user's artist tracking document
        func incrementArtistCount(userId: String, artistWikidataURL: String, completion: @escaping (Error?) -> Void) {
            // Skip if no Wikidata URL
            guard !artistWikidataURL.isEmpty else {
                completion(nil)
                return
            }
            
            // Print debug info
            print("Incrementing artist count for URL: \(artistWikidataURL)")
            
            // First, get the artist's image URL
            ArtistInfoService.shared.getArtistImageURL(from: artistWikidataURL) { [weak self] imageURL in
                guard let self = self else { return }
                
                // Debug print the image URL
                print("Retrieved image URL: \(imageURL ?? "nil")")
                
                // Reference to the user's artist document
                let userArtistDocRef = self.db.collection("artists").document(userId)
                
                // First get the current document
                userArtistDocRef.getDocument { documentSnapshot, error in
                    if let error = error {
                        print("Error fetching artist document: \(error.localizedDescription)")
                        completion(error)
                        return
                    }
                    
                    // Prepare the artist data
                    var artistData: [String: Any] = documentSnapshot?.data() ?? [:]
                    
                    // Extract or create artist info
                    var artistInfo: [String: Any] = [:]
                    
                    if let existingInfo = artistData[artistWikidataURL] as? [String: Any] {
                        artistInfo = existingInfo
                        let currentCount = artistInfo["count"] as? Int ?? 0
                        artistInfo["count"] = currentCount + 1
                        
                        // Keep existing image URL if present
                        if let existingImageURL = artistInfo["imageURL"] as? String, !existingImageURL.isEmpty {
                            print("Using existing image URL: \(existingImageURL)")
                        } else if let newImageURL = imageURL, !newImageURL.isEmpty {
                            // Otherwise set the new image URL
                            print("Setting new image URL: \(newImageURL)")
                            artistInfo["imageURL"] = newImageURL
                        }
                    } else {
                        // Create new artist info
                        artistInfo["count"] = 1
                        if let newImageURL = imageURL, !newImageURL.isEmpty {
                            print("Setting initial image URL: \(newImageURL)")
                            artistInfo["imageURL"] = newImageURL
                        }
                    }
                    
                    // Update the document with the new artist info
                    artistData[artistWikidataURL] = artistInfo
                    
                    // Print what we're saving
                    print("Saving artist data: \(artistInfo)")
                    
                    // Use setData with merge to update the document
                    userArtistDocRef.setData(artistData, merge: true) { error in
                        if let error = error {
                            print("Error updating artist document: \(error.localizedDescription)")
                        } else {
                            print("Successfully updated artist count and image URL")
                        }
                        completion(error)
                    }
                }
            }
        }
        
        /// Get the user's artist counts
        func getArtistCounts(userId: String, completion: @escaping (Result<[String: [String: Any]], Error>) -> Void) {
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
                
                // Convert to dictionary with artist info
                var artistData: [String: [String: Any]] = [:]
                for (url, value) in data {
                    if let artistInfo = value as? [String: Any] {
                        artistData[url] = artistInfo
                    } else if let count = value as? Int {
                        // Handle legacy data format for backward compatibility
                        artistData[url] = ["count": count]
                    }
                }
                
                completion(.success(artistData))
            }
        }

        /// Get top artists for a user
        func getTopArtists(userId: String, limit: Int = 5, completion: @escaping (Result<[(url: String, count: Int, imageURL: String?)], Error>) -> Void) {
            getArtistCounts(userId: userId) { result in
                switch result {
                case .success(let artistsData):
                    // Convert to array with extracted count values for sorting
                    var artistsArray: [(url: String, info: [String: Any])] = []
                    
                    for (url, info) in artistsData {
                        artistsArray.append((url: url, info: info))
                    }
                    
                    // Sort by count (descending) and take the top n
                    let sortedArtists = artistsArray.sorted {
                        let count1 = ($0.info["count"] as? Int) ?? 0
                        let count2 = ($1.info["count"] as? Int) ?? 0
                        return count1 > count2
                    }
                    
                    let topArtists = sortedArtists.prefix(limit).map { artist in
                        let imageURL = artist.info["imageURL"] as? String
                        print("Top artist URL: \(artist.url), count: \(artist.info["count"] as? Int ?? 0), imageURL: \(imageURL ?? "nil")")
                        
                        return (
                            url: artist.url,
                            count: (artist.info["count"] as? Int) ?? 0,
                            imageURL: imageURL
                        )
                    }
                    
                    completion(.success(Array(topArtists)))
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    
    
    
    
    func fetchReviewsForCurrentUser(userId: String, completion: @escaping ([ArtReview]) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("reviews")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching reviews: \(error)")
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([])
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
                
                completion(reviews)
            }
    }
    
    
    
}
