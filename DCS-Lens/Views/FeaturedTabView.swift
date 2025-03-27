//
//  FeaturedTabView.swift
//  DCS-Lens
//
//  Created by Navin Mathew Philip on 28/03/25.
//

import SwiftUI
import OpenImmersive

struct FeaturedTabView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissWindow) private var dismissWindow
    @EnvironmentObject private var contentService: ContentService
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Featured Section
                if let featured = contentService.allMedia.first {
                    FeaturedCard(mediaItem: featured, onPlay: { playMedia(featured) })
                }
                
                // Recently Added Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recently Added")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 300), spacing: 16)
                    ], spacing: 16) {
                        ForEach(contentService.allMedia.dropFirst()) { item in
                            MediaCard(mediaItem: item, onPlay: { playMedia(item) })
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .padding(.horizontal)
            }
        }
    }
    
    func playMedia(_ media: MediaItem) {
        let stream = StreamModel(
            title: media.title,
            details: media.description,
            url: media.hlsUrl,
            fallbackFieldOfView: 180.0,
            isSecurityScoped: false
        )
        
        Task {
            let result = await openImmersiveSpace(value: stream)
            if result == .opened {
                dismissWindow()
            }
        }
    }
}





#Preview {
    FeaturedTabView()
        .environmentObject(ContentService())
}
