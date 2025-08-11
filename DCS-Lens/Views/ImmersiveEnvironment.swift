//
//  SphereEnvironment.swift
//  RoyalLens-DCS
//
//  Created by Navin Mathew Philip on 22/04/25.
//


import SwiftUI
import RealityKit
import Combine

// Simple environment manager for 360° spherical environments
class SphereEnvironment {
  static let shared = SphereEnvironment()

  // Store the content for adding entities
  var content: RealityKit.RealityViewContent?

  // Initialize with content entity
  func initialize(with content: RealityKit.RealityViewContent) {
    self.content = content
  }

  // Core method for creating immersive environments
  func createImmersivePicture(environment: DownloadedEnvironment, brightness: Float = 1.0) -> Entity {
    let modelEntity = Entity()

    // Set a name based on the image used to help with identification
    modelEntity.name = environment.name

    if let texture = try? TextureResource.load(contentsOf: environment.dayImage) {
      var material = UnlitMaterial()
      material.color = .init(texture: .init(texture))

      // Apply brightness to the material
      material.color.tint = .init(red: CGFloat(brightness), green: CGFloat(brightness), blue: CGFloat(brightness), alpha: 1.0)

      modelEntity.components.set(ModelComponent(mesh: .generateSphere(radius: 1E3), materials: [material]))

      // Apply transformations:
      // 1. Scale to make the texture display on the inside of the sphere
      modelEntity.scale = .init(x: -1, y: 1, z: 1)

      // 2. Rotate the sphere to face the camera
      let rotationAngle: Float = degreesToRadians(85.0)
      let rotation = simd_quatf(angle: rotationAngle, axis: SIMD3<Float>(0, 1, 0)) // Y-axis rotation
      modelEntity.transform.rotation = rotation

      // 3. Apply translation
      modelEntity.transform.translation += SIMD3<Float>(0.0, 1.0, 0.0)
    } else {
      var material = UnlitMaterial()
      material.color = .init(tint: .init(red: CGFloat(brightness), green: CGFloat(brightness), blue: CGFloat(brightness), alpha: 1.0))
      modelEntity.components.set(ModelComponent(mesh: .generateSphere(radius: 1E3), materials: [material]))

      // Apply the same transformations to the fallback sphere
      modelEntity.scale = .init(x: -1, y: 1, z: 1)

      let rotationAngle: Float = degreesToRadians(0)
      let rotation = simd_quatf(angle: rotationAngle, axis: SIMD3<Float>(0, 1, 0)) // Y-axis rotation
      modelEntity.transform.rotation = rotation

      modelEntity.transform.translation += SIMD3<Float>(0.0, 1.0, 0.0)
    }

    return modelEntity
  }

  func createImmersivePicture(imageName: String, brightness: Float = 1.0) -> Entity {
    let modelEntity = Entity()

    // Set a name based on the image used to help with identification
    modelEntity.name = imageName

    if let texture = try? TextureResource.load(named: imageName) {
      var material = UnlitMaterial()
      material.color = .init(texture: .init(texture))

      // Apply brightness to the material
      material.color.tint = .init(red: CGFloat(brightness), green: CGFloat(brightness), blue: CGFloat(brightness), alpha: 1.0)

      modelEntity.components.set(ModelComponent(mesh: .generateSphere(radius: 1E3), materials: [material]))

      // Apply transformations:
      // 1. Scale to make the texture display on the inside of the sphere
      modelEntity.scale = .init(x: -1, y: 1, z: 1)

      // 2. Rotate the sphere to face the camera
      let rotationAngle: Float = degreesToRadians(85.0)
      let rotation = simd_quatf(angle: rotationAngle, axis: SIMD3<Float>(0, 1, 0)) // Y-axis rotation
      modelEntity.transform.rotation = rotation

      // 3. Apply translation
      modelEntity.transform.translation += SIMD3<Float>(0.0, 1.0, 0.0)
    } else {
      var material = UnlitMaterial()
      material.color = .init(tint: .init(red: CGFloat(brightness), green: CGFloat(brightness), blue: CGFloat(brightness), alpha: 1.0))
      modelEntity.components.set(ModelComponent(mesh: .generateSphere(radius: 1E3), materials: [material]))

      // Apply the same transformations to the fallback sphere
      modelEntity.scale = .init(x: -1, y: 1, z: 1)

      let rotationAngle: Float = degreesToRadians(0)
      let rotation = simd_quatf(angle: rotationAngle, axis: SIMD3<Float>(0, 1, 0)) // Y-axis rotation
      modelEntity.transform.rotation = rotation

      modelEntity.transform.translation += SIMD3<Float>(0.0, 1.0, 0.0)
    }

    return modelEntity
  }

