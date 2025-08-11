//
//  Tag.swift
//  RoyalLens-DCS
//
//  Created by Navin Mathew Philip on 25/04/25.
//
import Foundation

struct Tag: Codable, Identifiable, Hashable {
    let _id: String
    let name: String
    let createdAt: Date? // Made optional as they might not always be needed
    let updatedAt: Date? // Made optional
    let __v: Int?       // Made optional

    var id: String { _id } // Conform to Identifiable
}
