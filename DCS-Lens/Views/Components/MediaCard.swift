//
//  MediaCard.swift
//  DCS-Lens
//
//  Created by Navin Mathew Philip on 28/03/25.
//

import SwiftUI

struct MediaCard: View {
    let mediaItem: MediaItem
    let onPlay: () -> Void
    
    var body: some View {

            VStack(alignment: .leading, spacing: 12) {
                // Thumbnail
                AsyncImage(url: mediaItem.thumbnailURL) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                        .overlay(
                            Button(action: onPlay) {
                                Image(systemName: "play.fill")
                                  .font(.largeTitle)
                                  .foregroundColor(.white)
                                  .padding(12)
                                  .background(Color.black.opacity(0.6))
                                  .clipShape(Circle())
                            }.buttonStyle(.plain)
                              .opacity(0.8)
                        )
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.5)
                                .tint(.white)
                        )
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mediaItem.title)
                        .font(.headline)
                    
                    Text(mediaItem.description)
                      .multilineTextAlignment(.leading)
                      .font(.subheadline)
                      .foregroundColor(.secondary)
                      .lineLimit(2)
                      .frame(height: 40, alignment: .top)

                }.padding()
            }
            .background(.ultraThinMaterial)
            .cornerRadius(16)

    }
}
