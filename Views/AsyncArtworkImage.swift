//
//  AsyncArtworkImage.swift
//  artlogger
//
//  Created by Me on 5/12/25.
//


import SwiftUI

struct AsyncArtworkImage<Placeholder: View>: View {
    private let url: URL?
    private let scale: CGFloat
    private let transaction: Transaction
    private let placeholder: () -> Placeholder
    
    init(url: URL?, scale: CGFloat = 1.0, transaction: Transaction = Transaction(), @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.scale = scale
        self.transaction = transaction
        self.placeholder = placeholder
    }
    
    init(urlString: String?, scale: CGFloat = 1, transaction: Transaction = Transaction(), @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = urlString.flatMap { URL(string: $0) }
        self.scale = scale
        self.transaction = transaction
        self.placeholder = placeholder
    }
    
    var body: some View {
        if let url = url {
            AsyncImage(url: url, scale: scale, transaction: transaction) { phase in
                switch phase {
                case .empty:
                    placeholder()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure:
                    ZStack {
                        Color.gray.opacity(0.2)
                        Image(systemName: "photo.fill")
                            .foregroundColor(.gray)
                    }
                @unknown default:
                    placeholder()
                }
            }
        } else {
            placeholder()
        }
    }
}

// A simpler version for thumbnails
struct ArtworkThumbnailImage: View {
    let urlString: String?
    var size: CGFloat = 50
    
    var body: some View {
        AsyncArtworkImage(urlString: urlString) {
            ZStack {
                Color.gray.opacity(0.2)
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
