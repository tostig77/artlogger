import SwiftUI

struct ArtistDetailView: View {
    let artistUrl: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var artistDetails: ArtistInfoService.ArtistDetails?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                        Text("Loading artist information...")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(height: 200)
                } else {
                    // Artist Image - show if available, otherwise use placeholder
                    if let details = artistDetails, let imageURL = details.imageURL {
                        AsyncArtworkImage(urlString: imageURL) {
                            // Fallback for when image is loading or failed
                            ZStack {
                                Color.gray.opacity(0.2)
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray)
                            }
                        }
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    } else {
                        // Generic placeholder for artist without image
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                            
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Artist Name and Lifespan
                    VStack(alignment: .center, spacing: 8) {
                        // Show artist name (use details if available, fallback to "Artist")
                        Text(artistDetails?.name ?? "Artist")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        // Show years if available
                        if let details = artistDetails,
                           details.birthYear != "Unknown" || details.deathYear != "Unknown" {
                            Text("\(details.birthYear) - \(details.deathYear)")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        
                        // Show nationality if available
                        if let details = artistDetails,
                           details.nationality != "Unknown" {
                            Text(details.nationality)
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    
                    Divider()
                    
                    // Biography if available
                    if let details = artistDetails, !details.biography.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Biography")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            Text(details.biography)
                                .padding(.horizontal)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical)
                        
                        Divider()
                    }
                    
                    // Wikidata Source - always show
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Source")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Link(destination: URL(string: artistUrl)!) {
                            Text("View on Wikidata")
                                .underline()
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(artistDetails?.name ?? "Artist")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .onAppear {
            loadArtistDetails()
        }
    }
    
    private func loadArtistDetails() {
        isLoading = true
        
        // Get just the name first for a quick display
        ArtistInfoService.shared.getArtistName(from: artistUrl) { name in
            if let name = name {
                // Create a minimal details object with just the name
                self.artistDetails = ArtistInfoService.ArtistDetails(
                    name: name,
                    birthYear: "Unknown",
                    deathYear: "Unknown",
                    imageURL: nil,
                    movements: [],
                    nationality: "Unknown",
                    biography: ""
                )
            }
        }
        
        // Then load full details
        ArtistInfoService.shared.getArtistDetails(from: artistUrl) { details in
            isLoading = false
            
            if let details = details {
                self.artistDetails = details
            }
        }
    }
}
