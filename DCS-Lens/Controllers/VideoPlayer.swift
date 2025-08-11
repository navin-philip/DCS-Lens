//
//  VideoPlayer.swift
//  OpenImmersive
//
//  Created by Anthony Maës (Acute Immersive) on 9/14/24.
//

import SwiftUI
import AVFoundation
import RealityFoundation

/// Video Player Controller interfacing the underlying `AVPlayer`, exposing states and controls to the UI.
// @MainActor ensures properties are published on the main thread
// which is critical for using them in SwiftUI Views
@MainActor
@Observable
public class VideoPlayer: Sendable {
  //MARK: Variables accessible to the UI
  /// The title of the current video (empty string if none).
  private(set) var title: String = ""
  /// A short description of the current video (empty string if none).
  private(set) var details: String = ""
  /// The duration in seconds of the current video (0 if none).
  private(set) var duration: Double = 0
  /// `true` if playback is currently paused, or if playback has completed.
  private(set) var paused: Bool = false
  /// `true` if playback is temporarily interrupted due to buffering.
  private(set) var buffering: Bool = false
  /// `true` if playback reached the end of the video and is no longer playing.
  private(set) var hasReachedEnd: Bool = false
  /// The aspect ratio of the current media (width / height).
  private(set) var aspectRatio: Float = 1.0
  /// The horizontal field of view for the current media
  //    private(set) var horizontalFieldOfView: Float = 180.0
  /// The vertical field of view for the current media

  /// The resolution of the current video (width, height).
  private(set) var videoResolution: CGSize = .zero

  private var videoDetails: Video?

  public var horizontalFieldOfView: Float {
    get {
      let fovValue = videoDetails?.fov ?? 180.0 
      return Float(max(0, min(360, fovValue)))
    }
  }
  public var verticalFieldOfView: Float {
    get {
      return max(0, min(180, self.horizontalFieldOfView / aspectRatio))
    }
  }

  public var projection: String {
    get {
      return videoDetails?.projection ?? "rectilinear"
    }
  }

  public var cameraDistance: Float {
    get {
      return Float(videoDetails?.cameraDistance ?? 50.0)
    }
  }

  /// The bitrate of the current video stream (0 if none).
  private(set) var bitrate: Double = 0
  /// Resolution options available for the video stream, only available if streaming from a HLS server (m3u8).
  private(set) var resolutionOptions: [ResolutionOption] = []
  /// `true` if the control panel should be visible to the user.
  private(set) var shouldShowControlPanel: Bool = true {
    didSet {
      if shouldShowControlPanel {
        restartControlPanelTask()
      }
    }
  }
  /// `true` if the control panel should present resolution options to the user.
  private(set) var shouldShowResolutionOptions: Bool = false {
    didSet {
      restartControlPanelTask()
    }
  }

  /// The current time in seconds of the current video (0 if none).
  ///
  /// This variable is updated by video playback but can be overwritten by a scrubber, in conjunction with `scrubState`.
  public var currentTime: Double = 0
  public enum ScrubState {
    /// The scrubber is not active and reflects the video's current playback time.
    case notScrubbing
    /// The scrubber is active and the user is actively dragging it.
    case scrubStarted
    /// The scrubber is no longer active, the user just stopped dragging it and video playback should resume from the indicated time.
    case scrubEnded
  }
  /// The current state of the scrubber.
  public var scrubState: ScrubState = .notScrubbing {
    didSet {
      switch scrubState {
      case .notScrubbing:
        break
      case .scrubStarted:
        cancelControlPanelTask()
        break
      case .scrubEnded:
        let seekTime = CMTime(seconds: currentTime, preferredTimescale: 1000)
        player.seek(to: seekTime) { [weak self] finished in
          guard finished else {
            return
          }
          Task { @MainActor in
            self?.scrubState = .notScrubbing
            self?.restartControlPanelTask()
          }
        }
        hasReachedEnd = false
        break
      }
    }
  }

  //MARK: Private variables
  private var timeObserver: Any?
  private var durationObserver: NSKeyValueObservation?
  private var bufferingObserver: NSKeyValueObservation?
  private var dismissControlPanelTask: Task<Void, Never>?
  private var playlistReader: PlaylistReader?

  //MARK: Immutable variables
  /// The video player
  public let player = AVPlayer()
  public let videoMaterial: VideoMaterial

