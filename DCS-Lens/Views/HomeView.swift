import SwiftUI
import Combine // Import Combine for Timer

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @EnvironmentObject private var immersiveSpaceState: ImmersiveSpaceState // Access shared state
    
    // State for current featured index
    @State private var currentFeaturedIndex = 0
    // Timer publisher for auto-scroll
    @State private var timerSubscription: Cancellable? // Store subscription to cancel later
    private let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect() // Auto-scroll every 10 seconds

    // Define grid layout for categories
    private let categoryGridColumns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 15)
    ]
    
    // Define grid layout for videos
    private let videoGridColumns = [
        GridItem(.adaptive(minimum: 240, maximum: 300), spacing: 20)
    ]
    
    // Initializer to pass the environment object to the view model
    init(immersiveSpaceState: ImmersiveSpaceState) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(immersiveSpaceState: immersiveSpaceState))
    }

    var body: some View {
        ZStack {
          Color.clear.ignoresSafeArea()
            
        NavigationStack {
                // Wrap ScrollView content in ScrollViewReader
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 35) {
                            // Display error message if any
                            if let errorMessage = viewModel.errorMessage {
                                ErrorView(message: errorMessage) { 
                                    viewModel.fetchAllData() // Retry action
                                }
                                .padding(.horizontal)
                            }

                            // Featured Videos Carousel (Conditional)
                            featuredVideosSection
                            
                            // Categories Grid
                            categoriesSection
                            
                            // Videos List (Horizontal Scroll)
                            videosListSection
                                .id("videosListSection") // Give the section an ID
                        }
                        .padding(.bottom, 20)
                        // Add onAppear to scroll to the section
//                        .onAppear {
//                            // Scroll gently to the top of the video list when the view appears
//                            // Use a small delay to ensure layout is complete
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                                withAnimation { // Optional: Use animation
//                                   proxy.scrollTo("videosListSection", anchor: .top)
//                                }
//                            }
//                        }
                    }
                    .toolbar(.hidden, for: .navigationBar)
                    .preferredColorScheme(.dark)
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var featuredVideosSection: some View {
        // Show carousel only if not loading and featured videos exist
        if !viewModel.isLoadingFeatured && !viewModel.featuredVideos.isEmpty {
             // Use a group to attach modifiers easily
             Group { 
                TabView(selection: $currentFeaturedIndex) { // Bind selection to state
                    // Use enumerated array to get index easily
                    ForEach(Array(viewModel.featuredVideos.enumerated()), id: \.element.id) { index, video in
                        FeaturedVideoBanner(video: video)
                            .tag(index) // Tag each view with its index
                            // Add tap gesture to set the selected video
                            .onTapGesture {
                                immersiveSpaceState.selectedVideo = video
                                print("[HomeView] Selected featured video: \(video.title)")
                                // Optionally stop timer on tap?
                                stopTimer()
                            }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(height: 400)
                .listRowInsets(EdgeInsets())
            }
            .onReceive(timer) { _ in
                // Auto-scroll logic
                guard !viewModel.featuredVideos.isEmpty else { return }
                let nextIndex = (currentFeaturedIndex + 1) % viewModel.featuredVideos.count
                withAnimation { // Add animation for smooth transition
                     currentFeaturedIndex = nextIndex
                }
            }
            // Optional: Reset timer if user manually scrolls
            .onChange(of: currentFeaturedIndex) { _, _ in
                 // If user interacts, they change the index, restarting the timer delay implicitly
                 // For more robust pause/resume, might need gesture recognizers
                 // restartTimer() // Could restart timer here if needed
             }
             .onAppear(perform: startTimer) // Start timer when view appears
             .onDisappear(perform: stopTimer) // Stop timer when view disappears

        } else if viewModel.isLoadingFeatured {
            // Show loading indicator for featured section
            HStack {
                Spacer()
                ProgressView()
                    .frame(height: 400) // Match height
                Spacer()
            }
        }else if viewModel.featuredVideos.isEmpty {
          HStack{

          }.padding(.vertical)

        }
        // If loading fails or list is empty, this section will just be empty
    }

    // Helper methods for timer management
    private func startTimer() {
        // Ensure timer is not already running
        stopTimer()
        // Reconnect the publisher
        timerSubscription = timer.sink { _ in
             // Auto-scroll logic (redundant here, handled by onReceive directly)
            // guard !viewModel.featuredVideos.isEmpty else { return }
            // let nextIndex = (currentFeaturedIndex + 1) % viewModel.featuredVideos.count
            // withAnimation {
            //     currentFeaturedIndex = nextIndex
            // }
         }
        print("[HomeView] Timer Started")
    }

    private func stopTimer() {
        timerSubscription?.cancel()
        timerSubscription = nil
        print("[HomeView] Timer Stopped")
    }

    @ViewBuilder
    private var categoriesSection: some View {
        // No "Categories" title needed based on the reference image
        if viewModel.isLoadingTags {
             HStack {
                Spacer()
                ProgressView()
                Spacer()
            }.padding()
        } else if !viewModel.categories.isEmpty {
            LazyVGrid(columns: categoryGridColumns, spacing: 15) {
                 ForEach(viewModel.categories) { category in
                    CategoryButton(category: category, 
                                     isSelected: viewModel.selectedCategoryId == category.id)
                    {
                        viewModel.selectedCategoryId = category.id
                    }
                }
            }
            .padding(.horizontal)
        }
         // If loading fails or list is empty, this section will just be empty
    }

    @ViewBuilder
    private var videosListSection: some View { // Renamed
        VStack(alignment: .leading, spacing: 15) {
            // Dynamic section title, styled like "Recommended for You"
            Text(viewModel.categories.first { $0.id == viewModel.selectedCategoryId }?.name ?? "Videos")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            if viewModel.isLoadingVideos {
                HStack {
                    Spacer()
                    ProgressView("Loading Videos...")
                        .frame(height: 250) // Give loading indicator some space
                    Spacer()
                }
                .padding(.vertical)
            } else if viewModel.videos.isEmpty {
                 Text("No videos found for this category.")
                     .foregroundColor(.secondary)
                     .padding(.horizontal)
                     .frame(maxWidth: .infinity, alignment: .center)
                     .frame(height: 250) // Give message some space
                     .padding(.vertical)
             } else {
                 // Use LazyVGrid for video list
                 LazyVGrid(columns: videoGridColumns, spacing: 20) { // Use LazyVGrid and videoGridColumns
                     ForEach(viewModel.videos) { video in
                         VideoCard(video: video)
                             // No fixed frame needed, grid handles sizing
                             .onTapGesture {
                                 immersiveSpaceState.selectedVideo = video
                                 print("[HomeView] Selected video: \(video.title)")
                             }
                     }
                 }
                 .padding(.horizontal) // Keep horizontal padding for the VStack
                 .padding(.bottom, 5) // Keep bottom padding
            }
        }
    }
}

// MARK: - Reusable Components (Updated Styles)

struct FeaturedVideoBanner: View {
    let video: Video
    @EnvironmentObject var viewModel: HomeViewModel

    var body: some View {
        // Wrap AsyncImage in GeometryReader to get its potential size
        GeometryReader { geometry in
            AsyncImage(url: URL(string: video.thumbnailURL)) { phase in
                if let image = phase.image {
                    image.resizable()
                         .aspectRatio(contentMode: .fill)
                         // Apply frame based on GeometryReader
                         .frame(width: geometry.size.width, height: geometry.size.height)
                         
                } else if phase.error != nil {
                    // Error view (optional)
                    Rectangle()
                        .fill(Color.red.opacity(0.5))
                         .frame(width: geometry.size.width, height: geometry.size.height)
                    Text("Image Error")
                } else {
                    // Placeholder
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .overlay(ProgressView())
                }
            }
            .clipped() // Clip the image content if it overflows the frame
            .overlay { // Apply overlay to the GeometryReader/framed image
                // ZStack for Gradient and Content
                ZStack(alignment: .bottomLeading) { 
                    // Layer 1: Gradient
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    
                    // Layer 2: Content (Text & Button)
                    HStack(alignment: .bottom) {
                        // Text
                        VStack(alignment: .leading) {
                            Text(video.title)
                                .font(.title).fontWeight(.bold).foregroundColor(.white).shadow(radius: 2)
                            Text(video.description)
                                .font(.headline).foregroundColor(.white.opacity(0.8)).lineLimit(2).shadow(radius: 1)
                        }
                        
                        Spacer() // Pushes button to trailing edge
                        
                        // Button
                        DownloadButton(videoId: video.id)
                            .background(.ultraThinMaterial, in: Circle())
                            .padding(8) // Inner padding
                            .padding(.bottom, 8) // Push away from edge
                            .padding(.trailing, 8)
                    }
                    .padding() // Padding around the HStack content
                    
                } // End ZStack
                // No explicit frame needed here; overlay matches the GeometryReader's frame
            } // End overlay
        } // End GeometryReader
        // Environment object might be needed for preview if standalone
        // .environmentObject(viewModel)
    }
}

struct VideoCard: View {
    let video: Video
    @EnvironmentObject var viewModel: HomeViewModel // Needed for download button
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) { // Reduced spacing
            // Image with Download Button overlay
            ZStack(alignment: .topTrailing) { 
                AsyncImage(url: URL(string: video.thumbnailURL)) { phase in
                    if let image = phase.image {
                        image.resizable()
                             .aspectRatio(16/9, contentMode: .fit)
                             // Remove fixed frame - let the grid cell and aspect ratio determine size
                             // .frame(width: 250, height: 140)
                    } else if phase.error != nil {
                        // Error view (optional)
                        Rectangle()
                            .fill(Color.red.opacity(0.5))
                             // Also remove fixed frame here
                             .aspectRatio(16/9, contentMode: .fit)
                            // .frame(width: 250, height: 140)
                        Text("Image Error")
                    } else {
                        // Placeholder
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                             // Also remove fixed frame here
                             .aspectRatio(16/9, contentMode: .fit)
                            // .frame(width: 250, height: 140)
                            .overlay(ProgressView())
                    }
                }
                .cornerRadius(8)
                
                // Add DownloadButton
                 DownloadButton(videoId: video.id)
                     .padding(5)
                     .background(.ultraThinMaterial, in: Circle()) // Match banner button background
            }
            
            // Text Content below image
            VStack(alignment: .leading, spacing: 2) { // Inner VStack for text
                Text(video.title)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                    
                Text(video.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2) // Allow up to 2 lines for description
            }
            .padding(.horizontal, 4) // Slight horizontal padding for text
            .padding(.bottom, 4)

        }
        // No card background needed on dark theme
        // .environmentObject(viewModel) // Provided by parent (HomeView)
    }
}

struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background rectangle
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.gray.opacity(0.5) : Color.gray.opacity(0.2)) // Darker background
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 1.5) // White border when selected
                
                // Placeholder for Logo/Image - Using Text for now
                Text(category.name)
                    .font(.title3) // Larger font
                    .fontWeight(.bold)
                    .foregroundColor(.white) // White text
                    .padding()
            }
            .frame(height: 80) // Make button taller
        }
        .buttonStyle(.plain) // Use plain for custom styling
        .scaleEffect(isSelected ? 1.05 : 1.0) // Slight scale effect when selected
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

struct ErrorView: View {
    let message: String
    let retryAction: (() -> Void)?
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow) // Use yellow for dark mode
            Text(message)
                .foregroundColor(.secondary)
                .lineLimit(nil) // Allow multiple lines
            Spacer()
            if let retryAction = retryAction {
                Button("Retry") {
                    retryAction()
                }
                .buttonStyle(.bordered)
                .tint(.yellow) // Tint button to match icon
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.15))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    let previewState = ImmersiveSpaceState()
    let previewViewModel = HomeViewModel(immersiveSpaceState: previewState)
    // TODO: Populate viewModel with dummy data for preview if needed

    return HomeView(immersiveSpaceState: previewState)
        .environmentObject(previewState)
        .environmentObject(previewViewModel) // Provide viewModel
        .environmentObject(DownloadManager.shared) // Provide manager
        .preferredColorScheme(.dark)
} 
