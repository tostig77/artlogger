//
//  ArtDetailsFormView.swift
//  artlogger
//
//  Created by Me on 5/12/25.
//


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
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Artwork Details")) {
                    TextField("Title *", text: $title)
                    TextField("Artist *", text: $artist)
                    TextField("Date", text: $date)
                    TextField("Medium", text: $medium)
                    TextField("Movement", text: $movement)
                }
                
                Section(footer: requiredFieldsNote) {
                    Button("Next") {
                        // Create draft artwork
                        viewModel.createDraftArtwork(
                            title: title,
                            artist: artist,
                            date: date,
                            medium: medium,
                            movement: movement
                        )
                        
                        // Navigate to review form
                        showingReviewForm = true
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(!isFormValid)
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
}