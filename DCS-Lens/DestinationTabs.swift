//
//  DestinationTabs.swift
//  DCS-Lens
//
//  Created by Navin Mathew Philip on 27/03/25.
//



import SwiftUI
import SwiftData

/// The top level tab navigation for the app.
struct DestinationTabs: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  

    @Namespace private var namespace
    @State private var selectedTab: Tabs = .watchNow

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(Tabs.watchNow.name, systemImage: Tabs.watchNow.symbol, value: .watchNow) {
//                WatchNowView()
              FeaturedTabView()
            }
            .customizationID(Tabs.watchNow.customizationID)

            
            Tab(Tabs.library.name, systemImage: Tabs.library.symbol, value: .library) {
//                LibraryView()
              Text("Library view is intentionally blank")
            }
            .customizationID(Tabs.library.customizationID)

            
            Tab(Tabs.new.name, systemImage: Tabs.new.symbol, value: .new) {
                Text("New view is intentionally blank")
            }
            .customizationID(Tabs.new.customizationID)
            
            Tab(Tabs.favorites.name, systemImage: Tabs.favorites.symbol, value: .favorites) {
                Text("Favourites view is intentionally blank")
            }
            .customizationID(Tabs.favorites.customizationID)
            
            Tab(value: .search, role: .search) {
                Text("Search view is intentionally blank")
            }
            .customizationID(Tabs.search.customizationID)

//            TabSection {
//                ForEach(Category.collectionsList) { category in
//                    Tab(category.name, systemImage: category.icon, value: Tabs.collections(category)) {
//                        CategoryView(
//                            category: category,
//                            namespace: namespace
//                        )
//                    }
//                    .customizationID(category.customizationID)
//                }
//            } header: {
//                Label("Collections", systemImage: "folder")
//            }
//            .customizationID(Tabs.collections(.forest).name)
//
//            
//            TabSection {
//                ForEach(Category.animationsList) { category in
//                    Tab(category.name, systemImage: category.icon, value: Tabs.animations(category)) {
//                        CategoryView(
//                            category: category,
//                            namespace: namespace
//                        )
//                    }
//                    .customizationID(category.customizationID)
//                }
//            } header: {
//                Label("Animations", systemImage: "folder")
//            }
//            .customizationID(Tabs.animations(.amazing).name)
        }
        .tabViewStyle(.sidebarAdaptable)
    }

  
}

#Preview() {
    DestinationTabs()
}