  func degreesToRadians(_ degrees: Float) -> Float {
    return degrees * .pi / 180
  }
  // Update the brightness of the current environment
  func updateBrightness(brightness: Float) {
//    guard let content = self.content else { return }
//
//    // Get the current environment
//    if content.entities.isEmpty {
//      return
//    }

    // Use a default environment if detection fails
//    var environmentName = "ICON_PEARL"

//    // Try to identify the current environment from the first entity
//    if let firstEntity = content.entities.first {
//      if firstEntity.name.contains("ACUADOME") {
//        environmentName = "ICON_ACUADOME"
//      } else if firstEntity.name.contains("PEARL") {
//        environmentName = "ICON_PEARL"
//      }
//    }

    // Replace the entity with updated brightness
//    content.entities.removeAll()
//    content.add(createImmersivePicture(imageName: environmentName, brightness: brightness))
  }
}

// Method to update the material of an existing environment entity
func updateImmersivePictureMaterial(entity: Entity, environment: DownloadedEnvironment?, brightness: Float, useNightImage: Bool) {
    guard var modelComponent = entity.components[ModelComponent.self] else {
        print("[SphereEnvironment] Error: Entity missing ModelComponent.")
        return
    }

    var texture: TextureResource? = nil
    var textureLoadFailed = false

    // Determine which image URL/name to use
    if let env = environment {
        let imageUrl = useNightImage ? env.nightImage : env.dayImage
        if let url = imageUrl, url.isFileURL { // Check if URL is valid and local
            do {
                texture = try TextureResource.load(contentsOf: url)
                print("[SphereEnvironment] Loaded texture from URL: \(url.lastPathComponent)")
            } catch {
                print("[SphereEnvironment] Error loading texture from URL \(url.path): \(error)")
                textureLoadFailed = true
            }
        } else {
             print("[SphereEnvironment] Warning: Invalid or missing image URL for environment \(env.name). UseNightImage: \(useNightImage)")
             textureLoadFailed = true
        }
    } else {
        // Fallback to default (e.g., Pearl) if no environment selected
        // Assuming day/night doesn't apply to default built-in images
        let defaultImageName = "ICON_PEARL"
        do {
            texture = try TextureResource.load(named: defaultImageName)
            print("[SphereEnvironment] Loaded default texture: \(defaultImageName)")
        } catch {
             print("[SphereEnvironment] Error loading default texture \(defaultImageName): \(error)")
             textureLoadFailed = true
        }
    }

    // Create a new material if needed
    var material = UnlitMaterial()
    
    // Update material properties
    if let loadedTexture = texture, !textureLoadFailed {
        material.color = .init(texture: .init(loadedTexture))
    } else {
        // Fallback to tint if texture failed to load
        material.color = .init(tint: .white) // Base tint white
    }
    // Apply brightness tint regardless of texture
    material.color.tint = .init(red: CGFloat(brightness), green: CGFloat(brightness), blue: CGFloat(brightness), alpha: 1.0)

    // Apply the updated material back to the component
    modelComponent.materials = [material]
    entity.components.set(modelComponent)
    print("[SphereEnvironment] Updated material for entity \(entity.name ?? "unnamed"). Brightness: \(brightness), UseNight: \(useNightImage)")
}

