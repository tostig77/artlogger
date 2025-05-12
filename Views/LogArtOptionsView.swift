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
            Text("Log Artwork")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
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
                        Text("Log Manually")
                            .font(.headline)
                        Text("Enter artwork details yourself")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
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
                        Text("Search Database")
                            .font(.headline)
                        Text("Find artwork in the Met collection")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
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
