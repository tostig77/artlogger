//
//  FriendActivityView.swift
//  artlogger
//
//  Created by Me on 5/12/25.
//


import SwiftUI

struct FriendActivityView: View {
    var body: some View {
        NavigationView {
            List {
                Text("John logged Starry Night.")
                Text("Mary favorited The Persistence of Memory.")
            }
            .navigationTitle("Friend Activity")
        }
    }
}
