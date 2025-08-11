import SwiftUI

struct FeaturedView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Featured Content")
                    .font(.largeTitle)
            }
            .navigationTitle("Featured")
        }
    }
}

#Preview {
    FeaturedView()
} 