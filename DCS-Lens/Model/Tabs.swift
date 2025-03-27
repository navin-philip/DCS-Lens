//
//  Tabs.swift
//  DCS-Lens
//
//  Created by Navin Mathew Philip on 27/03/25.
//



import SwiftUI

/// A description of the tabs that the app can present.
enum Tabs: Equatable, Hashable, Identifiable {
    case watchNow
    case new
    case favorites
    case library
    case search
    case collections(Category)
    
    var id: Int {
        switch self {
        case .watchNow: 2001
        case .new: 2002
        case .favorites: 2003
        case .library: 2004
        case .search: 2005
        case .collections(let category): category.id
        }
    }
    
    var name: String {
        switch self {
        case .watchNow: String(localized: "Featured", comment: "Tab title")
        case .new: String(localized: "New", comment: "Tab title")
        case .library: String(localized: "Library", comment: "Tab title")
        case .favorites: String(localized: "Favorites", comment: "Tab title")
        case .search: String(localized: "Search", comment: "Tab title")
        case .collections(_): String(localized: "Collections", comment: "Tab title")
        }
    }
    
    var customizationID: String {
        return "com.example.apple-samplecode.DestinationVideo." + self.name
    }

    var symbol: String {
        switch self {
        case .watchNow: "star.fill"
        case .new: "bell"
        case .library: "books.vertical"
        case .favorites: "heart"
        case .search: "magnifyingglass"
        case .collections(_): "list.and.film"
        }
    }
    
    var isSecondary: Bool {
        switch self {
        case .watchNow, .library, .new, .favorites, .search:
            false
        case .collections(_):
            true
        }
    }
}
