import SwiftUI

struct DownloadsView: View {
    @StateObject var downloadManager = DownloadManager.shared
    @EnvironmentObject var viewModel: HomeViewModel // To get video details like title

    // Filter downloads to only show downloaded or failed items
    private var relevantDownloads: [DownloadInfo] {
        downloadManager.downloads.values.filter {
            if case .downloaded = $0.status { return true }
          //if case .failed = $0.status { return true } // Optionally show failed
            return false
        }.sorted { $0.videoId < $1.videoId } // Sort for consistent order
    }

    var body: some View {
        NavigationStack {
            List {
                if relevantDownloads.isEmpty {
                    Text("No videos downloaded yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(relevantDownloads, id: \.videoId) { downloadInfo in
                        HStack {
                            // Try to get video title from HomeViewModel
                            VStack(alignment: .leading) { // Use VStack for title
                                Text(viewModel.getVideo(byId: downloadInfo.videoId)?.title ?? "Video ID: \(downloadInfo.videoId)")
                                    .lineLimit(1)
                            }
                            
                            Spacer() // Pushes status and button to the right
                            
                            // Display status (mainly for 'failed' if included, or just size for 'downloaded')
                            if case .downloaded(let path) = downloadInfo.status {
                                if let fileSize = getFileSize(for: path) {
                                     Text(fileSize)
                                         .font(.caption)
                                         .foregroundColor(.secondary)
                                 } else {
                                     Text("-")
                                         .font(.caption)
                                         .foregroundColor(.secondary)
                                 }
                            } else if case .failed = downloadInfo.status {
                                 Image(systemName: "exclamationmark.triangle")
                                     .foregroundColor(.orange)
                            }
                            
                            // Add explicit Delete Button
                            Button(role: .destructive) {
                                downloadManager.deleteDownload(for: downloadInfo.videoId)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless) // Keep it clean in the list row
                            .padding(.leading, 5) // Add slight spacing
                        }
                        // Add swipe to delete action
                        .swipeActions {
                            Button(role: .destructive) {
                                downloadManager.deleteDownload(for: downloadInfo.videoId)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Downloads")
        }
        .preferredColorScheme(.dark)
    }
    
    // Helper to get file size string
    private func getFileSize(for relativePath: String) -> String? {
        let url = DownloadManager.shared.getLocalURL(for: relativePath.replacingOccurrences(of: ".mov", with: "")) ?? URL(fileURLWithPath: "") // Reconstruct URL (adjust if needed)
        guard url.isFileURL, let attributes = try? FileManager.default.attributesOfItem(atPath: url.path), let fileSize = attributes[.size] as? NSNumber else {
            return nil
        }
        return ByteCountFormatter.string(fromByteCount: fileSize.int64Value, countStyle: .file)
    }
}

#Preview {
    let previewState = ImmersiveSpaceState()
    let previewViewModel = HomeViewModel(immersiveSpaceState: previewState)
    // TODO: Populate download manager with dummy data for preview
    
    return DownloadsView()
        .environmentObject(previewViewModel)
        .environmentObject(DownloadManager.shared)
        .preferredColorScheme(.dark)
} 
