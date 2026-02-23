import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(AuthService.self) private var auth

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Flame mascot placeholder
                Image(systemName: "flame.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.orange)
                    .symbolEffect(.pulse)

                Text("Cosmos")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Your universe. Your greatness.")
                    .font(.title3)
                    .foregroundStyle(.gray)

                Spacer()

                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    Task {
                        if case .success(let authorization) = result,
                           let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                            try? await auth.signInWithApple(credential: credential)
                        }
                    }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 55)
                .padding(.horizontal, 40)

                Spacer().frame(height: 40)
            }
        }
    }
}
