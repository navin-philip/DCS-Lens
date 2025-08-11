import Foundation
import RealityKit

@MainActor
class EnvironmentsViewModel: ObservableObject {
    @Published var environments: [EnvironmentObj] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var selectedEnvironment: EnvironmentObj?
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0
    
    private var downloadedImages: [String: URL] = [:]
    private var downloadTasks: [String: DownloadTask] = [:]
    
    func fetchEnvironments() {
        isLoading = true
        error = nil
        
        Task {
            do {
                environments = try await APIService.shared.fetchEnvironments()
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
    
    func downloadEnvironmentImages(for environment: EnvironmentObj) async throws -> (dayURL: URL, nightURL: URL?) {
        isDownloading = true
        downloadProgress = 0
        selectedEnvironment = environment
        
        // Check if images are already downloaded
        if let dayURL = downloadedImages[environment.dayImage] {
            if environment.nightImage.isEmpty {
                // If no night image needed and day image exists, return immediately
                downloadProgress = 1
                isDownloading = false
                return (dayURL, nil)
            } else if let nightURL = downloadedImages[environment.nightImage] {
                // If both images exist, return immediately
                downloadProgress = 1
                isDownloading = false
                return (dayURL, nightURL)
            }
        }
        
        // Create a continuation to wait for downloads to complete
        return try await withCheckedThrowingContinuation { continuation in
            var dayURL: URL?
            var nightURL: URL?
            var dayDownloadComplete = false
            var nightDownloadComplete = true // Default to true if no night image
            
            // Only download day image if not already cached
            if let cachedDayURL = downloadedImages[environment.dayImage] {
                dayURL = cachedDayURL
                dayDownloadComplete = true
                downloadProgress = 0.5 // Set progress to halfway since day image is already done
            } else {
                // Download day image
                let dayDownloadTask = DownloadTask()
                downloadTasks[environment.dayImage] = dayDownloadTask
                
                // Set up progress handler for day image
                dayDownloadTask.handleDownloadedProgressPercent = { [weak self] progress in
                    Task { @MainActor [weak self] in
                        self?.downloadProgress = Double(progress) * 0.5
                    }
                }
                
                // Set up completion handler for day image
                dayDownloadTask.completionHandler = { url in
                    dayURL = url
                    dayDownloadComplete = true
                    
                    // Cache the downloaded URL
                    self.downloadedImages[environment.dayImage] = url
                    
                    // If night image is already downloaded or not needed, complete
                    if nightDownloadComplete {
                        continuation.resume(returning: (dayURL!, nightURL))
                    }
                }
                
                // Start day image download
                dayDownloadTask.download(url: environment.dayImage, progress: { [weak self] progress in
                    Task { @MainActor [weak self] in
                        self?.downloadProgress = Double(progress) * 0.5
                    }
                }, isDayImage: true)
            }
            
            // Handle night image if available
            if !environment.nightImage.isEmpty {
                if let cachedNightURL = downloadedImages[environment.nightImage] {
                    // Use cached night image
                    nightURL = cachedNightURL
                    nightDownloadComplete = true
                    downloadProgress = 1 // Set progress to complete since both images are done
                    
                    if dayDownloadComplete {
                        continuation.resume(returning: (dayURL!, nightURL))
                    }
                } else {
                    nightDownloadComplete = false
                    
                    let nightDownloadTask = DownloadTask()
                    downloadTasks[environment.nightImage] = nightDownloadTask
                    
                    // Set up progress handler for night image
                    nightDownloadTask.handleDownloadedProgressPercent = { [weak self] progress in
                        Task { @MainActor [weak self] in
                            self?.downloadProgress = 0.5 + Double(progress) * 0.5
                        }
                    }
                    
                    // Set up completion handler for night image
                    nightDownloadTask.completionHandler = { url in
                        nightURL = url
                        nightDownloadComplete = true
                        
                        // Cache the downloaded URL
                        self.downloadedImages[environment.nightImage] = url
                        
                        // If day image is already downloaded, complete
                        if dayDownloadComplete {
                            continuation.resume(returning: (dayURL!, nightURL))
                        }
                    }
                    
                    // Start night image download
                    nightDownloadTask.download(url: environment.nightImage, progress: { [weak self] progress in
                        Task { @MainActor [weak self] in
                            self?.downloadProgress = 0.5 + Double(progress) * 0.5
                        }
                    }, isDayImage: false)
                }
            } else if dayDownloadComplete {
                // No night image and day image is done
                continuation.resume(returning: (dayURL!, nil))
            }
        }
    }
    
    func switchEnvironment(_ environment: EnvironmentObj, _ immersiveSpaceState: ImmersiveSpaceState) async {
        do {
            let (dayURL, nightURL) = try await downloadEnvironmentImages(for: environment)
            
            // Cache the downloaded URLs
            downloadedImages[environment.dayImage] = dayURL
            if let nightURL = nightURL {
                downloadedImages[environment.nightImage] = nightURL
            }
            
            // Here you would implement the actual environment switching logic
            // This might involve loading the images into RealityKit or your 3D environment
            print("Switching to environment: \(environment.name)")
            print("Day image: \(dayURL)")
            let downloadedEnvironment:DownloadedEnvironment = DownloadedEnvironment(name: environment.name, dayImage: dayURL, nightImage: nightURL)
            immersiveSpaceState.selectedEnvironment = downloadedEnvironment
            if let nightURL = nightURL {
                print("Night image: \(nightURL)")
            } else {
                print("No night image available")
            }
            
            // Add a small delay to ensure the progress is visible
//            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            isDownloading = false
            
        } catch {
            self.error = error
            isDownloading = false
        }
    }
} 