  //MARK: Public methods
  /// Public initializer for visibility.
  public init(title: String = "", details: String = "", duration: Double = 0, paused: Bool = false, buffering: Bool = false, hasReachedEnd: Bool = false, bitrate: Double = 0, shouldShowControlPanel: Bool = true, currentTime: Double = 0, scrubState: VideoPlayer.ScrubState = .notScrubbing, timeObserver: Any? = nil, durationObserver: NSKeyValueObservation? = nil, bufferingObserver: NSKeyValueObservation? = nil, dismissControlPanelTask: Task<Void, Never>? = nil) {
    self.title = title
    self.details = details
    self.duration = duration
    self.paused = paused
    self.buffering = buffering
    self.hasReachedEnd = hasReachedEnd
    //        if let aspectRatio { self.aspectRatio = aspectRatio }
    //        if let horizontalFieldOfView { self.horizontalFieldOfView = horizontalFieldOfView }
    self.bitrate = bitrate
    self.shouldShowControlPanel = shouldShowControlPanel
    self.currentTime = currentTime
    self.scrubState = scrubState
    self.timeObserver = timeObserver
    self.durationObserver = durationObserver
    self.bufferingObserver = bufferingObserver
    self.dismissControlPanelTask = dismissControlPanelTask

    self.videoMaterial = VideoMaterial(avPlayer: player)
    self.videoDetails = nil
  }

  /// Instruct the UI to reveal the control panel.
  public func showControlPanel() {
    withAnimation {
      shouldShowControlPanel = true
    }
  }

  /// Instruct the UI to hide the control panel.
  public func hideControlPanel() {
    withAnimation {
      shouldShowControlPanel = false
    }
  }

  /// Instruct the UI to toggle the visibility of the control panel.
  public func toggleControlPanel() {
    withAnimation {
      shouldShowControlPanel.toggle()
    }
  }

  /// Instruct the UI to toggle the visibility of resolutions options.
  ///
  /// This will only do something if resolution options are available.
  public func toggleResolutionOptions() {
    if resolutionOptions.count > 1 {
      withAnimation {
        shouldShowResolutionOptions.toggle()
      }
    }
  }

  /// Load the indicated stream (will stop playback).
  /// - Parameters:
  ///   - stream: The model describing the stream.
  public func openStream(_ stream: StreamModel, videoDetails: Video) {
    // Clean up the AVPlayer first, avoid bad states
    stop()

    title = stream.title
    details = stream.details
    self.videoDetails = videoDetails

    let asset = AVURLAsset(url: stream.url)
    let playerItem = AVPlayerItem(asset: asset)
    playerItem.preferredPeakBitRate = 200_000_000 // 200 Mbps LFG!
    playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
    // Suggest buffering more data ahead (e.g., 60 seconds)
    // The actual amount buffered depends on system resources and network
    playerItem.preferredForwardBufferDuration = 60.0
    player.replaceCurrentItem(with: playerItem)
    scrubState = .notScrubbing
    setupObservers()
    //        MARK TODO:
    print("[VideoPlayer] getting resolution for: \(stream.url)")
            Task { [self] in
                var fetchedResolution: CGSize?

                if stream.url.pathExtension.lowercased() == "m3u8" {
                    do {
                        print("[VideoPlayer] Attempting to parse resolution from m3u8 manifest for URL: \(stream.url)")
                        let (data, response) = try await URLSession.shared.data(from: stream.url)
                        
                        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                            print("[VideoPlayer] Invalid HTTP response when fetching m3u8. Status: \((response as? HTTPURLResponse)?.statusCode ?? -1). Falling back to AVAsset.")
                            // Ensure fetchedResolution is nil so fallback to AVAsset is attempted.
                            fetchedResolution = nil 
                            return // Exit the current 'do' block, m3u8 processing stops here.
                        }

                        // If we reach here, httpResponse was valid (200 OK), so we can attempt to parse data.
                        // The 'fetchedResolution == nil' check here is redundant if the guard above has 'return'.
                        // However, keeping it doesn't harm and makes the logic explicit if 'data' might be empty or unparsable.
                        if let playlistString = String(data: data, encoding: .utf8) {
                            // parseResolution is a global function
                            if let parsedRes = parseResolution(from: playlistString) {
                                fetchedResolution = parsedRes
                                print("[VideoPlayer] Successfully parsed resolution from m3u8 manifest: \(parsedRes)")
                            } else {
                                print("[VideoPlayer] Failed to parse m3u8 manifest content, will fall back to AVAsset.")
                            }
                        } else if fetchedResolution == nil {
                            print("[VideoPlayer] Could not decode m3u8 content to String, will fall back to AVAsset.")
                        }
                    } catch {
                        print("[VideoPlayer] Error fetching or parsing m3u8 content: \(error). Falling back to AVAsset.")
                    }
                }

                // Fallback or default path for non-m3u8 or if m3u8 parsing failed/was skipped
                if fetchedResolution == nil {
                    print("[VideoPlayer] Using AVAsset to determine video dimensions for URL: \(stream.url)")
                    if let (assetResolution, _) = await VideoTools.getVideoDimensions(asset: asset) {
                        fetchedResolution = assetResolution
                        print("[VideoPlayer] Fetched resolution from AVAsset: \(assetResolution)")
                    } else {
                        print("[VideoPlayer] Failed to get video dimensions from AVAsset.")
                    }
                }

                guard let finalResolution = fetchedResolution else {
                    print("[VideoPlayer] Error: Could not determine video resolution from any source for URL: \(stream.url).")
                    return
                }

                print("[VideoPlayer] Final resolution determined for \(stream.url) is: \(finalResolution)")
                if finalResolution.width > 0 && finalResolution.height > 0 {
                    self.aspectRatio = Float(finalResolution.width) / Float(finalResolution.height)
                } else {
                    self.aspectRatio = 16.0 / 9.0 // Default to a common aspect ratio
                    print("[VideoPlayer] Warning: Video dimensions \(finalResolution) are invalid. Defaulting aspect ratio to 16/9.")
                }
                self.videoResolution = finalResolution
                print("[VideoPlayer] Video resolution set to: \(self.videoResolution)")
                print("[VideoPlayer] Aspect ratio set to: \(self.aspectRatio)")
            }

