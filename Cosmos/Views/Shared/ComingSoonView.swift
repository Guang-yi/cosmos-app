import SwiftUI

struct ComingSoonView: View {
    let feature: String
    let description: String

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 20) {
                    Image(systemName: "sparkles").font(.system(size: 50)).foregroundStyle(.orange)
                    Text(feature).font(.title2.bold()).foregroundStyle(.white)
                    Text(description).foregroundStyle(.gray)
                        .multilineTextAlignment(.center).padding(.horizontal, 40)
                    Text("Coming Soon").font(.headline).foregroundStyle(.orange)
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(.orange.opacity(0.2)).clipShape(Capsule())
                }
            }
            .navigationTitle(feature)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
