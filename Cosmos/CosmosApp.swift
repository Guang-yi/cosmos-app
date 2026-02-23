import SwiftUI
import FirebaseCore

@main
struct CosmosApp: App {
    @State private var authService: AuthService
    @State private var firestoreService: FirestoreService

    init() {
        // Only configure Firebase if GoogleService-Info.plist exists
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }
        // Initialize services after Firebase is configured
        _authService = State(initialValue: AuthService())
        _firestoreService = State(initialValue: FirestoreService())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authService)
                .environment(firestoreService)
        }
    }
}
