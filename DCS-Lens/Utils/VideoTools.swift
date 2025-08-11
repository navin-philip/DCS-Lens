//
//  VideoTools.swift
//  SpatialPlayer
//
//  Created by Michael Swanson on 2/6/24.
//

import RealityKit
@preconcurrency import AVFoundation

@MainActor
public struct VideoTools {

  // MARK: - Scale Utility

  static func calculateScaleFactor(
    videoWidth: Float, videoHeight: Float, zDistance: Float, fovDegrees: Float
  ) -> Float {
    let fovRadians = fovDegrees * .pi / 180.0
    let halfWidthAtZDistance = zDistance * tan(fovRadians / 2.0)
    return 2.0 * halfWidthAtZDistance
  }

  // MARK: - Sphere Mesh Generator

  public static func generateVideoSphere(
    radius: Float,
    sourceHorizontalFov: Float,
    sourceVerticalFov: Float,
    clipHorizontalFov: Float,
    clipVerticalFov: Float,
    verticalSlices: Int,
    horizontalSlices: Int
  ) -> MeshResource? {

    var vertices = [SIMD3<Float>](repeating: .zero, count: (verticalSlices + 1) * (horizontalSlices + 1))
    let verticalScale = clipVerticalFov / 180.0
    let verticalOffset = (1.0 - verticalScale) / 2.0
    let horizontalScale = clipHorizontalFov / 360.0
    let horizontalOffset = (1.0 - horizontalScale) / 2.0

    for y in 0...horizontalSlices {
      let angle1 = ((.pi * Float(y) / Float(horizontalSlices)) * verticalScale) + (verticalOffset * .pi)
      let sin1 = sin(angle1)
      let cos1 = cos(angle1)

      for x in 0...verticalSlices {
        let angle2 = ((.pi * 2 * Float(x) / Float(verticalSlices)) * horizontalScale) + (horizontalOffset * .pi * 2)
        vertices[x + (y * (verticalSlices + 1))] = SIMD3<Float>(
          sin1 * cos(angle2) * radius,
          cos1 * radius,
          sin1 * sin(angle2) * radius
        )
      }
    }

    let normals = vertices.map { -normalize($0) } // Inward-facing

    // UV Mapping
    var uvCoordinates = [SIMD2<Float>](repeating: .zero, count: vertices.count)
    let uvHScale = clipHorizontalFov / sourceHorizontalFov
    let uvHOffset = (1.0 - uvHScale) / 2.0
    let uvVScale = clipVerticalFov / sourceVerticalFov
    let uvVOffset = (1.0 - uvVScale) / 2.0

    for y in 0...horizontalSlices {
      for x in 0...verticalSlices {
        var uv = SIMD2<Float>(Float(x) / Float(verticalSlices), 1.0 - Float(y) / Float(horizontalSlices))
        uv.x = uv.x * uvHScale + uvHOffset
        uv.y = uv.y * uvVScale + uvVOffset
        uvCoordinates[x + (y * (verticalSlices + 1))] = uv
      }
    }

    // Triangle indices
    var indices: [UInt32] = []
    for y in 0..<horizontalSlices {
      for x in 0..<verticalSlices {
        let i0 = UInt32(x + y * (verticalSlices + 1))
        let i1 = i0 + 1
        let i2 = i0 + UInt32(verticalSlices + 1)
        let i3 = i2 + 1

        indices.append(contentsOf: [i1, i0, i3, i3, i0, i2])
      }
    }

    var descriptor = MeshDescriptor(name: "videoSphere")
    descriptor.positions = MeshBuffer(vertices)
    descriptor.normals = MeshBuffer(normals)
    descriptor.textureCoordinates = MeshBuffer(uvCoordinates)
    descriptor.primitives = .triangles(indices)

    return try? MeshResource.generate(from: [descriptor])
  }

  // MARK: - Custom Mesh Projection

  public static func makeVideoMesh(videoPlayer: VideoPlayer) async -> (mesh: MeshResource, transform: Transform) {
    let config = Config.shared
    let resolution = videoPlayer.videoResolution

    // RECTILINEAR: 2D plane
    if (videoPlayer.projection) == "rectilinear" {
      let width: Float = 1.0
      let height = resolution.width > 0 ? (Float(resolution.height / resolution.width) * width) : width // Default to square if width is 0

      let mesh = MeshResource.generatePlane(width: width, depth: height)
      let scale = calculateScaleFactor(
        videoWidth: width,
        videoHeight: height,
        zDistance: videoPlayer.cameraDistance,
        fovDegrees: 90.0
      )

      let transform = Transform(
        scale: SIMD3<Float>(scale, 1, scale),
        rotation: simd_quatf(angle: .pi / 2, axis: [1, 0, 0]),
        translation: [0, 0, -videoPlayer.cameraDistance - 30]
      )

      return (mesh, transform)
    }

    // SPHERICAL: 360 or Fisheye
    let hFov = max(1, min(360, videoPlayer.horizontalFieldOfView))
    let vFov = max(1, min(180, videoPlayer.verticalFieldOfView))

    let horizontalSlices = max(3, Int(hFov / 3))
    let verticalSlices = max(2, Int(vFov / 3))

    guard let mesh = generateVideoSphere(
      radius: config.videoScreenSphereRadius,
      sourceHorizontalFov: hFov,
      sourceVerticalFov: vFov,
      clipHorizontalFov: hFov,
      clipVerticalFov: vFov,
      verticalSlices: verticalSlices,
      horizontalSlices: horizontalSlices
    ) else {
      fatalError("Failed to generate spherical mesh")
    }

    let transform = Transform(
      scale: .one,
      rotation: simd_quatf(angle: -.pi / 2, axis: [0, 1, 0]),
      translation: .zero
    )

    return (mesh, transform)
  }

  // MARK: - Video Metadata Parsing

  public static func getVideoDimensions(asset: AVAsset) async -> (CGSize, Float?)? {
    guard let tracks = try? await asset.load(.tracks),
          let videoTrack = tracks.first(where: { $0.mediaType == .video }) else {
      print("No video track found.")
      return nil
    }

    guard let (naturalSize, formatDescriptions) = try? await videoTrack.load(.naturalSize, .formatDescriptions),
          let formatDescription = formatDescriptions.first else {
      print("Missing format description.")
      return (videoTrack.naturalSize, nil)
    }

    guard let extensions = CMFormatDescriptionGetExtensions(formatDescription) as? [CFString: Any],
          let rawFov = extensions[kCMFormatDescriptionExtension_HorizontalFieldOfView] as? UInt32 else {
      return (naturalSize, nil) // Fallback to non-spatial if no FoV
    }

    let horizontalFov = Float(rawFov) / 1000.0
    return (naturalSize, horizontalFov)
  }
}

func parseResolution(from playlist: String) -> CGSize? {
    let pattern = #"RESOLUTION=(\d+)x(\d+)"#
    let regex = try? NSRegularExpression(pattern: pattern, options: [])

    if let match = regex?.firstMatch(in: playlist, range: NSRange(playlist.startIndex..., in: playlist)),
       let widthRange = Range(match.range(at: 1), in: playlist),
       let heightRange = Range(match.range(at: 2), in: playlist) {

        let width = Int(playlist[widthRange]) ?? 0
        let height = Int(playlist[heightRange]) ?? 0
        return CGSize(width: width, height: height)
    }

    return nil
}
