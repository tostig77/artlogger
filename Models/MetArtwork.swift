import Foundation

struct MetArtwork: Identifiable {
    let id: String  // Object ID
    let objectNumber: String
    let isHighlight: Bool
    let isPublicDomain: Bool
    let department: String
    let objectName: String
    let title: String
    let culture: String
    let period: String
    let dynasty: String
    let reign: String
    let portfolio: String
    let artistRole: String
    let artistPrefix: String
    let artistDisplayName: String
    let artistDisplayBio: String
    let artistSuffix: String
    let artistAlphaSort: String
    let artistNationality: String
    let artistBeginDate: String
    let artistEndDate: String
    let objectDate: String
    let objectBeginDate: String
    let objectEndDate: String
    let medium: String
    let dimensions: String
    let creditLine: String
    let geographyType: String
    let city: String
    let state: String
    let county: String
    let country: String
    let region: String
    let subregion: String
    let locale: String
    let locus: String
    let excavation: String
    let river: String
    let classification: String
    let rightsAndReproduction: String
    let linkResource: String
    let metadataDate: String
    let repository: String
    
    // Convert to our app's Artwork model
    func toArtwork() -> Artwork {
        return Artwork(
            title: title,
            artist: artistDisplayName,
            date: objectDate,
            medium: medium,
            movement: "", // Not using movement for Met artworks
            metSourceId: id
        )
    }
}