    // if streaming from HLS, attempt to retrieve the resolution options
    playlistReader = nil
    resolutionOptions = []
    if stream.url.host() != nil {
      playlistReader = PlaylistReader(url: stream.url) { reader in
        Task { @MainActor in
          if case .success = reader.state,
             reader.resolutions.count > 0 {
            self.resolutionOptions = reader.resolutions
            let defaultResolution = reader.resolutions.first!.size
            self.aspectRatio = Float(defaultResolution.width / defaultResolution.height)
          }
        }
      }
    }
  }

  /// Load the corresponding stream variant from a resolution option, preserving other states.
  /// - Parameters:
  ///   - url: the url to the stream variant.
  private func openStreamVariant(_ url: URL) {
    guard let asset = player.currentItem?.asset as? AVURLAsset else {
      // nothing is currently playing
      return
    }

    guard asset.url != url else {
      // already playing the correct url
      return
    }

    withAnimation {
      shouldShowResolutionOptions = false
    }

    // temporarily stop the observers to stop them from interfering in the state changes
    tearDownObservers()
    let playerItem = AVPlayerItem(url: url)
    player.replaceCurrentItem(with: playerItem)
    // "simulating" a scrub end will seek the current time to the right spot
    scrubState = .scrubEnded
    setupObservers()
    if !paused {
      play()
    }
  }

  /// Load the resolution option for the given index, and open the corresponding url if successful.
  /// - Parameters:
  ///   - index: the index of the resolution option, -1 for adaptive bitrate (default)
  public func openResolutionOption(index: Int = -1) {
    guard let playlistReader,
          index < resolutionOptions.count
    else {
      return
    }

    // index -1 is automatic, that is to say the original URL parsed by the playlist reader
    let selectedUrl = index < 0 ? playlistReader.url : resolutionOptions[index].url

    openStreamVariant(selectedUrl)
  }

  /// Play or unpause media playback.
  ///
  /// If playback has reached the end of the video (`hasReachedEnd` is true), play from the beginning.
  public func play() {
    if hasReachedEnd {
      player.seek(to: CMTime.zero)
    }
    player.play()
    paused = false
    hasReachedEnd = false
    restartControlPanelTask()
  }

  /// Pause media playback.
  public func pause() {
    player.pause()
    paused = true
    restartControlPanelTask()
  }

  /// Jump back 15 seconds in media playback.
  public func minus15() {
    guard let time = player.currentItem?.currentTime() else {
      return
    }
    let newTime = time - CMTime(seconds: 15.0, preferredTimescale: 1000)
    hasReachedEnd = false
    player.seek(to: newTime)
    restartControlPanelTask()
  }

  /// Jump forward 15 seconds in media playback.
  public func plus15() {
    guard let time = player.currentItem?.currentTime() else {
      return
    }
    let newTime = time + CMTime(seconds: 15.0, preferredTimescale: 1000)
    hasReachedEnd = false
    player.seek(to: newTime)
    restartControlPanelTask()
  }

  /// Stop media playback and unload the current media.
  public func stop() {
    tearDownObservers()
    player.replaceCurrentItem(with: nil)
    title = ""
    details = ""
    duration = 0
    currentTime = 0
    bitrate = 0
  }

  //MARK: Private methods
  /// Callback for the end of playback. Reveals the control panel if it was hidden.
  @objc private func onPlayReachedEnd() {
    Task { @MainActor in
      hasReachedEnd = true
      paused = true
      showControlPanel()
    }
  }

  // Observers are needed to extract the current playback time and total duration of the media
  // Tricky: the observer callback closures must capture a weak self for safety, and execute on the MainActor
  /// Set up observers to register current media duration, current playback time, current bitrate, playback end event.
  private func setupObservers() {
    if timeObserver == nil {
      let interval = CMTime(seconds: 0.1, preferredTimescale: 1000)
      timeObserver = player.addPeriodicTimeObserver(
        forInterval: interval,
        queue: .main
      ) { [weak self] time in
        Task { @MainActor in
          if let self {
            if let event = self.player.currentItem?.accessLog()?.events.last {
              self.bitrate = event.indicatedBitrate
            } else {
              self.bitrate = 0
            }

            switch self.scrubState {
            case .notScrubbing:
              self.currentTime = time.seconds
              break
            case .scrubStarted: return
            case .scrubEnded: return
            }
          }
        }
      }
    }

    if durationObserver == nil, let currentItem = player.currentItem {
      durationObserver = currentItem.observe(
        \.duration,
         options: [.new, .initial]
      ) { [weak self] item, _ in
        let duration = CMTimeGetSeconds(item.duration)
        if !duration.isNaN {
          Task { @MainActor in
            self?.duration = duration
          }
        }
      }
    }

    if bufferingObserver == nil {
      bufferingObserver = player.observe(
        \.timeControlStatus,
         options: [.new, .old, .initial]
      ) { [weak self] player, status in
        Task { @MainActor in
          self?.buffering = player.timeControlStatus == .waitingToPlayAtSpecifiedRate
          // buffering doesn't bring up the control panel but prevents auto dismiss.
          // auto dismiss after play resumed.
          if (status.oldValue, status.newValue) == (.waitingToPlayAtSpecifiedRate, .playing) {
            self?.restartControlPanelTask()
          }
        }
      }
    }

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onPlayReachedEnd),
      name: AVPlayerItem.didPlayToEndTimeNotification,
      object: player.currentItem
    )
  }

  /// Tear down observers set up in `setupObservers()`.
  private func tearDownObservers() {
    if let timeObserver {
      player.removeTimeObserver(timeObserver)
    }
    timeObserver = nil
    durationObserver?.invalidate()
    durationObserver = nil
    bufferingObserver?.invalidate()
    bufferingObserver = nil

    NotificationCenter.default.removeObserver(
      self,
      name: AVPlayerItem.didPlayToEndTimeNotification,
      object: player.currentItem
    )
  }

  /// Restarts a task with a 10-second timer to auto-hide the control panel.
  private func restartControlPanelTask() {
    cancelControlPanelTask()
    dismissControlPanelTask = Task {
      try? await Task.sleep(for: .seconds(10))
      let videoIsPlaying = !paused && !hasReachedEnd && !buffering
      if !Task.isCancelled, videoIsPlaying {
        hideControlPanel()
      }
    }
  }

  /// Cancels the current task to dismiss the control panel, if any.
  private func cancelControlPanelTask() {
    dismissControlPanelTask?.cancel()
    dismissControlPanelTask = nil
  }
}
