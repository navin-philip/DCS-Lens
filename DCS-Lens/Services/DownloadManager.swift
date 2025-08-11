import Foundation
import Combine
import SwiftUI // For @Published

@MainActor
class DownloadManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    static let shared = DownloadManager()
    
    // Dictionary to hold download info, mapping Video ID to DownloadInfo
    @Published private(set) var downloads: [String: DownloadInfo] = [:]
    
    private var session: URLSession!
    private let persistenceKey = "videoDownloadsInfo"
    private let fileManager = FileManager.default
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private override init() {
        super.init()
        // Configure URLSession
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.royal.RoyalLens.backgroundDownloads")
        configuration.isDiscretionary = false // Allow downloads even on cellular, etc. (adjust as needed)
        configuration.sessionSendsLaunchEvents = true
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil) // Use OperationQueue.main if immediate UI updates needed from delegate
        
        loadDownloads()
        print("[DownloadManager] Initialized. Loaded \(downloads.count) download records.")
        
        // Resume any interrupted downloads (optional, needs more state tracking)
        Task { 
            await resumeInterruptedDownloads()
        }
    }
    
    // MARK: - Persistence
    
    private func loadDownloads() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey) else { return }
        do {
            // Decode only the persistent parts
            let decoded = try JSONDecoder().decode([String: DownloadInfo].self, from: data)
            // Restore transient state (like setting status to .notDownloaded if it was .downloading)
            downloads = decoded.mapValues { info in
                var mutableInfo = info
                if case .downloading = mutableInfo.status {
                    mutableInfo.status = .notDownloaded // Assume interrupted
                }
                if case .failed = mutableInfo.status {
                    mutableInfo.status = .notDownloaded // Allow retry
                }
                // Verify file existence for .downloaded status
                if case .downloaded(let path) = mutableInfo.status {
                     let localURL = documentsDirectory.appendingPathComponent(path)
                     if !fileManager.fileExists(atPath: localURL.path) {
                         print("[DownloadManager] File missing for downloaded video \(info.videoId), resetting status.")
                         mutableInfo.status = .notDownloaded
                         mutableInfo.localPath = nil
                     }
                }
                return mutableInfo
            }
        } catch {
            print("[DownloadManager] Error loading download info: \(error)")
        }
    }
    
    private func saveDownloads() {
        do {
            // Encode only persistent parts
            let encodableDownloads = downloads.mapValues { info -> DownloadInfo in
                var persistentInfo = info
                persistentInfo.downloadTask = nil // Don't save task
                persistentInfo.progressObserver = nil // Don't save observer
                if case .downloading = persistentInfo.status {
                    persistentInfo.status = .notDownloaded // Save as interrupted
                } else if case .failed = persistentInfo.status {
                     persistentInfo.status = .notDownloaded // Allow retry
                }
                return persistentInfo
            }
            let data = try JSONEncoder().encode(encodableDownloads)
            UserDefaults.standard.set(data, forKey: persistenceKey)
            print("[DownloadManager] Saved \(downloads.count) download records.")
        } catch {
            print("[DownloadManager] Error saving download info: \(error)")
        }
    }
    
    // MARK: - Public Methods
    
    func getStatus(for videoId: String) -> DownloadStatus {
        return downloads[videoId]?.status ?? .notDownloaded
    }
    
    func getLocalURL(for videoId: String) -> URL? {
        guard let info = downloads[videoId], case .downloaded(let path) = info.status else {
            return nil
        }
        return documentsDirectory.appendingPathComponent(path)
    }
    
    func startDownload(for video: Video) {
        // Ensure fileURL is used for downloading
        guard let url = URL(string: video.fileURL) else { 
            print("[DownloadManager] Invalid fileURL for video \(video.id): \(video.fileURL)")
            updateStatus(for: video.id, status: .failed(error: "Invalid file URL"))
            return
        }
        
        // Check if already downloaded or downloading
        if let existingInfo = downloads[video.id] {
            if case .downloaded = existingInfo.status { 
                print("[DownloadManager] Video \(video.id) already downloaded.")
                return
            }
            if case .downloading = existingInfo.status {
                 print("[DownloadManager] Video \(video.id) already downloading.")
                 return
            }
        }
        
        print("[DownloadManager] Starting download for video \(video.id) from \(url)")
        let downloadTask = session.downloadTask(with: url)
        downloadTask.taskDescription = video.id // Use taskDescription to link task back to video ID
        
        var info = DownloadInfo(videoId: video.id)
        info.status = .downloading(progress: 0.0)
        info.downloadTask = downloadTask
        
        // Observe progress (needs Combine or KVO)
        // Using KVO example:
        info.progressObserver = downloadTask.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            DispatchQueue.main.async { // Ensure UI updates on main thread
                 self?.updateStatus(for: video.id, status: .downloading(progress: progress.fractionCompleted))
            }
        }
        
        downloads[video.id] = info
        downloadTask.resume()
        saveDownloads() // Save state update
    }
    
    func cancelDownload(for videoId: String) {
        guard var info = downloads[videoId], let task = info.downloadTask else { return }
        
        print("[DownloadManager] Cancelling download for video \(videoId)")
        task.cancel()
        info.progressObserver?.invalidate()
        info.progressObserver = nil
        info.downloadTask = nil
        info.status = .notDownloaded // Reset status
        downloads[videoId] = info
        saveDownloads()
    }
    
    func deleteDownload(for videoId: String) {
        guard let info = downloads[videoId] else { return }
        
        print("[DownloadManager] Deleting download for video \(videoId)")
        
        // Cancel if in progress
        if let task = info.downloadTask { 
            task.cancel()
            info.progressObserver?.invalidate()
        }
        
        // Delete file if it exists
        if let path = info.localPath {
            let localURL = documentsDirectory.appendingPathComponent(path)
            try? fileManager.removeItem(at: localURL)
        }
        
        // Remove record
        downloads.removeValue(forKey: videoId)
        saveDownloads()
    }
    
    // MARK: - Helper Methods
    
    private func updateStatus(for videoId: String, status: DownloadStatus) {
        // Ensure updates happen on the main thread for @Published
        DispatchQueue.main.async {
             guard var info = self.downloads[videoId] else { return }
             info.status = status
             self.downloads[videoId] = info
             
             // Add logging for progress
             if case .downloading(let progress) = status {
                 // Log progress periodically (e.g., every 5% or so)
                 // Use Int casting to avoid flooding logs
                 // print("[DownloadManager] Progress for \(videoId): \(String(format: "%.2f", progress * 100))%") 
                 let progressPercent = Int(progress * 100)
                 // Log only at certain intervals, e.g., every 5%
//                 if progressPercent % 5 == 0 || progress == 1.0 {
                     print("[DownloadManager] Progress for \(videoId): \(progressPercent)%")
//                 }
             }
             
             // Optionally save immediately, or batch saves
             // We might not want to save on every progress update, only on start/finish/cancel/fail
             // self.saveDownloads()
        }
    }
    
    private func resumeInterruptedDownloads() async {
       // Get tasks that might be resumable from the session
       let tasks = await session.allTasks
       print("[DownloadManager] Found \(tasks.count) existing tasks in session.")
       // Potentially match tasks with saved state and resume them
       // This requires more robust state saving (e.g., saving resume data)
       // For now, we reset 'downloading' state on load.
    }
    
    // MARK: - URLSessionDownloadDelegate Methods
    
    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
         guard let videoId = downloadTask.taskDescription else {
            print("[DownloadManager] Error: Download task finished but missing video ID description.")
            try? FileManager.default.removeItem(at: location)
            return
        }
        
        // Get documents directory path safely from nonisolated context
        guard let documentsPathString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
             print("[DownloadManager] Error: Could not find documents directory path for video \(videoId).")
             // Dispatch status update to main actor
             Task { @MainActor in
                 self.updateStatus(for: videoId, status: .failed(error: "Documents directory not found"))
                 self.saveDownloads()
             }
             return
         }
        let documentsURL = URL(fileURLWithPath: documentsPathString)
        
        // Construct destination URL
        let originalURL = downloadTask.originalRequest?.url
        let fileExtension = originalURL?.pathExtension ?? "mp4"
        let destinationFilename = "\(videoId).\(fileExtension)"
        let destinationURL = documentsURL.appendingPathComponent(destinationFilename)
        
        let fileManager = FileManager.default // Use a local instance
        var moveError: Error? = nil
        
        // Perform file operations synchronously within the delegate method
        do {
            // Remove existing file at destination if any
            try? fileManager.removeItem(at: destinationURL)
            // Move downloaded file
            try fileManager.moveItem(at: location, to: destinationURL)
            print("[DownloadManager] Video \(videoId) moved successfully to \(destinationURL.path)")
        } catch {
            print("[DownloadManager] Error moving downloaded file for video \(videoId): \(error)")
            moveError = error
        }
        
        // Dispatch ONLY the state update to the main actor
        Task { @MainActor in
            if let error = moveError {
                 self.updateStatus(for: videoId, status: .failed(error: "Failed to save file: \(error.localizedDescription)"))
            } else {
                 guard var info = self.downloads[videoId] else { return }
                 info.status = .downloaded(localPath: destinationFilename)
                 info.localPath = destinationFilename
                 info.downloadTask = nil 
                 info.progressObserver?.invalidate()
                 info.progressObserver = nil
                 self.downloads[videoId] = info
             }
             // Save state regardless of success/failure of the move
             self.saveDownloads()
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let videoId = task.taskDescription else { return }
        
        // Check if error occurred
        if let error = error {
            let nsError = error as NSError
            // Ignore cancellation errors
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                print("[DownloadManager] Download cancelled for video \(videoId).")
                // Status should have already been reset by cancelDownload
            } else {
                print("[DownloadManager] Download failed for video \(videoId): \(error.localizedDescription)")
                Task { @MainActor in
                    self.updateStatus(for: videoId, status: .failed(error: error.localizedDescription))
                     // Clean up transient state
                    guard var info = self.downloads[videoId] else { return }
                    info.downloadTask = nil
                    info.progressObserver?.invalidate()
                    info.progressObserver = nil
                    self.downloads[videoId] = info
                    self.saveDownloads()
                }
            }
        } else {
            // Task completed successfully (handled by didFinishDownloadingTo)
             print("[DownloadManager] Task completed successfully for video \(videoId). Final status handled by didFinishDownloadingTo.")
        }
    }
    
    // Optional: Handle background session completion
    // Mark as nonisolated to satisfy protocol requirement
    nonisolated func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        // If using background sessions and need to notify the system
        // Check if AppDelegate needs to handle completion
        DispatchQueue.main.async {
             guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                   let handler = appDelegate.backgroundSessionCompletionHandler else {
                 return
             }
             handler()
             appDelegate.backgroundSessionCompletionHandler = nil
         }
    }
}

// MARK: - AppDelegate Snippet (Required for Background Downloads)
/*
 Need to add this to your AppDelegate:
 
 class AppDelegate: UIResponder, UIApplicationDelegate {
     var backgroundSessionCompletionHandler: (() -> Void)?

     func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
         backgroundSessionCompletionHandler = completionHandler
     }
     // ... rest of AppDelegate ...
 }
 */ 
