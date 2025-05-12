import Foundation
import Firebase
import Combine

class ArtworkViewModel: ObservableObject {
    @Published var artworks: [Artwork] = sampleArtworks
    @Published var reviews: [ArtReview] = []
    @Published var user: User = sampleUser
    
    // Storage status
    @Published var isSaving = false
    @Published var savingError: String? = nil
    
    // Temporary artwork being created
    @Published var draftArtwork: Artwork?
    
    // Search-related properties
    @Published var searchResults: [MetArtwork] = []
    @Published var isSearching = false
    @Published var searchError: String? = nil
    @Published var metDatabaseLoaded = false
    @Published var metDatabaseLoadingError: String? = nil
    
    // Image loading status
    @Published var isLoadingImages = false
    @Published var loadingImagesError: String? = nil
    
    // Services
    private let firestoreService = FirestoreService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Load the Met database when the view model is initialized
        loadMetDatabase()
    }
    
    func loadMetDatabase() {
        MetCSVService.shared.loadCSV { success, error in
            DispatchQueue.main.async {
                self.metDatabaseLoaded = success
                self.metDatabaseLoadingError = error
            }
        }
    }

    func logNewArtwork(_ artwork: Artwork, review: ArtReview, userId: String, completion: @escaping (Bool, String?) -> Void) {
        isSaving = true
        savingError = nil
        
        // Pass the image URL and artist Wikidata URL from artwork to review
        var updatedReview = review
        updatedReview.imageURL = artwork.imageURL
        updatedReview.artistWikidataURL = artwork.artistWikidataURL
        
        // Different flow based on whether it's a Met artwork or manual entry
        if let metSourceId = artwork.metSourceId {
            // This is a Met artwork, only save the review
            saveMetArtworkReview(userId: userId, metSourceId: metSourceId, review: updatedReview) { success, error in
                DispatchQueue.main.async {
                    self.isSaving = false
                    
                    if success {
                        // Add to local data
                        self.artworks.append(artwork)
                        self.reviews.append(updatedReview)
                        self.draftArtwork = nil
                    } else {
                        self.savingError = error
                    }
                    
                    completion(success, error)
                }
            }
        } else {
            // This is a manually entered artwork, save both artwork and review
            saveManualArtwork(userId: userId, artwork: artwork, review: updatedReview) { success, error in
                DispatchQueue.main.async {
                    self.isSaving = false
                    
                    if success {
                        // Add to local data
                        self.artworks.append(artwork)
                        self.reviews.append(updatedReview)
                        self.draftArtwork = nil
                    } else {
                        self.savingError = error
                    }
                    
                    completion(success, error)
                }
            }
        }
    }
    
    private func saveMetArtworkReview(userId: String, metSourceId: String, review: ArtReview, completion: @escaping (Bool, String?) -> Void) {
        firestoreService.saveReviewForMetArtwork(userId: userId, metSourceId: metSourceId, review: review) { result in
            switch result {
            case .success(_):
                completion(true, nil)
            case .failure(let error):
                completion(false, "Failed to save review: \(error.localizedDescription)")
            }
        }
    }
    
    private func saveManualArtwork(userId: String, artwork: Artwork, review: ArtReview, completion: @escaping (Bool, String?) -> Void) {
        // First, save the artwork
        firestoreService.saveArtwork(userId: userId, artwork: artwork) { result in
            switch result {
            case .success(let artworkId):
                // Now save the review with the artwork ID
                self.firestoreService.saveReviewForManualArtwork(userId: userId, artworkId: artworkId, review: review) { reviewResult in
                    switch reviewResult {
                    case .success(_):
                        completion(true, nil)
                    case .failure(let error):
                        completion(false, "Failed to save review: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                completion(false, "Failed to save artwork: \(error.localizedDescription)")
            }
        }
    }
    
    func createDraftArtwork(
        title: String,
        artist: String,
        date: String,
        medium: String,
        movement: String,
        artistWikidataURL: String? = nil,
        artistULANURL: String? = nil
    ) {
        draftArtwork = Artwork(
            title: title,
            artist: artist,
            date: date,
            medium: medium,
            movement: movement,
            artistWikidataURL: artistWikidataURL,
            artistULANURL: artistULANURL
        )
    }
    
    func createDraftFromMetArtwork(_ metArtwork: MetArtwork) {
        draftArtwork = metArtwork.toArtwork()
    }
    
    func clearDraft() {
        draftArtwork = nil
    }

    func toggleFavorite(for artwork: Artwork) {
        if let index = user.favoriteArtworks.firstIndex(of: artwork.id) {
            user.favoriteArtworks.remove(at: index)
        } else {
            user.favoriteArtworks.append(artwork.id)
        }
    }

    func isFavorite(_ artwork: Artwork) -> Bool {
        user.favoriteArtworks.contains(artwork.id)
    }
    
    // Search the Met database
    func searchMetDatabase(query: String) {
        isSearching = true
        searchError = nil
        
        if !metDatabaseLoaded {
            // Try to load the database if it's not loaded yet
            MetCSVService.shared.loadCSV { success, error in
                DispatchQueue.main.async {
                    self.metDatabaseLoaded = success
                    if success {
                        self.performSearch(query: query)
                    } else {
                        self.isSearching = false
                        self.searchError = error
                    }
                }
            }
        } else {
            performSearch(query: query)
        }
    }
    
    private func performSearch(query: String) {
        let results = MetCSVService.shared.searchArtworks(query: query)
        
        if results.isEmpty {
            DispatchQueue.main.async {
                self.searchResults = []
                self.isSearching = false
                self.searchError = "No artworks found matching '\(query)'"
            }
            return
        }
        
        // Fetch image URLs for each artwork (limit to first 20 results to avoid too many API calls)
        let limitedResults = Array(results.prefix(20))
        var enrichedResults: [MetArtwork] = []
        let group = DispatchGroup()
        
        for artwork in limitedResults {
            group.enter()
            MetAPIService.shared.enrichMetArtwork(artwork) { result in
                switch result {
                case .success(let enrichedArtwork):
                    enrichedResults.append(enrichedArtwork)
                case .failure:
                    // If we can't get the image, still add the original artwork
                    enrichedResults.append(artwork)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.searchResults = enrichedResults
            self.isSearching = false
            
            if enrichedResults.isEmpty {
                self.searchError = "No artworks found matching '\(query)'"
            }
        }
    }
}
