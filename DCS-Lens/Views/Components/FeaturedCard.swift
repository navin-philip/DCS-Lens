//
//  FeaturedCard.swift
//  DCS-Lens
//
//  Created by Navin Mathew Philip on 28/03/25.
//
import SwiftUI

struct FeaturedCard: View {
    let mediaItem: MediaItem
    let onPlay: () -> Void
    
    var body: some View {
            ZStack(alignment: .bottomLeading) {
                // Background Image
                AsyncImage(url: mediaItem.thumbnailURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.5)
                                .tint(.white)
                        )
                }
                .frame(height: 400)
                .clipped()
                
                // Gradient Overlay
                LinearGradient(
                    gradient: Gradient(colors: [.black.opacity(0.4), .clear]),
                    startPoint: .bottom,
                    endPoint: .top
                )
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text(mediaItem.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(mediaItem.description)
                        .font(.body)
                        .lineLimit(2)

                  Button(action: onPlay){
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Play")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
//                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                  }.padding(.vertical, 16)
                }
                .foregroundColor(.white)
                .padding(24)
            }
    }
}
