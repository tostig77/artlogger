//
//  LogNewArtworkView.swift
//  artlogger
//
//  Created by Me on 5/12/25.
//


import SwiftUI

struct LogNewArtworkView: View {
    @ObservedObject var viewModel: ArtworkViewModel

    @State private var title: String = ""
    @State private var artist: String = ""
    @State private var date: String = ""
    @State private var medium: String = ""
    @State private var movement: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Artwork Details")) {
                    TextField("Title", text: $title)
                    TextField("Artist", text: $artist)
                    TextField("Date", text: $date)
                    TextField("Medium", text: $medium)
                    TextField("Movement", text: $movement)
                }

                Button("Save Artwork") {
                    let newArtwork = Artwork(title: title, artist: artist, date: date, medium: medium, movement: movement)
                    viewModel.logNewArtwork(newArtwork)
                    clearForm()
                }
            }
            .navigationTitle("Log Artwork")
        }
    }

    private func clearForm() {
        title = ""
        artist = ""
        date = ""
        medium = ""
        movement = ""
    }
}
