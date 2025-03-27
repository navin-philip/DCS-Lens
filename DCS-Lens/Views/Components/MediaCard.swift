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
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(height: 40) // Fixed height for 2 lines of text
                    
                  HStack{
                    Spacer()
                    Button(action: onPlay){
                      HStack {
                          Image(systemName: "play.fill")
                          Text("Play")
                      }
                      .padding(.horizontal, 20)
                      .padding(.vertical, 10)
//                      .cornerRadius(8)
                    }.padding(.horizontal, 16)
                    Spacer()
                  }
                  .padding(8)

                }.padding(.horizontal)
            }
            .background(.ultraThinMaterial)
            .cornerRadius(16)

    }
}
