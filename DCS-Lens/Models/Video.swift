//
//  Video.swift
//  RoyalLens-DCS
//
//  Created by Navin Mathew Philip on 25/04/25.
//
import Foundation

public struct Video: Codable, Identifiable, Hashable {
    let _id: String
    let title: String
    let fileURL: String
    let streamURL: String
    let thumbnailURL: String
    let description: String
    let fov: Double?
    let primaryEye: String?
    let heroEye: String?
    let disparity: Double?
    let projection: String?
    let frameRate: Double?
    let cameraDistance: Double?
    let tags: [Tag]
    let createdAt: Date? // Optional
    let updatedAt: Date? // Optional
    let __v: Int?       // Optional
    let isFeatured: Bool? // Optional

    public var id: String { _id } // Conform to Identifiable

//    // Nested struct for tags within a video
//    struct VideoTag: Codable, Identifiable, Hashable {
//        let _id: String
//        let name: String
//        let createdAt: Date? // Optional
//        let updatedAt: Date? // Optional
//        let __v: Int?       // Optional
//
//        var id: String { _id } // Conform to Identifiable
//    }
}
