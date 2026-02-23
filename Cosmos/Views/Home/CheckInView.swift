import SwiftUI

struct CheckInView: View {
    @Environment(AuthService.self) private var auth
    @Environment(FirestoreService.self) private var firestore
    @Environment(\.dismiss) private var dismiss
    var onComplete: () -> Void = {}

    @State private var objectives: [CheckIn.Objective] = [
        .init(text: "", completed: false),
        .init(text: "", completed: false),
        .init(text: "", completed: false),
    ]
    @State private var journalResponse = ""
    @State private var step: CheckInStep = .objectives
    @State private var isSubmitting = false
    @State private var todayPrompt = ""

    private let journalPrompts = [
        "What's one thing you're proud of today?",
        "What did you learn today?",
        "What's one thing you'd do differently?",
        "What are you grateful for right now?",
    ]

    enum CheckInStep { case objectives, journal, confirm }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 24) {
                    switch step {
                    case .objectives: objectivesView
                    case .journal: journalView
                    case .confirm: confirmView
                    }
                }
                .padding()
            }
            .navigationTitle("Check In")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.gray)
                }
            }
        }
        .onAppear {
            todayPrompt = journalPrompts.randomElement() ?? journalPrompts[0]
        }
    }

    private var objectivesView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Today's Objectives")
                .font(.title2.bold()).foregroundStyle(.white)

            ForEach(objectives.indices, id: \.self) { i in
                HStack {
                    Button { objectives[i].completed.toggle() } label: {
                        Image(systemName: objectives[i].completed ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(objectives[i].completed ? .orange : .gray)
                            .font(.title2)
                    }
                    TextField("Objective \(i + 1)", text: Binding(
                        get: { objectives[i].text },
                        set: { objectives[i].text = $0 }
                    ))
                    .foregroundStyle(.white)
                    .padding()
                    .background(.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            Spacer()
            Button { step = .journal } label: {
                Text("Next").font(.headline).foregroundStyle(.black)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(.orange).clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var journalView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(todayPrompt).font(.title2.bold()).foregroundStyle(.white)
            TextEditor(text: $journalResponse)
                .foregroundStyle(.white)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 150)
                .padding()
                .background(.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            Spacer()
            Button { step = .confirm } label: {
                Text("Next").font(.headline).foregroundStyle(.black)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(.orange).clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var confirmView: some View {
        VStack(spacing: 24) {
            Image(systemName: "flame.fill")
                .font(.system(size: 60)).foregroundStyle(.orange)

            Text("Ready to submit?").font(.title2.bold()).foregroundStyle(.white)

            let completed = objectives.filter(\.completed).count
            Text("\(completed)/\(objectives.count) objectives completed")
                .foregroundStyle(.gray)

            Spacer()

            Button { Task { await submitCheckIn() } } label: {
                Group {
                    if isSubmitting { ProgressView().tint(.black) }
                    else { Text("Submit Check-In") }
                }
                .font(.headline).foregroundStyle(.black)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(.orange).clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(isSubmitting)
        }
    }

    private func submitCheckIn() async {
        guard let uid = auth.currentUser?.uid else { return }
        isSubmitting = true

        let checkIn = CheckIn(
            userId: uid, date: Date(), objectives: objectives,
            journalPrompt: todayPrompt, journalResponse: journalResponse
        )
        try? await firestore.saveCheckIn(checkIn)

        // Compute Cosmos Score — PATH ONLY
        let completedCount = objectives.filter(\.completed).count
        var score = CosmosScore.compute(objectivesSet: objectives.count, objectivesCompleted: completedCount)
        score.userId = uid
        score.date = Date()
        try? await firestore.saveCosmosScore(score)

        onComplete()
        dismiss()
    }
}
