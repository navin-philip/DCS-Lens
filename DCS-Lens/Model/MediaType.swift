//
//  MediaType.swift
//  DCS-Lens
//
//  Created by Navin Mathew Philip on 28/03/25.
//


import Foundation
import SwiftUI

enum MediaType {
    case photo
    case video
}

struct MediaItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let thumbnailURL: URL
    let contentURL: URL
    let mediaType: MediaType
    let duration: TimeInterval?
    let dateAdded: Date
    let hlsUrl: URL

    init(id: UUID = UUID(), 
         title: String, 
         description: String, 
         thumbnailURL: URL, 
         contentURL: URL, 
         mediaType: MediaType, 
         duration: TimeInterval? = nil, 
         dateAdded: Date = Date(), hlsUrl: URL) {
        self.id = id
        self.title = title
        self.description = description
        self.thumbnailURL = thumbnailURL
        self.contentURL = contentURL
        self.mediaType = mediaType
        self.duration = duration
        self.dateAdded = dateAdded
        self.hlsUrl = hlsUrl
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
        lhs.id == rhs.id
    }
}