// Animation controller for smooth brightness transitions
class BrightnessAnimator: ObservableObject {
  @Published private(set) var isAnimating: Bool = false

  private var displayLink: CADisplayLink?
  private var startValue: Float = 0
  private var endValue: Float = 0
  private var currentValue: Float = 0
  private var duration: TimeInterval = 1.0
  private var startTime: CFTimeInterval = 0
  private var completion: ((Float) -> Void)?
  private var completionCallback: (() -> Void)?

  // Handle deinitialization properly
  deinit {
    displayLink?.invalidate()
  }

  func animateBrightness(from start: Float, to end: Float, duration: TimeInterval,
                         update: @escaping (Float) -> Void,
                         completion: (() -> Void)? = nil) {
    // Cancel any existing animation
    displayLink?.invalidate()

    startValue = start
    endValue = end
    currentValue = start
    self.duration = duration
    self.completion = update
    self.completionCallback = completion

    // Update the published property
    isAnimating = true

    // Use CADisplayLink for smoother animations that sync with display refresh
    let displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
    displayLink.preferredFramesPerSecond = 120 // Target high refresh rate for smoothness
    startTime = CACurrentMediaTime()

    // Add to RunLoop to begin animation
    displayLink.add(to: .main, forMode: .common)
    self.displayLink = displayLink
  }

  @objc private func handleDisplayLink(_ displayLink: CADisplayLink) {
    let currentTime = CACurrentMediaTime()
    let elapsedTime = currentTime - startTime
    let progress = min(elapsedTime / duration, 1.0)

    // Use a more refined cubic easing function
    let easedProgress = cubicEaseInOut(progress)

    // Calculate the current value
    currentValue = startValue + Float(easedProgress) * (endValue - startValue)

    // Update the brightness
    DispatchQueue.main.async {
      self.completion?(self.currentValue)
    }

    // Check if animation is complete
    if progress >= 1.0 {
      displayLink.invalidate()
      self.displayLink = nil
      self.isAnimating = false
      self.completionCallback?()
    }
  }

  // Enhanced cubic easeInOut function for smoother transitions
  private func cubicEaseInOut(_ x: Double) -> Double {
    return x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2
  }

  func cancel() {
    displayLink?.invalidate()
    displayLink = nil
    isAnimating = false
  }
}

struct ImmersiveView: View {
  // Remove hardcoded streamModel
  // var streamModel: StreamModel = StreamModel(title: "Hello", details: "Testing details", url:  URL(string: "https://stream.spatialgen.com/stream/JNVc-sA-_QxdOQNnzlZTc/index.m3u8")!, fallbackFieldOfView: 100.0)
  @EnvironmentObject private var immersiveSpaceState: ImmersiveSpaceState
  @Binding var brightnessValue: Float

  // Create a state object for the brightness animator
  @StateObject private var animator = BrightnessAnimator()

  // Track previous environment to detect changes
  @State private var previousEnvironment: String = ""
  
  // Flag to track initial environment load
  @State private var isInitialLoad: Bool = true
  
  // Flag to track night mode
  @State private var isNightMode: Bool = false

