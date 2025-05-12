import SwiftUI

struct MetDatabaseSearchView: View {
    @ObservedObject var viewModel: ArtworkViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var searchQuery: String = ""
    @State private var showingSearchResults = false
    @State private var showingReviewForm = false
    @State private var showingDatabaseStatus = false
    
    var body: some View {
        VStack {
            // Search bar
            HStack {
                TextField("Enter search term", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onSubmit {
                        performSearch()
                    }
                
                Button(action: {
                    performSearch()
                }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color("AccentColor"))
                }
                .disabled(searchQuery.isEmpty || !viewModel.metDatabaseLoaded || viewModel.isSearching)
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Database status
            HStack {
                Button(action: {
                    showingDatabaseStatus = true
                }) {
                    Label("Database info", systemImage: "info.circle")
                        .font(.footnote)
                }
                
                Spacer()
                
                if !viewModel.metDatabaseLoaded {
                    Text("Loading database...")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.top, 5)
            
            // Search results or placeholder
            if viewModel.isSearching {
                ProgressView("Searching...")
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.searchError {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                        .padding()
                    
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !viewModel.searchResults.isEmpty {
                List {
                    ForEach(viewModel.searchResults) { artwork in
                        Button(action: {
                            selectArtwork(artwork)
                            showingReviewForm = true
                        }) {
                            HStack(spacing: 12) {
                                // Artwork thumbnail
                                ArtworkThumbnailImage(urlString: artwork.primaryImageSmall, size: 60)
                                
                                // Artwork details
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(artwork.title)
                                        .font(.headline)
                                        .lineLimit(2)
                                    
                                    if !artwork.artistDisplayName.isEmpty {
                                        Text("by \(artwork.artistDisplayName)")
                                            .font(.subheadline)
                                            .lineLimit(1)
                                    }
                                    
                                    if !artwork.objectDate.isEmpty {
                                        Text("Date: \(artwork.objectDate)")
                                            .font(.caption)
                                    }
                                    
                                    if !artwork.medium.isEmpty {
                                        Text("Medium: \(artwork.medium)")
                                            .font(.caption)
                                            .lineLimit(1)
                                    }
                                    
                                    HStack {
                                        Text(artwork.department)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                        
                                        Text("ID: \(artwork.id)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.top, 2)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            } else {
                // Placeholder when no search performed
                VStack(spacing: 20) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    
                    Text("Search for an artwork in our database")
                        .foregroundColor(.gray)
                    
        
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
        .navigationTitle("Database search")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Database status", isPresented: $showingDatabaseStatus) {
            Button("OK", role: .cancel) {}
        } message: {
            if viewModel.metDatabaseLoaded {
                Text("Our database is loaded with \(MetCSVService.shared.getArtworkCount()) artworks.")
            } else if let error = viewModel.metDatabaseLoadingError {
                Text("Failed to load database: \(error)")
            } else {
                Text("The database is still loading...")
            }
        }
        .navigationDestination(isPresented: $showingReviewForm) {
            ArtReviewFormView(viewModel: viewModel)
        }
    }
    
    private func performSearch() {
        if !searchQuery.isEmpty {
            viewModel.searchMetDatabase(query: searchQuery)
        }
    }
    
    private func selectArtwork(_ metArtwork: MetArtwork) {
        // Create draft artwork from Met selection
        viewModel.createDraftFromMetArtwork(metArtwork)
    }
}
