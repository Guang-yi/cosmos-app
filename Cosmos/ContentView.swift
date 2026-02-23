import SwiftUI

struct ContentView: View {
    @Environment(AuthService.self) private var auth

    var body: some View {
        if auth.isAuthenticated {
            Text("Home — coming in Task 7")
        } else {
            SignInView()
        }
    }
}
