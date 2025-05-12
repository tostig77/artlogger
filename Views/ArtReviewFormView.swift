import SwiftUI
import Firebase

struct ArtReviewFormView: View {
    @ObservedObject var viewModel: ArtworkViewModel
    @EnvironmentObject var session: SessionStore
    @Environment(\.presentationMode) var presentationMode
    
    @State private var dateViewed = Date()
    @State private var location = ""
    @State private var reviewText = ""
    
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Artwork details card (uneditable)
                if let artwork = viewModel.draftArtwork {
                    artworkDetailsCard(artwork)
                        .padding(.horizontal)
                }
                
                // Review form
                VStack(alignment: .leading, spacing: 20) {
                    Text("Your Experience")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    // Date viewed
                    VStack(alignment: .leading) {
                        Text("Date Viewed *")
                            .font(.headline)
                        DatePicker("", selection: $dateViewed, displayedComponents: .date)
                            .labelsHidden()
                    }
                    .padding(.horizontal)
                    
                    // Location
                    VStack(alignment: .leading) {
                        Text("Location")
                            .font(.headline)
                        TextField("e.g. The Met, New York", text: $location)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal)
                    
                    // Review
                    VStack(alignment: .leading) {
                        Text("Review")
                            .font(.headline)
                        TextEditor(text: $reviewText)
                            .frame(minHeight: 150)
                            .padding(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                    
                    // Required fields note
                    Text("* Required fields")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    // Submit button
                    Button(action: {
                        submitReview()
                    }) {
                        if viewModel.isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Submit")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .disabled(viewModel.isSaving)
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Review Artwork")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK") {
                // Go back to root view (options menu)
                navigateToRoot()
            }
        } message: {
            Text("Artwork has been logged successfully.")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func artworkDetailsCard(_ artwork: Artwork) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Artwork Details")
                .font(.title3)
                .fontWeight(.bold)
            
            Divider()
            
            Text("Title: \(artwork.title)")
                .font(.headline)
            
            Text("Artist: \(artwork.artist)")
            
            if !artwork.date.isEmpty {
                Text("Date: \(artwork.date)")
            }
            
            if !artwork.medium.isEmpty {
                Text("Medium: \(artwork.medium)")
            }
            
            if !artwork.movement.isEmpty {
                Text("Movement: \(artwork.movement)")
            }
            
            if let metId = artwork.metSourceId {
                Text("Met Database ID: \(metId)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    private func submitReview() {
        guard let artwork = viewModel.draftArtwork else { return }
        guard let userId = session.user?.uid else {
            errorMessage = "You must be logged in to submit a review"
            showingErrorAlert = true
            return
        }
        
        // Create review
        let review = ArtReview(
            artworkId: artwork.id,
            dateViewed: dateViewed,
            location: location,
            reviewText: reviewText
        )
        
        // Log the artwork with review
        viewModel.logNewArtwork(artwork, review: review, userId: userId) { success, error in
            if success {
                showingSuccessAlert = true
            } else {
                errorMessage = error ?? "An unknown error occurred"
                showingErrorAlert = true
            }
        }
    }
    
    private func navigateToRoot() {
        // This dismisses all the way back to the root of the navigation stack
        let presentation = presentationMode
        presentation.wrappedValue.dismiss()
    }
}
