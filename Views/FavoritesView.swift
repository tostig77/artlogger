import SwiftUI

struct FavoritesView: View {
    @ObservedObject var viewModel: ArtworkViewModel
    @State private var selectedArtwork: Artwork? = nil

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.artworks.filter { viewModel.isFavorite($0) }) { artwork in
                    Button(action: {
                        selectedArtwork = artwork
                    }) {
                        HStack(spacing: 12) {
                            // Artwork thumbnail
                            if let imageURL = artwork.imageURL, !imageURL.isEmpty {
                                ArtworkThumbnailImage(urlString: imageURL, size: 60)
                            } else {
                                ZStack {
                                    Color.gray.opacity(0.2)
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                }
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            
                            // Artwork details
                            VStack(alignment: .leading, spacing: 4) {
                                Text(artwork.title)
                                    .font(.headline)
                                    .lineLimit(1)
                                
                                Text("by \(artwork.artist)")
                                    .font(.subheadline)
                                    .lineLimit(1)
                                
                                Text(artwork.date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .onDelete { indexSet in
                    // Handle removing from favorites
                    let favoritedArtworks = viewModel.artworks.filter { viewModel.isFavorite($0) }
                    for index in indexSet {
                        viewModel.toggleFavorite(for: favoritedArtworks[index])
                    }
                }
            }
            .navigationTitle("Favorite Artworks")
            .sheet(item: $selectedArtwork) { artwork in
                NavigationView {
                    ArtworkDetailView(artwork: artwork, viewModel: viewModel)
                        .navigationTitle("Artwork Details")
                        .navigationBarItems(trailing: Button("Close") {
                            selectedArtwork = nil
                        })
                }
            }
        }
    }
}
