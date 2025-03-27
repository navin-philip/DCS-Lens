//
//  SpatialMediaResponse.swift
//  DCS-Lens
//
//  Created by Navin Mathew Philip on 28/03/25.
//


import Foundation

struct SpatialMediaResponse: Codable {
    let items: [SpatialMediaItem]
}

struct SpatialMediaItem: Codable {
    let id: String
    let title: String
    let description: String
    let thumbnailURL: String
    let contentURL: String
    let mediaType: String
    let duration: Double?
    let dateAdded: String
    let hlsUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case thumbnailURL = "thumbnail_url"
        case contentURL = "content_url"
        case mediaType = "media_type"
        case duration
        case dateAdded = "date_added"
        case hlsUrl = "hls_url"
    }
    
  func toMediaItem(baseUrl: String) -> MediaItem {
        let type: MediaType = mediaType.lowercased() == "video" ? .video : .photo
        let dateFormatter = ISO8601DateFormatter()
        let date = dateFormatter.date(from: dateAdded) ?? Date()
        let resolved_HlsUrl = type == .video && hlsUrl != nil ? baseUrl + hlsUrl! : ""

        return MediaItem(
            id: UUID(uuidString: id) ?? UUID(),
            title: title,
            description: description,
            thumbnailURL: URL(string: baseUrl + thumbnailURL)!,
            contentURL: URL(string: baseUrl + contentURL)!,
            mediaType: type,
            duration: duration,
            dateAdded: date,
            hlsUrl: URL(string: resolved_HlsUrl) ?? URL(string: "https://placeholder.com")!
        )
    }
} 
