import SwiftUI
import Firebase
import FirebaseFirestore

// User Profile Data Model
struct UserProfile {
    var username: String
    var bio: String
    
    // Default empty profile
    static let empty = UserProfile(username: "", bio: "")
}

struct ProfileView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var viewModel = ProfileViewModel()
    @State private var navigateToProfileSetup = false
    @State private var selectedArtistUrl: String? = nil
    @State private var artistImages: [String: String] = [:] // Cache for artist images: [url: imageUrl]
    
    var body: some View {
        ZStack(alignment: .top) {
            // Fixed top bar with buttons
            VStack(spacing: 0) {
                HStack {
                    // Sign Out Button (Left)
                    Button(action: {
                        session.signOut()
                    }) {
                        Text("Sign out")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(Color("MutedGreenAccent"))
                    }
                    .padding(12)
                    
                    Spacer()
                    
                    // Profile Title (Center)
                    Text("Profile")
                        .font(.custom("Georgia", size: 34))
                        .fontWeight(.bold)
                        .foregroundColor(Color(.darkGray))
                        .multilineTextAlignment(.center)
                        .padding(.top)
                        .padding(.bottom)
                    
                    Spacer()
                    
                    // Edit Button (Right)
                    Button(action: {
                        navigateToProfileSetup = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color("MutedGreenAccent"))
                    }
                    .padding(12)
                }
                .padding(.horizontal, 8)
                .background(Color(UIColor.systemBackground))
                
                Divider() // Add a line separator
            }
            .zIndex(1) // Ensure it stays on top
            
            // Scrollable content below the fixed header
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Empty space for the fixed header
                    Rectangle()
                        .frame(height: 60)
                        .opacity(0)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if let errorMessage = viewModel.errorMessage {
                        VStack {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding()
                            
                            Button("Retry") {
                                if let userId = session.user?.uid {
                                    viewModel.fetchUserProfile(userId: userId)
                                }
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        // Profile header
                        HStack(spacing: 20) {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading) {
                                if viewModel.userProfile.username.isEmpty {
                                    Text("No username set")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .italic()
                                } else {
                                    Text(viewModel.userProfile.username)
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                }
                                
                                if viewModel.userProfile.bio.isEmpty {
                                    Text("")
                                        .font(.subheadline)
                                        .italic()
                                        .foregroundColor(.secondary)
                                } else {
                                    Text(viewModel.userProfile.bio)
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Top Artists Section (simplified - no "See All")
                        VStack(alignment: .leading) {
                            Text("Top artists")
                                .font(.title2)
                                .bold()
                                .padding(.horizontal)
                            
                            if viewModel.isLoadingArtists {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .padding()
                                    Spacer()
                                }
                            } else if viewModel.topArtists.isEmpty {
                                Text("No artist data available yet")
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                // Horizontal scrolling artist circles - direct implementation
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(viewModel.topArtists, id: \.url) { artist in
                                            artistCircle(url: artist.url, count: artist.count)
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                        .padding(.top)
                        
                        // Favorite artworks
                        VStack(alignment: .leading) {
                            Text("Pinned art")
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
                        .padding(.top)
                        
                        // Most recent logs
                        VStack(alignment: .leading) {
                            Text("Logs")
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
                        .padding(.top)
                    }
                }
                .padding(.bottom)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if let userId = session.user?.uid {
                viewModel.fetchUserProfile(userId: userId)
                viewModel.fetchTopArtists(userId: userId)
            }
        }
        .sheet(isPresented: $navigateToProfileSetup) {
            // When the sheet is dismissed, refresh the profile
            if let userId = session.user?.uid {
                viewModel.fetchUserProfile(userId: userId)
            }
        } content: {
            NavigationView {
                ProfileSetupView(isNewUser: false) { _ in
                    navigateToProfileSetup = false
                }
                .environmentObject(session)
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { selectedArtistUrl != nil },
            set: { if !$0 { selectedArtistUrl = nil } }
        )) {
            if let artistUrl = selectedArtistUrl {
                ArtistDetailView(artistUrl: artistUrl)
            }
        }
    }
    
    // Direct artist circle implementation
    private func artistCircle(url: String, count: Int) -> some View {
        Button {
            selectedArtistUrl = url
        } label: {
            VStack {
                // Artist Image Circle
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .shadow(radius: 2)
                        )
                    
                    if let imageURL = artistImages[url], let url = URL(string: imageURL) {
                        // Display cached artist image
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 70, height: 70)
                                    .clipShape(Circle())
                            case .failure:
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.gray)
                            @unknown default:
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.gray)
                            }
                        }
                    } else {
                        // Show loading placeholder while fetching the image
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.gray)
                    }
                }
                .onAppear {
                    // Fetch artist image if not already cached
                    if artistImages[url] == nil {
                        ArtistInfoService.shared.getArtistImageURL(from: url) { imageURL in
                            if let imageURL = imageURL {
                                DispatchQueue.main.async {
                                    artistImages[url] = imageURL
                                }
                            }
                        }
                    }
                }
                
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Keep this structure unchanged
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
