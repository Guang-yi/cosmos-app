import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "flame.fill")
                }

            QuotesView()
                .tabItem {
                    Label("Quotes", systemImage: "quote.opening")
                }

            ComingSoonView(feature: "Your Village", description: "Connect with accountability partners and share your journey.")
                .tabItem {
                    Label("Village", systemImage: "person.3.fill")
                }

            CommunityRoadmapView()
                .tabItem {
                    Label("Roadmap", systemImage: "map.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        .tint(.orange)
    }
}
