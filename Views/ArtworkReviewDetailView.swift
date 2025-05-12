import SwiftUI

struct ArtworkReviewDetailView: View {
    let review: ArtReview
    @State private var artwork: Artwork?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    // For navigating to artist detail
    @State private var showArtistDetail = false
    
    // Debug state
    @State private var debugInfo: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 12) {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        
                        if !debugInfo.isEmpty {
                            Text(debugInfo)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else if let artwork = artwork {
                    // Artwork image
                    if let imageURL = review.imageURL, !imageURL.isEmpty {
                        AsyncArtworkImage(urlString: imageURL) {
                            ZStack {
                                Color.gray.opacity(0.2)
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.system(size: 30))
                                    Text("Loading image...")
                                        .font(.caption)
                                }
                            }
                        }
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(8)
                    }
                    
                    // Artwork details
                    Group {
                        Text(artwork.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Button(action: {
                            if artwork.artistWikidataURL != nil {
                                showArtistDetail = true
                            }
                        }) {
                            HStack {
                                Text("by \(artwork.artist)")
                                    .font(.title3)
                                
                                if artwork.artistWikidataURL != nil {
                                    Image(systemName: "info.circle")
                                        .font(.footnote)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if !artwork.date.isEmpty {
                            Text("Date: \(artwork.date)")
                                .font(.subheadline)
                        }
                        
                        if !artwork.medium.isEmpty {
                            Text("Medium: \(artwork.medium)")
                                .font(.subheadline)
                        }
                        
                        if !artwork.movement.isEmpty {
                            Text("Movement: \(artwork.movement)")
                                .font(.subheadline)
                        }
                        
                        if let metSourceId = artwork.metSourceId {
                            Text("Met ID: \(metSourceId)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Review details
                    Group {
                        Text("Your Experience")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.bottom, 4)
                        
                        Text("Viewed on \(formattedDate(review.dateViewed))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if !review.location.isEmpty {
                            Text("Location: \(review.location)")
                                .font(.subheadline)
                        }
                        
                        if !review.reviewText.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Your notes:")
                                    .font(.headline)
                                    .padding(.top, 8)
                                
                                Text(review.reviewText)
                                    .padding()
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Artwork Review")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadArtworkDetails()
        }
        .navigationDestination(isPresented: $showArtistDetail) {
            if let artistURL = artwork?.artistWikidataURL {
                ArtistDetailView(artistUrl: artistURL)
            }
        }
    }
    
    private func loadArtworkDetails() {
        isLoading = true
        errorMessage = nil
        debugInfo = ""
        
        // First check if this is a Met artwork (has metSourceId)
        if let metSourceId = review.metSourceId {
            debugInfo += "Found metSourceId: \(metSourceId)\n"
            loadMetArtwork(metId: metSourceId)
        } else {
            // Not a Met artwork, try to load from Firestore
            debugInfo += "No metSourceId found, trying artworkId: \(review.artworkId.uuidString)\n"
            loadFirestoreArtwork()
        }
    }
    
    // Load artwork from Firestore
    private func loadFirestoreArtwork() {
        let firestoreService = FirestoreService()
        firestoreService.getArtwork(id: review.artworkId.uuidString) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let artwork):
                    self.artwork = artwork
                    self.debugInfo += "Successfully loaded artwork from Firestore\n"
                    
                case .failure(let error):
                    self.errorMessage = "Could not load artwork details"
                    self.debugInfo += "Error loading from Firestore: \(error.localizedDescription)\n"
                    
                    // Create a fallback artwork with review data
                    self.createFallbackArtwork()
                }
            }
        }
    }
    
    // Load artwork from Met database
    private func loadMetArtwork(metId: String) {
        if let metArtwork = MetCSVService.shared.getArtwork(id: metId) {
            // Convert to our app's Artwork model
            DispatchQueue.main.async {
                self.artwork = metArtwork.toArtwork()
                self.isLoading = false
                self.debugInfo += "Successfully loaded Met artwork\n"
            }
        } else {
            // Try to fetch from Met API as fallback
            MetAPIService.shared.fetchArtworkDetails(objectID: metId) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let response):
                        // Create Artwork from API response
                        self.artwork = Artwork(
                            title: response.title,
                            artist: response.artistDisplayName,
                            date: response.objectDate,
                            medium: response.medium,
                            movement: "", // API doesn't provide movement
                            metSourceId: String(response.objectID),
                            imageURL: response.primaryImage.isEmpty ? nil : response.primaryImage,
                            artistWikidataURL: response.artistWikidata_URL,
                            artistULANURL: response.artistULAN_URL
                        )
                        self.debugInfo += "Loaded Met artwork from API\n"
                        
                    case .failure(let error):
                        self.errorMessage = "Could not find artwork in Met database"
                        self.debugInfo += "Error loading from Met API: \(error.localizedDescription)\n"
                        self.createFallbackArtwork()
                    }
                }
            }
        }
    }
    
    // Create a fallback artwork when we can't load the real one
    private func createFallbackArtwork() {
        self.artwork = Artwork(
            title: "Untitled Artwork",
            artist: "Unknown Artist",
            date: "",
            medium: "",
            movement: "",
            imageURL: review.imageURL,
            artistWikidataURL: review.artistWikidataURL,
            artistULANURL: review.artistULANURL
        )
        self.debugInfo += "Created fallback artwork\n"
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
