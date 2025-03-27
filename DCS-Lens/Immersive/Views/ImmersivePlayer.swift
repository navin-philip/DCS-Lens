//
//  ImmersivePlayer.swift
//  OpenImmersive
//
//  Created by Anthony Maës (Acute Immersive) on 9/11/24.
//

import SwiftUI
import RealityKit
import AVFoundation

/// An immersive video player, complete with UI controls
public struct ImmersivePlayer: View {
    /// The singleton video player control interface.
    @State var videoPlayer: VideoPlayer = VideoPlayer()
    
    /// The object managing the sphere or half-sphere displaying the video.
    // This needs to be a @State otherwise the video doesn't load.
    @State private(set) var videoScreen = VideoScreen()
    
    /// The stream for which the player was open.
    ///
    /// The current implementation assumes only one media per appearance of the ImmersivePlayer.
    let selectedStream: StreamModel
    
    /// The callback to execute when the user closes the immersive player.
    let closeAction: (() -> Void)?
    
    /// The pose tracker ensuring the position of the control panel attachment is fixed relatively to the viewer.
    private let headTracker = HeadTracker()
    
    /// Public initializer for visibility.
    /// - Parameters:
    ///   - selectedStream: the stream for which the player will be open.
    ///   - closeAction: the callback to execute when the user closes the immersive player.
    public init(selectedStream: StreamModel, closeAction: (() -> Void)? = nil) {
        self.selectedStream = selectedStream
        self.closeAction = closeAction
    }
    
    public var body: some View {
        RealityView { content, attachments in
            let config = Config.shared
            
            // Setup root entity that will remain static relatively to the head
            let root = makeRootEntity()
            content.add(root)
            headTracker.start(content: content) { _ in
                guard let headTransform = headTracker.transform else {
                    return
                }
                let headPosition = simd_make_float3(headTransform.columns.3)
                root.position = headPosition
            }
            
            // Setup video sphere/half sphere entity
            root.addChild(videoScreen.entity)
            
            // Setup ControlPanel as a floating window within the immersive scene
            if let controlPanel = attachments.entity(for: "ControlPanel") {
                controlPanel.name = "ControlPanel"
                controlPanel.position = [0, config.controlPanelVerticalOffset, -config.controlPanelHorizontalOffset]
                controlPanel.orientation = simd_quatf(angle: -config.controlPanelTilt * .pi/180, axis: [1, 0, 0])
                root.addChild(controlPanel)
            }
            
            // Show a spinny animation when the video is buffering
            if let progressView = attachments.entity(for: "ProgressView") {
                progressView.name = "ProgressView"
                progressView.position = [0, 0, -0.7]
                root.addChild(progressView)
            }
            
            // Setup an invisible object that will catch all taps behind the control panel
            let tapCatcher = makeTapCatcher()
            root.addChild(tapCatcher)
        } update: { content, attachments in
            if let progressView = attachments.entity(for: "ProgressView") {
                progressView.isEnabled = videoPlayer.buffering
            }
        } placeholder: {
            ProgressView()
        } attachments: {
            Attachment(id: "ControlPanel") {
                ControlPanel(videoPlayer: $videoPlayer, closeAction: closeAction)
                    .animation(.easeInOut(duration: 0.3), value: videoPlayer.shouldShowControlPanel)
            }
            
            Attachment(id: "ProgressView") {
                ProgressView()
            }
        }
        .onAppear {
            videoPlayer.openStream(selectedStream)
            videoPlayer.showControlPanel()
            videoPlayer.play()
            
            videoScreen.update(source: videoPlayer)
        }
        .onDisappear {
            videoPlayer.stop()
            videoPlayer.hideControlPanel()
            headTracker.stop()
            if selectedStream.isSecurityScoped {
                selectedStream.url.stopAccessingSecurityScopedResource()
            }
        }
        .gesture(TapGesture()
            .targetedToAnyEntity()
            .onEnded { event in
                videoPlayer.toggleControlPanel()
            }
        )
    }
    
    /// Programmatically generates the root entity for the RealityView scene, and positions it at `(0, 1.2, 0)`,
    /// which is a typical position for a viewer's head while sitting on a chair.
    /// - Returns: a new root entity.
    private func makeRootEntity() -> some Entity {
        let entity = Entity()
        entity.name = "Root"
        entity.position = [0.0, 1.2, 0.0] // Origin would be the floor.
        return entity
    }
    
    /// Programmatically generates a tap catching entity in the shape of a large invisible box in front of the viewer.
    /// Taps captured by this invisible shape will toggle the control panel on and off.
    /// - Parameters:
    ///   - debug: if `true`, will make the box red for debug purposes (default false).
    /// - Returns: a new tap catcher entity.
    private func makeTapCatcher(debug: Bool = false) -> some Entity {
        let collisionShape: ShapeResource =
            .generateBox(width: 100, height: 100, depth: 1)
            .offsetBy(translation: [0.0, 0.0, -5.0])
        
        let entity = debug ?
        ModelEntity(
            mesh: MeshResource(shape: collisionShape),
            materials: [UnlitMaterial(color: .red)]
        ) : Entity()
        
        entity.name = "TapCatcher"
        entity.components.set(CollisionComponent(shapes: [collisionShape], mode: .trigger, filter: .default))
        entity.components.set(InputTargetComponent())
        
        return entity
    }
}
