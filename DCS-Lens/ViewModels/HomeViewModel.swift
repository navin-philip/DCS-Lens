import Foundation
import Combine

// Define a special Category struct to include "All"
struct Category: Identifiable, Hashable {
    let id: String
    let name: String
    var isTag: Bool { id != "all" } // Helper to distinguish the "All" category

    static let all = Category(id: "all", name: "All")
}

@MainActor
class HomeViewModel: ObservableObject {
    // Add immersiveSpaceState reference
    private var immersiveSpaceState: ImmersiveSpaceState
    // Add DownloadManager reference
    private let downloadManager = DownloadManager.shared
    
    @Published var featuredVideos: [Video] = []
    @Published var tags: [Tag] = []
    @Published var videos: [Video] = []
    // Remove local selectedCategoryId state
    // @Published var selectedCategoryId: String = Category.all.id { ... }

    @Published var isLoadingFeatured = false
    @Published var isLoadingTags = false
    @Published var isLoadingVideos = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()
    private let apiService = APIService.shared

    // Computed property for categories including "All"
    var categories: [Category] {
        [Category.all] + tags.map { Category(id: $0.id, name: $0.name) }
    }
    
    // Computed property to access selectedCategoryId from shared state
    var selectedCategoryId: String {
        get { immersiveSpaceState.selectedCategoryId }
        set { 
            // Only update if the value actually changed
            if immersiveSpaceState.selectedCategoryId != newValue {
                immersiveSpaceState.selectedCategoryId = newValue 
                fetchVideosForSelectedCategory() // Trigger fetch on change
            }
        }
    }

    // Modify initializer to accept ImmersiveSpaceState
    init(immersiveSpaceState: ImmersiveSpaceState) {
        self.immersiveSpaceState = immersiveSpaceState
        // Initial data fetch
        fetchAllData()
        // Explicitly fetch videos for the default category ("All") on init
        // Fetch based on the categoryId already present in immersiveSpaceState
        fetchVideosForSelectedCategory()
    }

    func fetchAllData() {
        // Reset error message
        errorMessage = nil
        
        // Fetch featured videos and tags concurrently
        Task {
            await fetchFeatured()
            await fetchTagsList()
            // Initial video fetch is handled by selectedCategoryId didSet
        }
    }

    // MARK: - Data Fetching Methods

    func fetchFeatured() async {
        isLoadingFeatured = true
        do {
            featuredVideos = try await apiService.fetchFeaturedVideos()
//            print("Fetched \(featuredVideos.count) featured videos.")
        } catch {
            handleError(error, context: "featured videos")
            featuredVideos = [] // Clear on error
        }
        isLoadingFeatured = false
    }

    func fetchTagsList() async {
        isLoadingTags = true
        do {
            tags = try await apiService.fetchTags()
//             print("Fetched \(tags.count) tags.")
        } catch {
            handleError(error, context: "tags")
            tags = [] // Clear on error
        }
        isLoadingTags = false
    }

    func fetchVideosForSelectedCategory() {
        guard !isLoadingVideos else { return } // Prevent concurrent fetches
        isLoadingVideos = true
        errorMessage = nil // Clear previous video errors
        
        // Use the computed property which reads from immersiveSpaceState
        let categoryIdToFetch = self.selectedCategoryId 
        
        Task {
            do {
                if categoryIdToFetch == Category.all.id {
                    videos = try await apiService.fetchAllVideos()
//                    print("[ViewModel] Fetched \(videos.count) videos for 'All'.")
                } else {
                    videos = try await apiService.fetchVideos(tagged: categoryIdToFetch)
//                     print("[ViewModel] Fetched \(videos.count) videos for tag ID \(categoryIdToFetch).")
                }
            } catch {
                handleError(error, context: "videos for category \(categoryIdToFetch)")
                videos = [] // Clear videos on error
            }
            isLoadingVideos = false
        }
    }

    // MARK: - Error Handling

    private func handleError(_ error: Error, context: String) {
        print("Error fetching \(context): \(error)")
        // Set a user-friendly error message
        if let apiError = error as? APIError {
            switch apiError {
            case .invalidURL:
                errorMessage = "Failed to fetch \(context). Invalid URL."
            case .networkError(let underlyingError):
                errorMessage = "Network error fetching data: \(underlyingError.localizedDescription)"
            case .decodingError(let underlyingError):
                errorMessage = "Failed to process data for \(context). Please check API response. Error: \(underlyingError)"
            case .invalidResponse:
                errorMessage = "Received an invalid response while fetching \(context)."
            }
        } else {
            errorMessage = "An unexpected error occurred fetching \(context): \(error.localizedDescription)"
        }
        // Only keep the first error message if multiple fetches fail
        // Or decide how to combine/prioritize errors
    }

    // Function to get the full Video object by ID (if needed by DownloadButton)
    // This assumes videos/featuredVideos contain all currently relevant videos
    func getVideo(byId id: String) -> Video? {
        if let video = videos.first(where: { $0.id == id }) {
            return video
        } 
        if let featuredVideo = featuredVideos.first(where: { $0.id == id }) {
             return featuredVideo
        }
        print("[ViewModel] Warning: Video with ID \(id) not found in current lists.")
        return nil // Or fetch from API if not found?
    }
} 
