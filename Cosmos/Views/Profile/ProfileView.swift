import SwiftUI

struct ProfileView: View {
    @Environment(AuthService.self) private var auth
    @Environment(FirestoreService.self) private var firestore
    @State private var user: CosmosUser?
    @State private var referralCount = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            Image(systemName: "flame.fill").font(.system(size: 50)).foregroundStyle(.orange)
                            if let user {
                                Text(user.name).font(.title.bold()).foregroundStyle(.white)
                                Text(user.domain).font(.subheadline).foregroundStyle(.gray)
                                Text("\"\(user.dreamGoal)\"")
                                    .font(.body).foregroundStyle(.white.opacity(0.7)).italic()
                                    .multilineTextAlignment(.center).padding(.horizontal)
                            }
                        }.padding(.top, 30)

                        if let user {
                            HStack(spacing: 30) {
                                StatItem(value: "\(user.currentStreak)", label: "Streak")
                                StatItem(value: "\(user.longestStreak)", label: "Best")
                                StatItem(value: "\(referralCount)", label: "Referrals")
                            }

                            Button { shareReferralLink(code: user.referralCode) } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Invite a Friend")
                                }
                                .font(.headline).foregroundStyle(.black)
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(.orange).clipShape(RoundedRectangle(cornerRadius: 16))
                            }.padding(.horizontal)
                        }

                        // Coming soon placeholders
                        NavigationLink {
                            AppIconPickerView()
                        } label: {
                            HStack {
                                Text("Change App Icon").foregroundStyle(.white)
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.gray)
                            }
                            .padding()
                            .background(.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                        }
                        ComingSoonButton(feature: "AI Life Coach")
                        ComingSoonButton(feature: "Coach Marketplace")

                        Button("Sign Out") { try? auth.signOut() }
                            .foregroundStyle(.red).padding(.top, 30)
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task {
            guard let uid = auth.currentUser?.uid else { return }
            user = try? await firestore.getUser(id: uid)
            referralCount = (try? await firestore.getReferralCount(userId: uid)) ?? 0
        }
    }

    private func shareReferralLink(code: String) {
        let url = "https://cosmos.app/join?ref=\(code)"
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
    }
}

struct StatItem: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.bold()).foregroundStyle(.white)
            Text(label).font(.caption).foregroundStyle(.gray)
        }
    }
}

struct ComingSoonButton: View {
    let feature: String
    var body: some View {
        HStack {
            Text(feature).foregroundStyle(.white)
            Spacer()
            Text("Coming Soon").font(.caption.bold()).foregroundStyle(.orange)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.orange.opacity(0.2)).clipShape(Capsule())
        }
        .padding()
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}
