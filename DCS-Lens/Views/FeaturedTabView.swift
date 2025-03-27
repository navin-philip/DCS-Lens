//
//  FeaturedTabView.swift
//  DCS-Lens
//
//  Created by Navin Mathew Philip on 28/03/25.
//

import SwiftUI

struct FeaturedTabView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissWindow) private var dismissWindow
    @EnvironmentObject private var contentService: ContentService

    @State private var fallbackFov: Int = 180

  var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Featured Section
                if let featured = contentService.allMedia.first {
                    FeaturedCard(mediaItem: featured, onPlay: { playMedia(featured) })
                }


              HStack{
                Text("Field of View (To be fetched automatically):")
                FormatPicker(fieldOfView: $fallbackFov, options: [65, 144, 180, 360])
              }
              .padding(40)
              .transition(.scale)

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
                    .padding()
                }
                .padding(.horizontal)
            }
        }
    }
    
    func playMedia(_ media: MediaItem) {
        let stream = StreamModel(
            title: media.title,
            details: media.description,
//            url: media.hlsUrl,
            url: URL(string: "https://stream.spatialgen.com/stream/JNVc-sA-_QxdOQNnzlZTc/index.m3u8")!,
            fallbackFieldOfView: Float(fallbackFov),
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


/// A field of view picker
struct FormatPicker: View {
    @Binding public var fieldOfView: Int
    public let options: [Int]

    var body: some View {
        Picker(selection: $fieldOfView) {
            ForEach(options, id: \.self) { option in
                Text("\(option)°").tag(option)
            }
        } label: {
            Text("Open as...")
        }
        .pickerStyle(.palette)
        .controlSize(.large)
        .frame(maxWidth: CGFloat(64 * options.count))
    }
}


#Preview {
    FeaturedTabView()
        .environmentObject(ContentService())
}
