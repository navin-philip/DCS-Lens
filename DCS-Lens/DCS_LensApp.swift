//
//  DCS_LensApp.swift
//  DCS-Lens
//
//  Created by Navin Mathew Philip on 27/03/25.
//

import SwiftUI
import OpenImmersive

@main
struct DCS_LensApp: App {
  @Environment(\.openWindow) private var openWindow
  @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

  @StateObject private var contentService = ContentService()

  var body: some Scene {
      WindowGroup(id: "MainWindow") {
        DestinationTabs().environmentObject(contentService)
          .onAppear {
              contentService.loadContent(from: "https://royal-lens-test.s3.us-east-1.amazonaws.com/")
          }
      }

      ImmersiveSpace(for: StreamModel.self) { $model in
          ImmersivePlayer(selectedStream: model!) {
              Task {
                  openWindow(id: "MainWindow")
                  await dismissImmersiveSpace()
              }
          }
      }
      .immersionStyle(selection: .constant(.full), in: .full)
  }
  
}



extension StreamModel {
    /// An example StreamModel to illustrate how to load videos that stream from the web.
    @MainActor public static let sampleStream = StreamModel(
        title: "Example Stream",
        details: "Local basketball player takes a shot at sunset",
        url: URL(string: "https://stream.spatialgen.com/stream/JNVc-sA-_QxdOQNnzlZTc/index.m3u8")!,
        fallbackFieldOfView: 180.0,
        isSecurityScoped: false
    )
}
