import Foundation

struct ArtReview: Identifiable {
    let id = UUID()
    let artworkId: UUID
    var dateViewed: Date
    var location: String
    var reviewText: String
}