  var body: some View {
    ZStack {
      RealityView { content in
        // Initial setup - ensure a default environment is selected if none exists
        if immersiveSpaceState.selectedEnvironment == nil {
          // Try to load the default Pearl environment from DefaultResources
          if let defaultImageURL = Bundle.main.url(forResource: "ICON-PEARL", withExtension: "jpg") {
            // Create a default environment object
            let defaultEnvironment = DownloadedEnvironment(name: "ICON - PEARL", dayImage: defaultImageURL, nightImage: nil)
            // Set it as the selected environment in the state
            immersiveSpaceState.selectedEnvironment = defaultEnvironment
          } else {
            print("[ImmersiveView] ERROR: Could not load default ICON-PEARL.jpg from DefaultResources. Check file inclusion and path.")
          }
        }

        // Now, add the environment to the scene
        // This uses the selectedEnvironment, which is either the one previously set or the default one we just loaded.
        if let currentEnv = immersiveSpaceState.selectedEnvironment {
           content.add(SphereEnvironment.shared.createImmersivePicture(environment: currentEnv, brightness: brightnessValue))
        } else {
           // Fallback if even the default loading failed - add a simple colored sphere
           print("[ImmersiveView] Fallback: Adding a simple grey sphere as no environment could be loaded.")
           var material = UnlitMaterial(color: .gray)
           let fallbackEntity = Entity()
           fallbackEntity.components.set(ModelComponent(mesh: .generateSphere(radius: 1E3), materials: [material]))
           fallbackEntity.scale = .init(x: -1, y: 1, z: 1) // Make it visible from inside
           content.add(fallbackEntity)
        }

        // Store a reference to content in SphereEnvironment
        SphereEnvironment.shared.initialize(with: content)

      }
      .onChange(of: brightnessValue) { _, newValue in
        // Only update directly if not in a transition
        if !immersiveSpaceState.isTransitioning {
          SphereEnvironment.shared.updateBrightness(brightness: newValue)
        }
      }

      .onChange(of: immersiveSpaceState.selectedEnvironment) { _, newEnvironment in
        if newEnvironment != nil {
          startTransition(to: newEnvironment)
        }
      }
      
      .onChange(of: immersiveSpaceState.selectedVideo) { _, newVideo in
        if newVideo != nil {
          // Switch to night mode when video starts
          isNightMode = true
          if let environment = immersiveSpaceState.selectedEnvironment {
            updateEnvironmentMaterial(environment: environment, useNightImage: true)
          }
        } else {
          // Switch back to day mode when video ends
          isNightMode = false
          if let environment = immersiveSpaceState.selectedEnvironment {
            updateEnvironmentMaterial(environment: environment, useNightImage: false)
          }
        }
      }
//      .onAppear {
//        // Set the animator reference in the shared state
//        immersiveSpaceState.setAnimator(animator)
//        // Initialize the previous environment
//        previousEnvironment = immersiveSpaceState.currentEnvironment
//        // Mark that initial load has been handled
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//          isInitialLoad = false
//        }
//      }
      .edgesIgnoringSafeArea(.all)
      
      // Conditionally display ImmersivePlayer based on selectedVideo
      if let selectedVideo = immersiveSpaceState.selectedVideo {
          
          // Determine the URL to play first
          let urlToPlay: URL? = {
              let downloadManager = DownloadManager.shared
              if let localURL = downloadManager.getLocalURL(for: selectedVideo.id) {
                  print("[ImmersiveView] Using local video: \(localURL.path)")
                  return localURL
              } else if let streamURL = URL(string: selectedVideo.streamURL) {
                  print("[ImmersiveView] Using streamed video: \(streamURL)")
                  return streamURL
              } else {
                  print("[ImmersiveView] Error: No valid local or stream URL for video \(selectedVideo.id)")
                  return nil
              }
          }()
          
          // Now, conditionally return the View based on the determined URL
          if let finalURL = urlToPlay {
              let streamModel = StreamModel(
                  title: selectedVideo.title,
                  details: selectedVideo.description,
                  url: finalURL,
                  // Provide default FOV if optional value is nil
                  fallbackFieldOfView: Float(selectedVideo.fov ?? 180.0)
              )
              ImmersivePlayer(
                  selectedStream: streamModel,
                  videoDetails: selectedVideo,
                  closeAction: immersiveSpaceState.closeVideoPlayer
              )
          } else {
              // Error View
              Text("Error: Invalid stream or local URL for \(selectedVideo.title)")
                  .foregroundColor(.red)
                  .padding()
                  .background(Color.black.opacity(0.7))
                  .cornerRadius(10)
                  // Center the error message in the view
                  .frame(maxWidth: .infinity, maxHeight: .infinity)
          }
      }
    }
  }

