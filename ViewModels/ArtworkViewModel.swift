//
//  ArtworkViewModel.swift
//  artlogger
//
//  Created by Me on 5/12/25.
//


import Foundation

class ArtworkViewModel: ObservableObject {
    @Published var artworks: [Artwork] = sampleArtworks
    @Published var user: User = sampleUser

    func logNewArtwork(_ artwork: Artwork) {
        artworks.append(artwork)
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
}
