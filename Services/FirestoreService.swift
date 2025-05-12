//
//  FirestoreService.swift
//  artlogger
//
//  Created by Me on 5/12/25.
//


import Foundation
import Firebase
import FirebaseFirestore

class FirestoreService {
    private let db = Firestore.firestore()
    
    // MARK: - Artwork Methods
    
    /// Save manually entered artwork to Firestore
    func saveArtwork(userId: String, artwork: Artwork, completion: @escaping (Result<String, Error>) -> Void) {
        // Create artwork data
        let artworkData: [String: Any] = [
            "userId": userId,
            "title": artwork.title,
            "artist": artwork.artist,
            "date": artwork.date,
            "medium": artwork.medium,
            "movement": artwork.movement,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
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
                movement: data["movement"] as? String ?? ""
            )
            
            completion(.success(artwork))
        }
    }
    
    // MARK: - Review Methods
    
    /// Save review for manually entered artwork
    func saveReviewForManualArtwork(userId: String, artworkId: String, review: ArtReview, completion: @escaping (Result<String, Error>) -> Void) {
        // Create the review data
        let reviewId = review.id.uuidString
        let reviewData: [String: Any] = [
            "userId": userId,
            "artworkId": artworkId,
            "dateViewed": review.dateViewed,
            "location": review.location,
            "reviewText": review.reviewText,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        // Save to Firestore
        db.collection("reviews").document(reviewId).setData(reviewData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(reviewId))
            }
        }
    }
    
    /// Save review for Met artwork
    func saveReviewForMetArtwork(userId: String, metSourceId: String, review: ArtReview, completion: @escaping (Result<String, Error>) -> Void) {
        // Create the review data
        let reviewId = review.id.uuidString
        let reviewData: [String: Any] = [
            "userId": userId,
            "metSourceId": metSourceId,
            "dateViewed": review.dateViewed,
            "location": review.location,
            "reviewText": review.reviewText,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        // Save to Firestore
        db.collection("reviews").document(reviewId).setData(reviewData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(reviewId))
            }
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
                        reviewText: data["reviewText"] as? String ?? ""
                    )
                    
                    reviews.append(review)
                }
                
                completion(.success(reviews))
            }
    }
}