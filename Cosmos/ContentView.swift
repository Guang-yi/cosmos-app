import SwiftUI

struct ContentView: View {
    @Environment(AuthService.self) private var auth
    @Environment(FirestoreService.self) private var firestore
    @State private var hasCompletedOnboarding = false
    @State private var isCheckingProfile = true

    var body: some View {
        Group {
            if !auth.isAuthenticated {
                SignInView()
            } else if isCheckingProfile {
                ZStack {
                    Color.black.ignoresSafeArea()
                    ProgressView().tint(.orange)
                }
            } else if !hasCompletedOnboarding {
                VoiceOnboardingView(onComplete: {
                    hasCompletedOnboarding = true
                })
            } else {
                MainTabView()
            }
        }
        .task(id: auth.currentUser?.uid) {
            guard let uid = auth.currentUser?.uid else {
                isCheckingProfile = false
                return
            }
            let user = try? await firestore.getUser(id: uid)
            hasCompletedOnboarding = user != nil
            isCheckingProfile = false
        }
    }
}
