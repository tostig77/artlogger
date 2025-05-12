import SwiftUI

struct TopArtistsView: View {
    @EnvironmentObject var session: SessionStore
    @State private var topArtists: [(url: String, count: Int)] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack(alignment: .leading) {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else if topArtists.isEmpty {
                Text("No artist data available yet")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List {
                    ForEach(topArtists, id: \.url) { artist in
                        NavigationLink(destination: ArtistDetailView(artistUrl: artist.url)) {
                            // Each artist is a standalone component that loads its own data
                            HStack {
                                // We'll use ArtistCircleView to show the artist's image
                                ArtistCircleView(
                                    artistUrl: artist.url,
                                    count: artist.count
                                )
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
        .navigationTitle("Your Top Artists")
        .onAppear {
            loadTopArtists()
        }
        .refreshable {
            loadTopArtists()
        }
    }
    
    private func loadTopArtists() {
        guard let userId = session.user?.uid else {
            errorMessage = "Not logged in"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        FirestoreService().getTopArtists(userId: userId, limit: 10) { result in
            isLoading = false
            
            switch result {
            case .success(let artists):
                topArtists = artists
                if artists.isEmpty {
                    errorMessage = "No artist data available yet"
                }
            case .failure(let error):
                errorMessage = "Error loading artists: \(error.localizedDescription)"
            }
        }
    }
}
