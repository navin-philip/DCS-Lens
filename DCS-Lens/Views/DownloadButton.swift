import SwiftUI

struct DownloadButton: View {
    let videoId: String
    @EnvironmentObject var viewModel: HomeViewModel
    @ObservedObject var downloadManager = DownloadManager.shared // Access shared manager
    @State private var showDownloadErrorAlert = false // State for alert
    @State private var downloadErrorVideoId: String? = nil // Store which video failed
    
    var body: some View {
        let status = downloadManager.getStatus(for: videoId)
        
        Group { // Use Group to attach alert easily
            switch status {
            case .notDownloaded:
                Button {
                    // Get the video object using the ID
                    if let video = viewModel.getVideo(byId: videoId) {
                        downloadManager.startDownload(for: video) 
                    } else {
                        print("[DownloadButton] Error: Could not find Video object for ID \(videoId) to start download.")
                        // Trigger the alert
                        downloadErrorVideoId = videoId
                        showDownloadErrorAlert = true
                    }
                } label: {
                    Image(systemName: "arrow.down.circle")
                        .imageScale(.large)
                }
                .buttonStyle(.borderless) // Use borderless for icon buttons within cards
                
            case .downloading(let progress):
                ZStack {
                    CircularProgressView(progress: progress)
                        .frame(width: 30, height: 30)
                    // Allow cancelling
                    Button {
                        downloadManager.cancelDownload(for: videoId)
                    } label: {
                         Image(systemName: "stop.circle.fill") // Or "xmark"?
                            .imageScale(.medium)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.borderless)
                }
                
            case .downloaded:
                // Show checkmark, maybe tapping deletes it?
                Image(systemName: "checkmark.circle.fill")
                     .imageScale(.large)
                     .foregroundColor(.green)
                     .contextMenu { // Add context menu to delete
                         Button(role: .destructive) {
                             downloadManager.deleteDownload(for: videoId)
                         } label: {
                             Label("Delete Download", systemImage: "trash")
                         }
                     }
            case .failed(let error):
                 // Show error icon, tapping could retry?
                 Image(systemName: "exclamationmark.arrow.triangle.2.circlepath")
                     .imageScale(.large)
                     .foregroundColor(.orange)
                     .help("Download failed: \(error). Tap to retry.") // Tooltip
                     .onTapGesture {
                         if let video = viewModel.getVideo(byId: videoId) {
                             downloadManager.startDownload(for: video) // Retry
                         } else {
                              print("[DownloadButton] Error: Could not find Video object for ID \(videoId) to retry download.")
                              downloadErrorVideoId = videoId
                              showDownloadErrorAlert = true
                         }
                     }
            }
        }
        .alert("Download Error", isPresented: $showDownloadErrorAlert, presenting: downloadErrorVideoId) { failedVideoId in
             // Alert actions (e.g., just OK)
             Button("OK") { }
        } message: { failedVideoId in
             Text("Could not start download for video. Please try again later.")
        }
    }
}

// Simple Circular Progress View
struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 3.0)
                .opacity(0.3)
                .foregroundColor(.gray)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 3.0, lineCap: .round, lineJoin: .round))
                .foregroundColor(.blue)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: progress)
        }
    }
}

#Preview {
    // Preview needs the ViewModel and Manager
    let previewState = ImmersiveSpaceState()
    let previewViewModel = HomeViewModel(immersiveSpaceState: previewState)
    // TODO: Populate viewModel with dummy data for preview if needed
    
    return HStack(spacing: 20) {
        DownloadButton(videoId: "test1")
        DownloadButton(videoId: "test2") 
        DownloadButton(videoId: "test3") 
        DownloadButton(videoId: "test4")
    }
    .padding()
    .environmentObject(previewViewModel)
    .environmentObject(DownloadManager.shared)
} 