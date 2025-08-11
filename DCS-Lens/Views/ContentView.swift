//
//  ContentView.swift
//  RoyalLens-DCS
//
//  Created by Navin Mathew Philip on 22/04/25.
//

import SwiftUI
import os

struct ContentView: View {
  @EnvironmentObject private var immersiveSpaceState: ImmersiveSpaceState
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.openImmersiveSpace) private var openImmersiveSpace
  @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

  private let logger = Logger(subsystem: "com.royal.RoyalLens", category: "RoyalLensApp")

  var body: some View {
    // Group to potentially apply modifiers to the whole conditional content
    Group {
        // Conditionally display content based on video selection
        if immersiveSpaceState.selectedVideo == nil {
          // Show TabView when no video is selected
          TabView(selection: $immersiveSpaceState.selectedTab) {
            // ... (Existing TabView content) ...
            HomeView(immersiveSpaceState: immersiveSpaceState)
              .tabItem {
                Label("Home", systemImage: "house.fill")
              }
              .tag(1)
              
            DownloadsView()
              .tabItem {
                  Label("Downloads", systemImage: "arrow.down.circle.fill")
              }
              .tag(2)
      
            EnvironmentsView()
              .environmentObject(immersiveSpaceState)
              .tabItem {
                Label("Environments", systemImage: "mountain.2")
              }
              .tag(3)
          }
          .onChange(of: scenePhase) { _, newPhase in
             // ... (Existing onChange content) ...
//             if immersiveSpaceState.selectedVideo != nil {
//                 return
//             }
             print("Background", newPhase)
             Task { @MainActor in
               if newPhase == .background {
                 await dismissImmersiveSpace()
               } else if newPhase == .active {
                 await openImmersiveSpace(id: "ImmersiveSpace")
               }
             }
          }
          .onAppear {
             // ... (Existing onAppear content) ...
             logger.info("ContentView appeared (TabView visible), isActive: \(self.immersiveSpaceState.isActive), isRequestingSpace: \(self.immersiveSpaceState.isRequestingSpace)")
       
             Task {
               // Open the immersive space when the view appears, but only if not already active
               if !immersiveSpaceState.isActive {
                 logger.info("Opening immersive space automatically")
                 if !immersiveSpaceState.isRequestingSpace {
                   do {
                     // Safely set the requesting flag
                     await MainActor.run {
                       immersiveSpaceState.isRequestingSpace = true
                     }
       
                     // Open the immersive space
                     await openImmersiveSpace(id: "ImmersiveSpace")
                     logger.info("Successfully opened immersive space")
       
                     // Reset the flag safely
                     await MainActor.run {
                       immersiveSpaceState.isRequestingSpace = false
                     }
                   }
                 } else {
                   logger.warning("Skipped opening immersive space - already requesting")
                 }
               } else {
                 logger.info("Immersive space already active, not opening")
               }
             }
          }
        } else {
          // Show EmptyView, but make it non-interactive and transparent
          EmptyView()
            .allowsHitTesting(false) // Prevent interactions
            .opacity(0) // Make fully transparent
            .onChange(of: scenePhase) { _, newPhase in
               Task { @MainActor in
                 if newPhase == .background {
                   await dismissImmersiveSpace()
                 } else if newPhase == .active {
                   await openImmersiveSpace(id: "ImmersiveSpace")
                 }
               }
            }
        }
    }
    // Apply persistentSystemOverlays conditionally to the Group
    .persistentSystemOverlays(immersiveSpaceState.selectedVideo == nil ? .visible : .hidden)
  }
}

#Preview {
  let previewState = ImmersiveSpaceState()
  let previewViewModel = HomeViewModel(immersiveSpaceState: previewState)

  return ContentView()
    .environmentObject(previewState)
    .environmentObject(previewViewModel)
    .environmentObject(DownloadManager.shared)
}
