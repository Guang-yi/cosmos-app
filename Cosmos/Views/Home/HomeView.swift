import SwiftUI

struct HomeView: View {
    @Environment(AuthService.self) private var auth
    @Environment(FirestoreService.self) private var firestore
    @State private var viewModel: HomeViewModel?
    @State private var showCheckIn = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let vm = viewModel, !vm.isLoading {
                    ScrollView {
                        VStack(spacing: 24) {
                            CosmosScoreView(score: vm.todayScore)
                                .padding(.top)

                            if !vm.hasCheckedInToday {
                                Button {
                                    showCheckIn = true
                                } label: {
                                    HStack {
                                        Image(systemName: "flame.fill")
                                        Text("Check In")
                                    }
                                    .font(.headline)
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(.orange)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                .padding(.horizontal)
                            }

                            if let quote = vm.todayQuote {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("\"\(quote.quote)\"")
                                        .font(.body).foregroundStyle(.white).italic()
                                    Text("— \(quote.personName)")
                                        .font(.caption).foregroundStyle(.gray)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal)
                            }

                            if let user = vm.user {
                                HStack {
                                    Image(systemName: "flame.fill").foregroundStyle(.orange)
                                    Text("\(user.currentStreak) day streak")
                                        .foregroundStyle(.white).font(.headline)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal)
                            }
                        }
                    }
                } else {
                    ProgressView().tint(.orange)
                }
            }
            .navigationTitle("Cosmos")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showCheckIn) {
                CheckInView {
                    // Reload after check-in
                    if let uid = auth.currentUser?.uid {
                        Task { await viewModel?.loadToday(userId: uid) }
                    }
                }
            }
        }
        .task {
            guard let uid = auth.currentUser?.uid else { return }
            let vm = HomeViewModel(firestore: firestore)
            viewModel = vm
            await vm.loadToday(userId: uid)
        }
    }
}
