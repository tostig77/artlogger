import Foundation

struct Artwork: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var artist: String
    var date: String
    var medium: String
    var movement: String
}
