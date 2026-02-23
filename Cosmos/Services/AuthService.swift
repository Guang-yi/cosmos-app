import Foundation
import FirebaseCore
import FirebaseAuth
import AuthenticationServices

@Observable
class AuthService {
    var currentUser: FirebaseAuth.User?
    var isAuthenticated: Bool { currentUser != nil }

    init() {
        guard FirebaseApp.app() != nil else { return }
        currentUser = Auth.auth().currentUser
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
        }
    }

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let tokenData = credential.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            throw AuthError.missingToken
        }
        let oauthCredential = OAuthProvider.appleCredential(
            withIDToken: token,
            rawNonce: nil,
            fullName: credential.fullName
        )
        let result = try await Auth.auth().signIn(with: oauthCredential)
        currentUser = result.user
    }

    func signOut() throws {
        try Auth.auth().signOut()
        currentUser = nil
    }

    enum AuthError: Error {
        case missingToken
    }
}
