import Foundation

class DownloadTask: NSObject {
    var totalDownloaded: Float = 0 {
        didSet {
            self.handleDownloadedProgressPercent?(totalDownloaded)
        }
    }
    
    typealias progressClosure = ((Float) -> Void)
    typealias completionClosure = ((URL) -> Void)
    
    var handleDownloadedProgressPercent: progressClosure?
    var completionHandler: completionClosure?
    var isDayImage: Bool = true
    
    // MARK: - Properties
    private var configuration: URLSessionConfiguration
    private lazy var session: URLSession = {
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: .main)
        return session
    }()
    
    // MARK: - Initialization
    override init() {
        self.configuration = URLSessionConfiguration.default
        super.init()
    }
    
    func download(url: String, progress: ((Float) -> Void)?, isDayImage: Bool = true) {
        /// bind progress closure to View
        self.handleDownloadedProgressPercent = progress
        self.isDayImage = isDayImage
        
        /// handle url
        guard let url = URL(string: url) else {
            preconditionFailure("URL isn't true format!")
        }
        
        let task = session.downloadTask(with: url)
        task.resume()
    }
    
    func download(url: String, isDayImage: Bool = true) {
        download(url: url, progress: nil, isDayImage: isDayImage)
    }
}

extension DownloadTask: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        self.totalDownloaded = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
    }
    
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        // Create a copy of the file in the temporary directory with a specific name
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = downloadTask.originalRequest?.url?.lastPathComponent ?? "downloaded_file"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            // Remove existing file if it exists
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            
            // Copy the downloaded file to our temporary directory
            try FileManager.default.copyItem(at: location, to: fileURL)
            
            // Call the completion handler with the file URL
            if let completionHandler = completionHandler {
                completionHandler(fileURL)
            }
        } catch {
            print("Error saving downloaded file: \(error)")
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Download error: \(error)")
        }
    }
} 
