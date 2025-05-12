import Foundation

struct Artwork: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var artist: String
    var date: String
    var medium: String
    var movement: String
    var metSourceId: String? = nil // Reference to Met database if applicable
    var imageURL: String? = nil // URL for artwork image
    var artistWikidataURL: String? = nil // Artist's Wikidata URL
    var artistULANURL: String? = nil // Artist's ULAN URL
}
