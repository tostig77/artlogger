//
//  ArtworkDetailView.swift
//  artlogger
//
//  Created by Me on 5/12/25.
//


import SwiftUI

struct ArtworkDetailView: View {
    var artwork: Artwork
    @ObservedObject var viewModel: ArtworkViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(artwork.title).font(.title2)
            Text("by \(artwork.artist)").font(.subheadline)
            Text("Date: \(artwork.date)")
            Text("Medium: \(artwork.medium)")
            Text("Movement: \(artwork.movement)")

            Button(action: {
                viewModel.toggleFavorite(for: artwork)
            }) {
                Label(viewModel.isFavorite(artwork) ? "Unfavorite" : "Favorite", systemImage: "heart.fill")
                    .foregroundColor(viewModel.isFavorite(artwork) ? .red : .gray)
            }
        }
        .padding()
    }
}
