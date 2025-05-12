import Foundation

struct ArtReview: Identifiable {
    let id = UUID()
    let artworkId: UUID
    var dateViewed: Date
    var location: String
    var reviewText: String
    var imageURL: String? = nil
    var artistWikidataURL: String? = nil
    var artistULANURL: String? = nil
    var metSourceId: String? = nil  // Added field for Met artworks
}
