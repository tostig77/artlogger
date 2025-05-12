import SwiftUI

struct ArtworkDetailView: View {
    var artwork: Artwork
    @ObservedObject var viewModel: ArtworkViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Artwork image if available
            if let imageURL = artwork.imageURL, !imageURL.isEmpty {
                AsyncArtworkImage(urlString: imageURL) {
                    ZStack {
                        Color.gray.opacity(0.2)
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    }
                }
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 250)
                .cornerRadius(8)
                .padding(.bottom, 8)
            }
            
            Text(artwork.title).font(.title2)
            Text("by \(artwork.artist)").font(.subheadline)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Date: \(artwork.date)")
                Text("Medium: \(artwork.medium)")
                
                if !artwork.movement.isEmpty {
                    Text("Movement: \(artwork.movement)")
                }
                
                if let metId = artwork.metSourceId {
                    Text("Met Database ID: \(metId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            
            Spacer()

            Button(action: {
                viewModel.toggleFavorite(for: artwork)
            }) {
                Label(viewModel.isFavorite(artwork) ? "Unfavorite" : "Favorite", systemImage: "heart.fill")
                    .foregroundColor(viewModel.isFavorite(artwork) ? .red : .gray)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}
