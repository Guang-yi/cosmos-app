import SwiftUI

struct CommunityRoadmapView: View {
    @Environment(AuthService.self) private var auth
    @Environment(FirestoreService.self) private var firestore
    @State private var features: [FeatureRequest] = []
    @State private var showSubmit = false
    @State private var newTitle = ""
    @State private var newDescription = ""
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if isLoading {
                    ProgressView().tint(.orange)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(features) { feature in
                                FeatureCard(feature: feature) {
                                    Task { await upvote(feature) }
                                }
                            }
                        }.padding()
                    }
                }
            }
            .navigationTitle("Community Roadmap")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showSubmit = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showSubmit) { submitSheet }
        }
        .task { await loadFeatures() }
    }

    private var submitSheet: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 20) {
                    TextField("Feature title", text: $newTitle)
                        .foregroundStyle(.white).padding()
                        .background(.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    TextEditor(text: $newDescription)
                        .foregroundStyle(.white).scrollContentBackground(.hidden)
                        .frame(minHeight: 100).padding()
                        .background(.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Button("Submit") { Task { await submitFeature() } }
                        .font(.headline).foregroundStyle(.black)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(.orange).clipShape(RoundedRectangle(cornerRadius: 16))
                    Spacer()
                }.padding()
            }
            .navigationTitle("Suggest a Feature")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func loadFeatures() async {
        features = (try? await firestore.getFeatureRequests()) ?? []
        isLoading = false
    }

    private func submitFeature() async {
        guard let uid = auth.currentUser?.uid, !newTitle.isEmpty else { return }
        let request = FeatureRequest(title: newTitle, description: newDescription, authorId: uid)
        try? await firestore.submitFeatureRequest(request)
        newTitle = ""; newDescription = ""; showSubmit = false
        await loadFeatures()
    }

    private func upvote(_ feature: FeatureRequest) async {
        guard let uid = auth.currentUser?.uid, let featureId = feature.id else { return }
        try? await firestore.upvoteFeature(featureId: featureId, userId: uid)
        await loadFeatures()
    }
}

struct FeatureCard: View {
    let feature: FeatureRequest
    let onUpvote: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onUpvote) {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.up").font(.headline)
                    Text("\(feature.voteCount)").font(.caption.bold())
                }.foregroundStyle(.orange).frame(width: 50)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(feature.title).font(.headline).foregroundStyle(.white)
                    Spacer()
                    StatusBadge(status: feature.status)
                }
                if !feature.description.isEmpty {
                    Text(feature.description).font(.caption).foregroundStyle(.gray).lineLimit(2)
                }
            }
        }
        .padding()
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct StatusBadge: View {
    let status: FeatureRequest.Status
    var body: some View {
        Text(label).font(.caption2.bold()).foregroundStyle(color)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(color.opacity(0.2)).clipShape(Capsule())
    }
    private var label: String {
        switch status {
        case .suggested: "Suggested"
        case .underReview: "Under Review"
        case .inProgress: "In Progress"
        case .shipped: "Shipped!"
        }
    }
    private var color: Color {
        switch status {
        case .suggested: .gray
        case .underReview: .blue
        case .inProgress: .orange
        case .shipped: .green
        }
    }
}