  // Helper function to start transition to new environment
  private func startTransition(to newEnvironment: DownloadedEnvironment?) {
    guard let environment = newEnvironment else { return }
    if immersiveSpaceState.isTransitioning { return }

    immersiveSpaceState.isTransitioning = true

    // Animate brightness to minimum using our custom animator
    animator.animateBrightness(
      from: brightnessValue,
      to: 0.2,
      duration: 0.5, // Slightly longer duration for smoother feel
      update: { value in
        // Update the visual brightness during animation
        SphereEnvironment.shared.updateBrightness(brightness: value)
      },
      completion: {
        // This is the only place we should call switchEnvironment
        switchEnvironment(to: environment)
      }
    )
  }

  // Switch environment when brightness reaches minimum
  private func switchEnvironment(to newEnvironment: DownloadedEnvironment) {
    if let content = SphereEnvironment.shared.content {
      content.entities.removeAll()
      
      content.add(SphereEnvironment.shared.createImmersivePicture(environment: newEnvironment, brightness: brightnessValue))

      // Use DispatchQueue to ensure a small delay before animating back up
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { // Reduced delay for better continuity
        // Animate brightness back up using our custom animator
        animator.animateBrightness(
          from: 0.2,
          to: brightnessValue,
          duration: 0.5, // Slightly longer duration for smoother feel
          update: { value in
            SphereEnvironment.shared.updateBrightness(brightness: value)
          },
          completion: {
            // Reset transition states after animation completes
            immersiveSpaceState.isTransitioning = false
          }
        )
      }
    } else {
      // If no content, reset states
      immersiveSpaceState.isTransitioning = false
    }
  }

  // Helper function to update environment material
  private func updateEnvironmentMaterial(environment: DownloadedEnvironment, useNightImage: Bool) {
    if let content = SphereEnvironment.shared.content {
      if let entity = content.entities.first {
        // Check if night image is available and we want to use it
        if useNightImage && environment.nightImage == nil {
          // If no night image available, just adjust brightness to 20%
          updateImmersivePictureMaterial(entity: entity, environment: environment, brightness: 0.2, useNightImage: false)
        } else {
          // Otherwise proceed with normal day/night switching
          updateImmersivePictureMaterial(entity: entity, environment: environment, brightness: brightnessValue, useNightImage: useNightImage)
        }
      }
    }
  }
}

class ImmersiveSpaceState: ObservableObject {
  @Published var brightness: Float
  @Published var isActive: Bool
  @Published var currentEnvironment: String
  @Published var selectedEnvironment: DownloadedEnvironment?
  @Published var selectedVideo: Video? = nil
  @Published var selectedTab: Int = 0
  @Published var selectedCategoryId: String = Category.all.id
  @Published var isTransitioning: Bool = false
  @Published var isRequestingSpace: Bool = false

  // Reference to the animator for coordinating animations
  private var animator: BrightnessAnimator?

  init(brightness: Float = 0.8, isActive: Bool = false, currentEnvironment: String = "Pearl") {
    self.brightness = brightness
    self.isActive = isActive
    self.currentEnvironment = currentEnvironment
    self.selectedTab = 0
    self.selectedCategoryId = Category.all.id
  }

  func setAnimator(_ animator: BrightnessAnimator) {
    self.animator = animator
  }

  func switchEnvironment(to newEnvironment: String) {
    if isTransitioning || currentEnvironment == newEnvironment { return }

    // The actual environment switching happens in ImmersiveView through binding updates
    self.currentEnvironment = newEnvironment
  }
  
  // Function to clear the selected video, effectively closing the player
  func closeVideoPlayer() {
      selectedVideo = nil
      print("[ImmersiveSpaceState] Video player closed.")
  }
}
