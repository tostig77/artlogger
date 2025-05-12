import SwiftUI

struct ArtistCircleView: View {
    let artistUrl: String
    let count: Int
    
    @State private var artistName: String = "Artist"
    @State private var imageURL: String? = nil
    @State private var isLoading = true
    @State private var navigateToArtistDetail = false
    
    var body: some View {
        VStack {
            Button(action: {
                navigateToArtistDetail = true
            }) {
                // Artist Image with fallback
                if let imageURL = imageURL {
                    // Ensure URL is properly URL-encoded
                    let encodedURL = imageURL
                        .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? imageURL
                    
                    // Use explicit image loading with fallback
                    if let url = URL(string: encodedURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                // Show loading placeholder
                                ZStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                    ProgressView()
                                }
                                .frame(width: 70, height: 70)
                            case .success(let image):
                                // Show loaded image
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 70, height: 70)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                            .shadow(radius: 2)
                                    )
                            case .failure:
                                // Show error placeholder
                                ZStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                    Image(systemName: "person.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(.gray)
                                }
                                .frame(width: 70, height: 70)
                            @unknown default:
                                // Fallback for future changes
                                ZStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                    Image(systemName: "person.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(.gray)
                                }
                                .frame(width: 70, height: 70)
                            }
                        }
                    } else {
                        // Fallback for invalid URL
                        defaultCircleImage
                    }
                } else {
                    // Default placeholder when no image URL is available
                    defaultCircleImage
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Artist Name
            Text(artistName)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
            
            // View Count Badge
            Text("\(count)")
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Capsule())
        }
        .onAppear {
            // Load artist name
            ArtistInfoService.shared.getArtistName(from: artistUrl) { name in
                if let name = name {
                    self.artistName = name
                }
                self.isLoading = false
            }
            
            // Try to load artist image
            ArtistInfoService.shared.getArtistImageURL(from: artistUrl) { url in
                print("Image URL for \(artistName): \(url ?? "nil")")
                self.imageURL = url
            }
        }
        .navigationDestination(isPresented: $navigateToArtistDetail) {
            ArtistDetailView(artistUrl: artistUrl)
        }
    }
    
    // Default circle image when no image is available
    private var defaultCircleImage: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 70, height: 70)
            
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundColor(.gray)
        }
        .overlay(
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .shadow(radius: 2)
        )
    }
}
