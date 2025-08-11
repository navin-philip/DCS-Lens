import SwiftUI

struct EnvironmentsView: View {
    @EnvironmentObject private var immersiveSpaceState: ImmersiveSpaceState
    @StateObject private var viewModel = EnvironmentsViewModel()
    @State private var hasSelectedInitialEnvironment = false
    
    private let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 300), spacing: 20)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.error {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text(error.localizedDescription)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            viewModel.fetchEnvironments()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else {
                    LazyVGrid(columns: columns, spacing: 20) {
                        // Manually add the default Pearl environment first
                        if let defaultPearlURL = Bundle.main.url(forResource: "ICON-PEARL", withExtension: "jpg") {
                            // Create a simplified EnvironmentObj just for the card display
                            // We only need properties the card uses directly (id, name, description, preview)
                            // NOTE: Using a placeholder image or the day image URL for the preview
                            let defaultPearlPreviewURLString = defaultPearlURL.absoluteString // Or use a specific preview image URL string
                            let defaultPearlEnv = EnvironmentObj(id: "default-pearl", 
                                                               name: "ICON - PEARL", 
                                                               description: "The default starting environment.", 
                                                               dayImage: defaultPearlURL.absoluteString, // Still needed if card logic uses it, but not for init
                                                               nightImage: "", // Still needed if card logic uses it, but not for init
                                                               imagePreview: defaultPearlPreviewURLString, 
                                                               isEnabled: true, // Assuming default is enabled
                                                               createdAt: Date(), // Placeholder date
                                                               updatedAt: Date()) // Placeholder date
                            
                            EnvironmentCard(environment: defaultPearlEnv, viewModel: viewModel)
                                .frame(idealWidth: 300, maxWidth: 300)
                                .onTapGesture {
                                     // Convert EnvironmentObj to DownloadedEnvironment for state update
                                     let downloadedEnv = DownloadedEnvironment(name: defaultPearlEnv.name, dayImage: defaultPearlURL, nightImage: nil)
                                     immersiveSpaceState.selectedEnvironment = downloadedEnv
                                     print("[EnvironmentsView] Selected default environment: \(defaultPearlEnv.name)")
                                }
                        } else {
                            // Optional: Display a placeholder or error if default couldn't be loaded
                            Text("Could not load default Pearl environment.")
                                .foregroundColor(.red)
                        }
                        
                        // Then loop through the downloaded environments, skipping the default if present
                        ForEach(viewModel.environments.filter { $0.name != "ICON - PEARL" }) { environment in
                            EnvironmentCard(environment: environment, viewModel: viewModel)
                                .frame(idealWidth: 300, maxWidth: 300)
                                // Tap gesture for downloaded environments is handled inside EnvironmentCard
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Environments")
            .task {
                viewModel.fetchEnvironments()
            }
            .onAppear {
                // Check if we need to select the first environment
                if !hasSelectedInitialEnvironment && !viewModel.environments.isEmpty && immersiveSpaceState.selectedEnvironment == nil {
                    selectFirstEnvironment()
                }
            }
            .onChange(of: viewModel.environments.count) { _, count in
                // When environments are loaded, select the first one if needed
                if !hasSelectedInitialEnvironment && count > 0 && immersiveSpaceState.selectedEnvironment == nil {
                    selectFirstEnvironment()
                }
            }
        }
    }
    
    private func selectFirstEnvironment() {
        guard !viewModel.environments.isEmpty else { return }
        
        hasSelectedInitialEnvironment = true
        Task {
            await viewModel.switchEnvironment(viewModel.environments[0], immersiveSpaceState)
        }
    }
}

struct EnvironmentCard: View {
    @EnvironmentObject private var immersiveSpaceState: ImmersiveSpaceState
    let environment: EnvironmentObj
    @ObservedObject var viewModel: EnvironmentsViewModel
    
    private var isDownloading: Bool {
        viewModel.isDownloading && viewModel.selectedEnvironment?.id == environment.id
    }
    
    private var isSelected: Bool {
        immersiveSpaceState.selectedEnvironment?.name == environment.name
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                AsyncImage(url: URL(string: environment.imagePreview)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else if phase.error != nil {
                        Rectangle()
                            .fill(Color.red.opacity(0.2))
                            .overlay(Image(systemName: "exclamationmark.triangle").foregroundColor(.red))
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(ProgressView())
                    }
                }
                
                if isDownloading {
                    ZStack {
                        Color.black.opacity(0.6)
                        
                        VStack(spacing: 16) {
                            Text("Downloading Environment")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ZStack {
                                Circle()
                                    .stroke(lineWidth: 8)
                                    .opacity(0.3)
                                    .foregroundColor(.white)
                                
                                Circle()
                                    .trim(from: 0.0, to: CGFloat(viewModel.downloadProgress))
                                    .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                                    .foregroundColor(.white)
                                    .rotationEffect(Angle(degrees: 270.0))
                                    .animation(.linear, value: viewModel.downloadProgress)
                                
                                VStack {
                                    Text("\(Int(viewModel.downloadProgress * 100))%")
                                        .font(.title)
                                        .bold()
                                        .foregroundColor(.white)
                                    
//                                    Text(viewModel.downloadProgress < 0.5 ? "Day Image" : "Night Image")
//                                        .font(.caption)
//                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            .frame(width: 120, height: 120)
                        }
                        .padding()
                    }
                }
                
                if isSelected && !isDownloading {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                                .background(Circle().fill(Color.white))
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            .frame(width: 300, height: 200)
            .clipped()
            .contentShape(Rectangle())
            
            VStack(alignment: .leading, spacing: 8) {
                Text(environment.name)
                    .font(.title2)
                    .bold()

                Text(environment.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    if !environment.nightImage.isEmpty {
                        Label("Day/Night", systemImage: "sun.max.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Label("Day Only", systemImage: "sun.max")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Text("Selected")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            Task {
                await viewModel.switchEnvironment(environment, immersiveSpaceState)
            }
        }
        .scaleEffect(isDownloading ? 0.98 : 1.0)
        .animation(.spring(response: 0.3), value: isDownloading)
    }
}

#Preview {
    EnvironmentsView()
} 
