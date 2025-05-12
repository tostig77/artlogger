//
//  FavoritesView.swift
//  artlogger
//
//  Created by Me on 5/12/25.
//


import SwiftUI

struct FavoritesView: View {
    @ObservedObject var viewModel: ArtworkViewModel

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.artworks.filter { viewModel.isFavorite($0) }) { artwork in
                    ArtworkDetailView(artwork: artwork, viewModel: viewModel)
                }
            }
            .navigationTitle("Favorite Artworks")
        }
    }
}
