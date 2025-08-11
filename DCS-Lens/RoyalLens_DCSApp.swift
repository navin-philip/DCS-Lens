//
//  RoyalLens_DCSApp.swift
//  RoyalLens-DCS
//
//  Created by Navin Mathew Philip on 22/04/25.
//

import SwiftUI
import os

@main
struct RoyalLens_DCSApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
  @StateObject private var immersiveSpaceState = ImmersiveSpaceState(isActive: false)
  @Environment(\.openWindow) private var openWindow
  @Environment(\.dismissWindow) private var dismissWindow
  
  private let logger = Logger(subsystem: "com.royal.RoyalLens", category: "RoyalLensApp")

    var body: some Scene {
        WindowGroup(id: "main-window") {
          let homeViewModel = HomeViewModel(immersiveSpaceState: immersiveSpaceState)
          ContentView()
              .environmentObject(immersiveSpaceState)
              .environmentObject(homeViewModel)
              .environmentObject(DownloadManager.shared)
        }

        .onChange(of: immersiveSpaceState.selectedVideo) { _, newVideo in
            if newVideo != nil {
                logger.info("[App] Video selected. Main window content will hide.")
            } else {
                logger.info("[App] Video closed. Main window content will reappear.")
            }
        }
        .defaultSize(width: 1400, height: 1080)
        .windowStyle(.plain)
        .persistentSystemOverlays(.hidden)


      ImmersiveSpace(id: "ImmersiveSpace") {
          ImmersiveView(brightnessValue: $immersiveSpaceState.brightness)
              .environmentObject(immersiveSpaceState)
              .onAppear {
                  DispatchQueue.main.async {
                      immersiveSpaceState.isActive = true
                  }
              }
      }
      .immersionStyle(selection: .constant(.full), in: .full)
      
    }
}
