import SwiftUI

struct ArtDetailsFormView: View {
    @ObservedObject var viewModel: ArtworkViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title: String = ""
    @State private var artist: String = ""
    @State private var date: String = ""
    @State private var medium: String = ""
    @State private var movement: String = ""
    
    @State private var showingReviewForm = false
    @State private var isLookingUpArtist = false
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Artwork Details")) {
                    TextField("Title *", text: $title)
                    
                    HStack {
                        TextField("Artist *", text: $artist)
                        if isLookingUpArtist {
                            ProgressView()
                                .frame(width: 20, height: 20)
                        }
                    }
                    
                    TextField("Date", text: $date)
                    TextField("Medium", text: $medium)
                    TextField("Movement", text: $movement)
                }
                
                Section(footer: requiredFieldsNote) {
                    Button("Next") {
                        // First try to identify the artist
                        lookupArtistAndCreateDraft()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(!isFormValid || isLookingUpArtist)
                }
            }
        }
        .navigationTitle("Artwork Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showingReviewForm) {
            ArtReviewFormView(viewModel: viewModel)
        }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty && !artist.isEmpty
    }
    
    private var requiredFieldsNote: some View {
        Text("* Required fields")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    private func lookupArtistAndCreateDraft() {
        isLookingUpArtist = true
        
        // Try to lookup artist information
        ArtistIdentificationService.shared.lookupArtistURLs(artistName: artist) { wikidataURL, ulanURL in
            // Create draft artwork with any found URLs
            viewModel.createDraftArtwork(
                title: title,
                artist: artist,
                date: date,
                medium: medium,
                movement: movement,
                artistWikidataURL: wikidataURL,
                artistULANURL: ulanURL
            )
            
            // Navigate to review form
            isLookingUpArtist = false
            showingReviewForm = true
        }
    }
}
