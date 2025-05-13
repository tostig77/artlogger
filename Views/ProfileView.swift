import SwiftUI
import Firebase
import FirebaseFirestore

let pastelColors: [Color] = [
    Color(red: 0.98, green: 0.85, blue: 0.85),
    Color(red: 0.85, green: 0.93, blue: 0.98),
    Color(red: 0.90, green: 0.87, blue: 0.98),
    Color(red: 0.87, green: 0.95, blue: 0.87),
    Color(red: 1.00, green: 0.97, blue: 0.85)
]

let emojiList: [String] = ["🎨", "🖼", "🌸", "🧠", "📚", "✨", "🌿", "💡", "🎭", "🧵"]

func stableHash(_ string: String) -> Int {
    var hash = 5381
    for char in string.utf8 {
        hash = ((hash << 5) &+ hash) &+ Int(char)
    }
    return abs(hash)
}

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
    @State private var selectedReview: ArtReview? = nil
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
                    .padding(4)
                    
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
                            let hash = stableHash(viewModel.userProfile.username)
                            let emoji = emojiList[hash % emojiList.count]
                            let backgroundColor = pastelColors[hash % pastelColors.count]

                            ZStack {
                                Circle()
                                    .fill(backgroundColor)
                                    .frame(width: 80, height: 80)
                                Text(emoji)
                                    .font(.system(size: 36))
                            }
                            
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
                                // Horizontal scrolling artist circles
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
                        
                        // Artwork Logs - Vertical List
                        VStack(alignment: .leading) {
                            Text("Your logs")
                                .font(.title2)
                                .bold()
                                .padding(.horizontal)
                            
                            if viewModel.isLoadingReviews {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else if viewModel.userReviews.isEmpty {
                                Text("No artwork logs yet")
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                // Vertical list of artwork logs
                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.userReviews, id: \.id) { review in
                                        Button {
                                            selectedReview = review
                                        } label: {
                                            ArtworkLogItem(review: review)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top)
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if let userId = session.user?.uid {
                viewModel.fetchUserProfile(userId: userId)
                viewModel.fetchTopArtists(userId: userId)
                viewModel.fetchUserReviews(userId: userId)
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
        .navigationDestination(isPresented: Binding(
            get: { selectedReview != nil },
            set: { if !$0 { selectedReview = nil } }
        )) {
            if let review = selectedReview {
                ArtworkReviewDetailView(review: review)
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
                
                // Artist Name fetching and display removed (simplified)
                
               
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
