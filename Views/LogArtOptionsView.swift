//
//  LogArtOptionsView.swift
//  artlogger
//
//  Created by Me on 5/12/25.
//


import SwiftUI

struct LogArtOptionsView: View {
    @ObservedObject var viewModel: ArtworkViewModel
    @State private var showingManualEntry = false
    @State private var showingDatabaseSearch = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            Text("Log art")
                .font(.custom("Georgia", size: 34))
                .fontWeight(.bold)
                .foregroundColor(Color(.darkGray))
                .multilineTextAlignment(.center)
                .padding(.top)
                .padding(.bottom)
            
            Spacer()
            
            // Option buttons
            VStack(spacing: 20) {
                // Manual Entry Button
                Button(action: {
                    showingManualEntry = true
                }) {
                    VStack {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 50))
                            .padding(.bottom, 10)
                        Text("Log manually")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("MutedGreenLight"))
                    .cornerRadius(15)
                }
                
                // Database Search Button
                Button(action: {
                    showingDatabaseSearch = true
                }) {
                    VStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .padding(.bottom, 10)
                        Text("Search database")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("MutedGreenLight"))
                    .cornerRadius(15)
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .navigationTitle("Log Artwork")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button(action: {
            // Ensure any draft is cleared when closing the view
            viewModel.clearDraft()
        }) {
            Image(systemName: "xmark")
                .foregroundColor(.gray)
        })
        .navigationDestination(isPresented: $showingManualEntry) {
            ArtDetailsFormView(viewModel: viewModel)
        }
        .navigationDestination(isPresented: $showingDatabaseSearch) {
            MetDatabaseSearchView(viewModel: viewModel)
        }
    }
}
