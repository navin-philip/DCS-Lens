//
//  ContentService.swift
//  DCS-Lens
//
//  Created by Navin Mathew Philip on 28/03/25.
//


import Foundation
import Combine
import AVFoundation
import SwiftUI

class ContentService: ObservableObject {
    @Published var allMedia: [MediaItem] = []
    @Published var isLoading = false
    @Published var selectedMedia: MediaItem?
    @Published var currentPlaybackBackground: BackgroundType = .pearl
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    enum BackgroundType {
        case pearl
        case acuadome
    }
    
    deinit {
        // Remove any notification observers
        NotificationCenter.default.removeObserver(self)
    }
    
  func loadContent(from baseUrl: String? = nil) {
        isLoading = true
        errorMessage = nil
        

        let url = URL(string: baseUrl! + "catalog.json")!
    print("Loading content from: \(url)")
        // Using a short timeout for faster error detection
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        let session = URLSession(configuration: config)
        
        session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: SpatialMediaResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to load content: \(error.localizedDescription)"
                    print("Content loading error: \(error)")
                }
            } receiveValue: { [weak self] response in
                self?.processMediaResponse(response, baseUrl: baseUrl)
            }
            .store(in: &cancellables)
        
        // Failsafe - if loading takes too long, fall back to demo content
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
            guard let self = self, self.isLoading else { return }
            self.isLoading = false
            self.errorMessage = "Loading timed out. Using demo content."
        }
    }
    
    private func processMediaResponse(_ response: SpatialMediaResponse, baseUrl: String? = nil) {
        // Convert all items to MediaItem objects and add base URL to paths
        let mediaItems = response.items.map { item -> MediaItem in
          let mediaItem = item.toMediaItem(baseUrl: baseUrl!)

            return mediaItem
        }
        
        if mediaItems.isEmpty {
            errorMessage = "No media items found in response"
            return
        }
        
        // Store all media in a single array
        self.allMedia = mediaItems
        self.errorMessage = nil
    }
    
    func selectMedia(_ media: MediaItem) {
        selectedMedia = media
        
        // Switch background based on type
        if media.mediaType == .video {
            currentPlaybackBackground = .acuadome
        } else {
            currentPlaybackBackground = .pearl
        }
    }
    
    func clearSelection() {
        selectedMedia = nil
        currentPlaybackBackground = .pearl
    }
    
    // This would handle efficient video streaming with adaptive bitrate
    func prepareVideoPlayback(for mediaItem: MediaItem) -> AVPlayer? {
        // Make sure we're explicitly handling a video media type
        if mediaItem.mediaType != .video {
            print("Error: Invalid media type for video playback: \(mediaItem.mediaType)")
            return nil
        }
        
        // For demo content with placeholder URLs, create a dummy player that won't actually play
        if mediaItem.contentURL.absoluteString.contains("placeholder.com") {
            print("Using demo video player - won't actually play content")
            // This will show the player UI but won't actually load video
            return AVPlayer(playerItem: AVPlayerItem(asset: AVAsset()))
        }
        
        print("Preparing video with HLS URL: \(mediaItem.hlsUrl)")
        
        // Configure AVPlayer with adaptive streaming
        // Use mediaItem.hlsUrl if it's valid and has a proper scheme
        let assetURL: URL
//        if mediaItem.hlsUrl.scheme != nil {
//            assetURL = mediaItem.hlsUrl
//        } else {
//            // Fallback to the hardcoded URL for testing - replace with contentURL in production
//            assetURL = URL(string: "https://s3.us-east-1.amazonaws.com/ai.lumion.oggler/royallens/videos/test/input.m3u8")!
//        }
//      assetURL = URL(string: "https://royal-lens-test.s3.us-east-1.amazonaws.com/new/2/prog_index.m3u8")!
        assetURL = mediaItem.hlsUrl
        // Create asset with specific options for visionOS
        let asset = AVURLAsset(url: assetURL)
        
        // Use asset options compatible with visionOS
        let playerItem = AVPlayerItem(asset: asset)
        
        // Configure for efficient streaming with values suitable for visionOS
        playerItem.preferredForwardBufferDuration = 10.0
        
        // Add error handling for playerItem
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { notification in
            // Handle playback errors
            if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
                print("Video playback error: \(error.localizedDescription)")
            }
        }
        
        // Initialize the player
        let player = AVPlayer(playerItem: playerItem)
        
        return player
    }
}
