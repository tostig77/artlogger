import SwiftUI

struct ProfileView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Back button
                Button(action: {}) {
                    Text("Back")
                        .font(.headline)
                        .padding(.horizontal)
                }
                
                Text("Profile")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center)
                
                // Profile header
                HStack(spacing: 20) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading) {
                        Text("John Doe @john_doe")
                            .font(.headline)
                        Text("This is a short bio about the user.")
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal)
                
                // Favorite artists
                VStack(alignment: .leading) {
                    Text("Favorite artists:")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(["Artist 1", "Artist 2", "Artist 3"], id: \.self) { artist in
                                ArtistThumbnail(artistName: artist)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Favorite artworks
                VStack(alignment: .leading) {
                    Text("Favorite artworks:")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(["Artwork 1", "Artwork 2", "Artwork 3"], id: \.self) { artwork in
                                ArtworkThumbnail(artwork: artwork)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Most recent logs
                VStack(alignment: .leading) {
                    Text("Most recent logs:")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(["Log 1", "Log 2", "Log 3"], id: \.self) { log in
                                ArtworkThumbnail(artwork: log)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationBarHidden(true)
    }
}

struct ArtistThumbnail: View {
    var artistName: String
    
    var body: some View {
        VStack {
            Image(systemName: "paintbrush")
                .resizable()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            Text(artistName)
                .font(.footnote)
                .frame(maxWidth: 70)
        }
    }
}

struct ArtworkThumbnail: View {
    var artwork: String
    
    var body: some View {
        VStack {
            Image(systemName: "photo")
                .resizable()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            Text(artwork)
                .font(.footnote)
                .frame(maxWidth: 70)
        }
    }
}

