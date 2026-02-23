import SwiftUI

struct VoiceOnboardingView: View {
    var onComplete: () -> Void = {}

    @Environment(AuthService.self) private var auth
    @Environment(FirestoreService.self) private var firestore
    @State private var speechService = SpeechService()
    @State private var claudeService = ClaudeService()

    @State private var step = 0
    @State private var cosmosMessage = ""
    @State private var userName = ""
    @State private var userDomain = ""
    @State private var userDreamGoal = ""
    @State private var isProcessing = false
    @State private var textInput = ""

    private let questions = [
        "What should I call you?",
        "What's your world? Tech, athletics, arts, business... what's your arena?",
        "If you could fast-forward to the absolute best version of yourself \u{2014} what does that look like? Don't hold back."
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // Flame mascot
                flameIcon

                // Cosmos speaks
                Text(cosmosMessage)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .animation(.easeInOut, value: cosmosMessage)

                Spacer()

                if step < questions.count {
                    // Voice/text input area
                    VStack(spacing: 16) {
                        // Show transcript or text input
                        Text(speechService.isListening ? speechService.transcript : "")
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(minHeight: 40)
                            .padding(.horizontal)

                        HStack(spacing: 30) {
                            // Mic button
                            Button {
                                if speechService.isListening {
                                    speechService.stopListening()
                                    textInput = speechService.transcript
                                } else {
                                    try? speechService.startListening()
                                }
                            } label: {
                                Image(systemName: speechService.isListening ? "mic.fill" : "mic")
                                    .font(.title)
                                    .foregroundStyle(speechService.isListening ? .red : .white)
                                    .frame(width: 60, height: 60)
                                    .background(speechService.isListening ? .red.opacity(0.2) : .white.opacity(0.1))
                                    .clipShape(Circle())
                            }

                            // Next button
                            if !textInput.isEmpty {
                                Button("Next") {
                                    handleResponse()
                                }
                                .font(.headline)
                                .foregroundStyle(.black)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 14)
                                .background(.white)
                                .clipShape(Capsule())
                            }
                        }

                        // Text fallback
                        TextField("Or type here...", text: $textInput)
                            .textFieldStyle(.plain)
                            .foregroundStyle(.white)
                            .padding()
                            .background(.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 30)
                    }
                } else {
                    // Confirmation step
                    Button("Let's go") {
                        Task { await completeOnboarding() }
                    }
                    .font(.headline)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(.white)
                    .clipShape(Capsule())
                    .disabled(isProcessing)
                }

                Spacer().frame(height: 40)
            }
        }
        .task {
            cosmosMessage = "Hey. I'm Cosmos. I'm here to help you become exactly who you're meant to be.\n\n\(questions[0])"
        }
    }

    private func handleResponse() {
        let response = textInput
        speechService.stopListening()
        textInput = ""
        speechService.transcript = ""

        switch step {
        case 0: userName = response
        case 1: userDomain = response
        case 2: userDreamGoal = response
        default: break
        }

        step += 1

        if step < questions.count {
            cosmosMessage = questions[step]
        } else {
            cosmosMessage = "So \(userName), you're in \(userDomain) and you want to \(userDreamGoal).\n\nThat's not a dream \u{2014} that's a destination. Let's build the road. Starting today."
        }
    }

    @ViewBuilder
    private var flameIcon: some View {
        let base = Image(systemName: "flame.fill")
            .font(.system(size: 60))
            .foregroundStyle(
                LinearGradient(colors: [.orange, .yellow], startPoint: .bottom, endPoint: .top)
            )
        if #available(iOS 18.0, *) {
            base.symbolEffect(.breathe)
        } else {
            base
        }
    }

    private func completeOnboarding() async {
        guard let uid = auth.currentUser?.uid else { return }
        isProcessing = true
        var user = CosmosUser(name: userName, domain: userDomain, dreamGoal: userDreamGoal)
        user.id = uid
        try? await firestore.saveUser(user)
        isProcessing = false
        onComplete()
    }
}
