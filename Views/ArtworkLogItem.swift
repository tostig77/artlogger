import SwiftUI
import FirebaseFirestore

struct ArtworkLogItem: View {
    let review: ArtReview
    @State private var artworkTitle: String = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            // Artwork Image
            if let imageURL = review.imageURL, !imageURL.isEmpty {
                AsyncArtworkImage(urlString: imageURL) {
                    ZStack {
                        Color.gray.opacity(0.2)
                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                    }
                }
                .aspectRatio(contentMode: .fill)
                .frame(height: 200)
                .clipped()
                .cornerRadius(8)
            } else {
                // Placeholder for artworks without images
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .cornerRadius(8)
                    
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        if !artworkTitle.isEmpty {
                            Text(artworkTitle)
                                .foregroundColor(.gray)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        } else {
                            Text("No Image")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            // Date viewed (small text below image)
            Text(formattedDate(review.dateViewed))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding(.vertical, 4)
        .onAppear {
            loadArtworkTitle()
        }
    }
    
    private func loadArtworkTitle() {
        // Try to get artwork title for a better placeholder
        let firestoreService = FirestoreService()
        
        // Check for Met artwork first
        let db = Firestore.firestore()
        db.collection("reviews").document(review.id.uuidString).getDocument { snapshot, error in
            if let data = snapshot?.data(), let metSourceId = data["metSourceId"] as? String, !metSourceId.isEmpty {
                // Look up Met artwork title
                MetCSVService.shared.loadCSV { success, _ in
                    if success, let metArtwork = MetCSVService.shared.getArtwork(id: metSourceId) {
                        DispatchQueue.main.async {
                            self.artworkTitle = metArtwork.title
                        }
                    }
                }
            } else {
                // Try to get manual artwork title
                firestoreService.getArtwork(id: review.artworkId.uuidString) { result in
                    if case .success(let artwork) = result {
                        DispatchQueue.main.async {
                            self.artworkTitle = artwork.title
                        }
                    }
                }
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
