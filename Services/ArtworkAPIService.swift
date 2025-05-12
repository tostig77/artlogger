//
//  ArtworkAPIService.swift
//  artlogger
//
//  Created by Me on 5/12/25.
//


import Foundation

class ArtworkAPIService {
    static func searchArtwork(byTitle title: String) -> [Artwork] {
        return sampleArtworks.filter { $0.title.lowercased().contains(title.lowercased()) }
    }
}
