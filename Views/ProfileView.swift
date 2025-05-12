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
    
    var body: some View {
        ZStack(alignment: .top) {
            // Fixed top bar with buttons
            VStack(spacing: 0) {
                HStack {
                    // Sign Out Button (Left)
                    Button(action: {
                        session.signOut()
                    }) {
                        Text("Sign Out")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                    }
                    .padding(12)
                    
                    Spacer()
                    
                    // Profile Title (Center)
                    Text("Profile")
                        .font(.title)
                        .bold()
                    
                    Spacer()
                    
                    // Edit Button (Right)
                    Button(action: {
                        navigateToProfileSetup = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.blue)
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
                                        .font(.headline)
                                        .italic()
                                } else {
                                    Text(viewModel.userProfile.username)
                                        .font(.headline)
                                }
                                
                                if viewModel.userProfile.bio.isEmpty {
                                    Text("No bio added yet.")
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
                            Text("Top Artists")
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
                                // Horizontal scrolling artist circles
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(viewModel.topArtists, id: \.url) { artist in
                                            ArtistCircleView(
                                                artistUrl: artist.url,
                                                count: artist.count
                                            )
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
                        .padding(.top)
                        
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
    }
}

// Keep these structures unchanged
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
