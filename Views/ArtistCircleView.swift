import SwiftUI

struct ArtistCircleView: View {
    let artistUrl: String
    let count: Int
    let providedImageURL: String?
    
    @State private var imageURL: String? = nil
    @State private var isLoading = true
    @State private var navigateToArtistDetail = false
    
    // Initialize with optional imageURL parameter
    init(artistUrl: String, count: Int, imageURL: String? = nil) {
        self.artistUrl = artistUrl
        self.count = count
        self.providedImageURL = imageURL
    }
    
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
        }
        .onAppear {
            // Load artist name
            
            
            // Use provided imageURL if available, otherwise fetch it
            if let providedImage = providedImageURL {
                self.imageURL = providedImage
            } else {
                // Try to load artist image
                ArtistInfoService.shared.getArtistImageURL(from: artistUrl) { url in
                    self.imageURL = url
                }
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
