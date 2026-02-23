# Cosmos Phase 1 (MVP) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the core Cosmos iOS app with voice onboarding, daily check-in loop, Cosmos Score, streaks, quotes, flame widget, changeable app icon, referral system, and Community Roadmap placeholders.

**Architecture:** SwiftUI iOS app using the Observation framework for state management, Firebase (Auth, Firestore, Cloud Functions) as backend, Claude API for AI features, HealthKit/Whoop/Oura for health data. MVVM pattern with service layer abstractions.

**Tech Stack:** Swift 5.9+, SwiftUI, WidgetKit, HealthKit, Speech framework, Firebase iOS SDK, Cloud Functions (TypeScript), Claude API

**Design doc:** `docs/plans/2026-02-22-cosmos-design.md`

---

## Task 1: Xcode Project Setup

**Files:**
- Create: `Cosmos.xcodeproj` (via Xcode project generation)
- Create: `Cosmos/CosmosApp.swift`
- Create: `Cosmos/ContentView.swift`
- Create: `Cosmos/Info.plist` entitlements for HealthKit, Speech, Push Notifications

**Step 1: Create the Xcode project**

Use `swift package init` or Xcode CLI to scaffold an iOS app target named "Cosmos" with SwiftUI lifecycle. Minimum deployment target: iOS 17.0.

```swift
// CosmosApp.swift
import SwiftUI
import FirebaseCore

@main
struct CosmosApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**Step 2: Add Swift Package dependencies**

Add via Package.swift or Xcode SPM:
- `firebase-ios-sdk` (Auth, Firestore, Functions, Messaging, Storage, Analytics)
- No third-party UI libraries — keep it native SwiftUI

**Step 3: Configure Info.plist entitlements**

Add usage descriptions:
- `NSHealthShareUsageDescription` — "Cosmos uses your health data to compute your daily Cosmos Score."
- `NSSpeechRecognitionUsageDescription` — "Cosmos uses speech recognition for voice onboarding and journaling."
- `NSMicrophoneUsageDescription` — "Cosmos uses the microphone for voice input."

**Step 4: Verify the app builds and runs**

Run: `xcodebuild -scheme Cosmos -destination 'platform=iOS Simulator,name=iPhone 16' build`
Expected: BUILD SUCCEEDED, blank app launches in simulator.

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: scaffold Cosmos Xcode project with Firebase and entitlements"
```

---

## Task 2: Firebase Backend Setup

**Files:**
- Create: `Cosmos/GoogleService-Info.plist` (from Firebase console — placeholder for now)
- Create: `functions/package.json`
- Create: `functions/tsconfig.json`
- Create: `functions/src/index.ts`
- Create: `firebase.json`
- Create: `firestore.rules`
- Create: `firestore.indexes.json`

**Step 1: Initialize Firebase in the project**

Run: `firebase init` in project root. Select: Firestore, Functions (TypeScript), Hosting (skip for now), Storage, Emulators.

**Step 2: Write Firestore security rules**

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Check-ins: user can read/write their own
    match /checkIns/{checkInId} {
      allow read, write: if request.auth != null && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
    }

    // Cosmos scores: user can read their own, Cloud Functions can write
    match /cosmosScores/{scoreId} {
      allow read: if request.auth != null && resource.data.userId == request.auth.uid;
    }

    // Dreams: anyone authenticated can read, author can create
    match /dreams/{dreamId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
    }

    // Quotes: anyone authenticated can read
    match /quotes/{quoteId} {
      allow read: if request.auth != null;
    }

    // Feature requests: anyone authenticated can read/create, upvote
    match /featureRequests/{featureId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
    }

    match /featureVotes/{voteId} {
      allow read, create: if request.auth != null;
    }

    // Referrals: user can read their own
    match /referrals/{referralId} {
      allow read: if request.auth != null;
    }
  }
}
```

**Step 3: Set up Cloud Functions entry point**

```typescript
// functions/src/index.ts
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

export const helloWorld = functions.https.onCall(async (data, context) => {
  return { message: "Cosmos backend is alive" };
});
```

**Step 4: Deploy and verify**

Run: `firebase deploy --only firestore:rules,functions`
Expected: Deployment succeeds.

Run emulators locally: `firebase emulators:start`
Expected: Emulators start for Firestore and Functions.

**Step 5: Commit**

```bash
git add firebase.json firestore.rules firestore.indexes.json functions/
git commit -m "feat: initialize Firebase backend with Firestore rules and Cloud Functions"
```

---

## Task 3: Data Models (Swift)

**Files:**
- Create: `Cosmos/Models/User.swift`
- Create: `Cosmos/Models/CheckIn.swift`
- Create: `Cosmos/Models/CosmosScore.swift`
- Create: `Cosmos/Models/Dream.swift`
- Create: `Cosmos/Models/Quote.swift`
- Create: `Cosmos/Models/FeatureRequest.swift`
- Create: `Cosmos/Models/Referral.swift`
- Test: `CosmosTests/Models/CosmosScoreTests.swift`

**Step 1: Write the failing test for CosmosScore computation**

```swift
// CosmosTests/Models/CosmosScoreTests.swift
import Testing
@testable import Cosmos

@Test func cosmosScoreComputesFromThreePillars() {
    let score = CosmosScore.compute(
        body: HealthData(sleepScore: 80, recoveryScore: 70, activityScore: 90),
        mind: MindData(streakDays: 10, journalCompleted: true, moodTrend: .positive, reflectionDepth: .detailed),
        path: PathData(objectivesSet: 3, objectivesCompleted: 2)
    )
    // Body: avg(80,70,90) = 80 → 80% of 30 = 24
    // Mind: streak(10pts) + journal(10pts) + mood(5pts) + reflection(5pts) = 30 → 30
    // Path: 2/3 × 40 = 26.67
    #expect(score.body == 24)
    #expect(score.mind == 30)
    #expect(score.path >= 26 && score.path <= 27)
    #expect(score.total >= 80 && score.total <= 81)
}

@Test func cosmosScoreHandlesMissingHealthData() {
    let score = CosmosScore.compute(
        body: HealthData(sleepScore: nil, recoveryScore: nil, activityScore: nil),
        mind: MindData(streakDays: 1, journalCompleted: true, moodTrend: .neutral, reflectionDepth: .brief),
        path: PathData(objectivesSet: 3, objectivesCompleted: 3)
    )
    // Body: no data → 0
    // Mind: streak(1pt) + journal(10pts) + mood(0) + reflection(2pts) = 13
    // Path: 3/3 × 40 = 40
    #expect(score.body == 0)
    #expect(score.total == 53)
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme Cosmos -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: FAIL — types don't exist yet.

**Step 3: Write all data models**

```swift
// Cosmos/Models/User.swift
import Foundation
import FirebaseFirestore

struct CosmosUser: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var domain: String
    var dreamGoal: String
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var subscriptionTier: SubscriptionTier = .free
    var referralCode: String = UUID().uuidString.prefix(8).lowercased()
    var createdAt: Date = Date()

    enum SubscriptionTier: String, Codable {
        case free, premium
    }
}
```

```swift
// Cosmos/Models/CheckIn.swift
import Foundation
import FirebaseFirestore

struct CheckIn: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var date: Date
    var objectives: [Objective]
    var journalPrompt: String
    var journalResponse: String
    var createdAt: Date = Date()

    struct Objective: Codable {
        var text: String
        var completed: Bool
    }
}
```

```swift
// Cosmos/Models/CosmosScore.swift
import Foundation
import FirebaseFirestore

struct CosmosScore: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var date: Date
    var body: Int
    var mind: Int
    var path: Int
    var total: Int
    var createdAt: Date = Date()

    static func compute(body bodyData: HealthData, mind mindData: MindData, path pathData: PathData) -> CosmosScore {
        let bodyScore = bodyData.computeScore()
        let mindScore = mindData.computeScore()
        let pathScore = pathData.computeScore()
        return CosmosScore(
            userId: "",
            date: Date(),
            body: bodyScore,
            mind: mindScore,
            path: pathScore,
            total: bodyScore + mindScore + pathScore
        )
    }
}

struct HealthData {
    var sleepScore: Int?
    var recoveryScore: Int?
    var activityScore: Int?

    func computeScore() -> Int {
        let scores = [sleepScore, recoveryScore, activityScore].compactMap { $0 }
        guard !scores.isEmpty else { return 0 }
        let avg = scores.reduce(0, +) / scores.count
        return Int(Double(avg) / 100.0 * 30.0)
    }
}

struct MindData {
    var streakDays: Int
    var journalCompleted: Bool
    var moodTrend: MoodTrend
    var reflectionDepth: ReflectionDepth

    enum MoodTrend { case negative, neutral, positive }
    enum ReflectionDepth { case none, brief, detailed }

    func computeScore() -> Int {
        let streakPts = min(streakDays, 10)
        let journalPts = journalCompleted ? 10 : 0
        let moodPts: Int = switch moodTrend {
            case .positive: 5
            case .neutral: 0
            case .negative: 0
        }
        let reflectionPts: Int = switch reflectionDepth {
            case .detailed: 5
            case .brief: 2
            case .none: 0
        }
        return min(streakPts + journalPts + moodPts + reflectionPts, 30)
    }
}

struct PathData {
    var objectivesSet: Int
    var objectivesCompleted: Int

    func computeScore() -> Int {
        guard objectivesSet > 0 else { return 0 }
        return Int((Double(objectivesCompleted) / Double(objectivesSet)) * 40.0)
    }
}
```

```swift
// Cosmos/Models/Dream.swift
import Foundation
import FirebaseFirestore

struct Dream: Codable, Identifiable {
    @DocumentID var id: String?
    var authorId: String
    var dreamText: String
    var encouragements: [String] = []
    var createdAt: Date = Date()
}
```

```swift
// Cosmos/Models/Quote.swift
import Foundation
import FirebaseFirestore

struct Quote: Codable, Identifiable {
    @DocumentID var id: String?
    var personName: String
    var quote: String
    var category: String
    var source: String?
    var personBio: String?
}
```

```swift
// Cosmos/Models/FeatureRequest.swift
import Foundation
import FirebaseFirestore

struct FeatureRequest: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var authorId: String
    var status: Status = .suggested
    var voteCount: Int = 0
    var createdAt: Date = Date()

    enum Status: String, Codable {
        case suggested, underReview, inProgress, shipped
    }
}

struct FeatureVote: Codable, Identifiable {
    @DocumentID var id: String?
    var featureId: String
    var userId: String
    var createdAt: Date = Date()
}
```

```swift
// Cosmos/Models/Referral.swift
import Foundation
import FirebaseFirestore

struct Referral: Codable, Identifiable {
    @DocumentID var id: String?
    var referrerId: String
    var referredUserId: String
    var createdAt: Date = Date()
}
```

**Step 4: Run tests to verify they pass**

Run: `xcodebuild test -scheme Cosmos -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: PASS

**Step 5: Commit**

```bash
git add Cosmos/Models/ CosmosTests/
git commit -m "feat: add data models with Cosmos Score computation and tests"
```

---

## Task 4: Firebase Service Layer

**Files:**
- Create: `Cosmos/Services/AuthService.swift`
- Create: `Cosmos/Services/FirestoreService.swift`
- Create: `Cosmos/Services/HealthService.swift`

**Step 1: Write AuthService**

```swift
// Cosmos/Services/AuthService.swift
import Foundation
import FirebaseAuth
import AuthenticationServices

@Observable
class AuthService {
    var currentUser: FirebaseAuth.User?
    var isAuthenticated: Bool { currentUser != nil }

    init() {
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
```

**Step 2: Write FirestoreService**

```swift
// Cosmos/Services/FirestoreService.swift
import Foundation
import FirebaseFirestore

@Observable
class FirestoreService {
    private let db = Firestore.firestore()

    // MARK: - User

    func saveUser(_ user: CosmosUser) async throws {
        guard let id = user.id else { return }
        try db.collection("users").document(id).setData(from: user)
    }

    func getUser(id: String) async throws -> CosmosUser? {
        try await db.collection("users").document(id).getDocument(as: CosmosUser.self)
    }

    // MARK: - Check-Ins

    func saveCheckIn(_ checkIn: CheckIn) async throws {
        try db.collection("checkIns").addDocument(from: checkIn)
    }

    func getCheckIns(userId: String, limit: Int = 30) async throws -> [CheckIn] {
        let snapshot = try await db.collection("checkIns")
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .limit(to: limit)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: CheckIn.self) }
    }

    // MARK: - Cosmos Scores

    func saveCosmosScore(_ score: CosmosScore) async throws {
        try db.collection("cosmosScores").addDocument(from: score)
    }

    func getCosmosScores(userId: String, limit: Int = 30) async throws -> [CosmosScore] {
        let snapshot = try await db.collection("cosmosScores")
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .limit(to: limit)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: CosmosScore.self) }
    }

    // MARK: - Quotes

    func getRandomQuotes(count: Int = 5) async throws -> [Quote] {
        let snapshot = try await db.collection("quotes")
            .limit(to: count)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Quote.self) }
    }

    // MARK: - Feature Requests

    func getFeatureRequests() async throws -> [FeatureRequest] {
        let snapshot = try await db.collection("featureRequests")
            .order(by: "voteCount", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: FeatureRequest.self) }
    }

    func submitFeatureRequest(_ request: FeatureRequest) async throws {
        try db.collection("featureRequests").addDocument(from: request)
    }

    func upvoteFeature(featureId: String, userId: String) async throws {
        let vote = FeatureVote(featureId: featureId, userId: userId)
        try db.collection("featureVotes").addDocument(from: vote)
        // Increment vote count
        try await db.collection("featureRequests").document(featureId)
            .updateData(["voteCount": FieldValue.increment(Int64(1))])
    }

    // MARK: - Referrals

    func createReferral(referrerId: String, referredUserId: String) async throws {
        let referral = Referral(referrerId: referrerId, referredUserId: referredUserId)
        try db.collection("referrals").addDocument(from: referral)
    }

    func getReferralCount(userId: String) async throws -> Int {
        let snapshot = try await db.collection("referrals")
            .whereField("referrerId", isEqualTo: userId)
            .getDocuments()
        return snapshot.count
    }
}
```

**Step 3: Write HealthService**

```swift
// Cosmos/Services/HealthService.swift
import Foundation
import HealthKit

@Observable
class HealthService {
    private let store = HKHealthStore()
    var isAuthorized = false

    func requestAuthorization() async throws {
        let readTypes: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        ]
        try await store.requestAuthorization(toShare: [], read: readTypes)
        isAuthorized = true
    }

    func getTodayHealthData() async throws -> HealthData {
        let sleep = try await fetchSleepScore()
        let activity = try await fetchActivityScore()
        // Recovery approximated from HRV if Whoop/Oura not connected
        let recovery = try await fetchRecoveryScore()
        return HealthData(sleepScore: sleep, recoveryScore: recovery, activityScore: activity)
    }

    private func fetchSleepScore() async throws -> Int? {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: now)
        let samples = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<[HKCategorySample], Error>) in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, error in
                if let error { cont.resume(throwing: error) }
                else { cont.resume(returning: results as? [HKCategorySample] ?? []) }
            }
            store.execute(query)
        }

        let asleepSamples = samples.filter { $0.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
            $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
            $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
            $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue }
        let totalSleep = asleepSamples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
        let hours = totalSleep / 3600.0

        // Score: 8 hours = 100, scale linearly
        return min(Int((hours / 8.0) * 100.0), 100)
    }

    private func fetchActivityScore() async throws -> Int? {
        let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date())

        let calories = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Double, Error>) in
            let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, error in
                if let error { cont.resume(throwing: error) }
                else { cont.resume(returning: stats?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0) }
            }
            store.execute(query)
        }

        // Score: 500 cal = 100, scale linearly
        return min(Int((calories / 500.0) * 100.0), 100)
    }

    private func fetchRecoveryScore() async throws -> Int? {
        let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date())

        let hrv = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Double, Error>) in
            let query = HKStatisticsQuery(quantityType: hrvType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, stats, error in
                if let error { cont.resume(throwing: error) }
                else { cont.resume(returning: stats?.averageQuantity()?.doubleValue(for: .secondUnit(with: .milli)) ?? 0) }
            }
            store.execute(query)
        }

        // Score: HRV 60ms+ = 100, scale linearly
        guard hrv > 0 else { return nil }
        return min(Int((hrv / 60.0) * 100.0), 100)
    }
}
```

**Step 4: Verify build**

Run: `xcodebuild -scheme Cosmos -destination 'platform=iOS Simulator,name=iPhone 16' build`
Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add Cosmos/Services/
git commit -m "feat: add Auth, Firestore, and Health service layers"
```

---

## Task 5: Authentication Flow UI

**Files:**
- Create: `Cosmos/Views/Auth/SignInView.swift`
- Modify: `Cosmos/ContentView.swift`

**Step 1: Write SignInView with Apple Sign In**

```swift
// Cosmos/Views/Auth/SignInView.swift
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
                        if case .success(let auth) = result,
                           let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                            try await self.auth.signInWithApple(credential: credential)
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
```

**Step 2: Wire up ContentView with auth state**

```swift
// Cosmos/ContentView.swift
import SwiftUI

struct ContentView: View {
    @Environment(AuthService.self) private var auth

    var body: some View {
        if auth.isAuthenticated {
            HomeView()
        } else {
            SignInView()
        }
    }
}
```

**Step 3: Inject services in CosmosApp**

```swift
// CosmosApp.swift — update to inject environment
@main
struct CosmosApp: App {
    @State private var authService = AuthService()
    @State private var firestoreService = FirestoreService()
    @State private var healthService = HealthService()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authService)
                .environment(firestoreService)
                .environment(healthService)
        }
    }
}
```

**Step 4: Verify build**

Run: `xcodebuild -scheme Cosmos -destination 'platform=iOS Simulator,name=iPhone 16' build`
Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add Cosmos/Views/ Cosmos/CosmosApp.swift Cosmos/ContentView.swift
git commit -m "feat: add Apple Sign In auth flow and service injection"
```

---

## Task 6: Voice Onboarding

**Files:**
- Create: `Cosmos/Views/Onboarding/VoiceOnboardingView.swift`
- Create: `Cosmos/Services/SpeechService.swift`
- Create: `Cosmos/Services/ClaudeService.swift`
- Create: `functions/src/claude.ts` (Cloud Function for Claude API calls)

**Step 1: Write SpeechService**

```swift
// Cosmos/Services/SpeechService.swift
import Foundation
import Speech
import AVFoundation

@Observable
class SpeechService {
    var isListening = false
    var transcript = ""

    private var recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
    }

    func startListening() throws {
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, _ in
            if let result {
                self?.transcript = result.bestTranscription.formattedString
            }
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isListening = true
    }

    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        isListening = false
    }
}
```

**Step 2: Write Claude Cloud Function**

```typescript
// functions/src/claude.ts
import * as functions from "firebase-functions";
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic({
  apiKey: functions.config().anthropic.api_key,
});

export const chatWithCoach = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Must be signed in");

  const { messages, systemPrompt } = data;

  const response = await client.messages.create({
    model: "claude-sonnet-4-6-20250514",
    max_tokens: 1024,
    system: systemPrompt || "You are Cosmos, a warm and confident high-performance life coach. You believe deeply in the person you're talking to. Be concise, encouraging, and real — not corporate or overly peppy. Like a mentor who sees their potential.",
    messages,
  });

  return { content: response.content[0].type === "text" ? response.content[0].text : "" };
});
```

**Step 3: Write ClaudeService (iOS side)**

```swift
// Cosmos/Services/ClaudeService.swift
import Foundation
import FirebaseFunctions

@Observable
class ClaudeService {
    private let functions = Functions.functions()

    func chat(messages: [[String: String]], systemPrompt: String? = nil) async throws -> String {
        var data: [String: Any] = ["messages": messages]
        if let systemPrompt { data["systemPrompt"] = systemPrompt }

        let result = try await functions.httpsCallable("chatWithCoach").call(data)
        guard let response = result.data as? [String: Any],
              let content = response["content"] as? String else {
            throw ClaudeError.invalidResponse
        }
        return content
    }

    enum ClaudeError: Error {
        case invalidResponse
    }
}
```

**Step 4: Write VoiceOnboardingView**

```swift
// Cosmos/Views/Onboarding/VoiceOnboardingView.swift
import SwiftUI

struct VoiceOnboardingView: View {
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

    private let questions = [
        "What should I call you?",
        "What's your world? Tech, athletics, arts, business... what's your arena?",
        "If you could fast-forward to the absolute best version of yourself — what does that look like? Don't hold back."
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // Flame mascot
                Image(systemName: "flame.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(flameGradient)
                    .symbolEffect(.breathe)

                // Cosmos speaks
                Text(cosmosMessage)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .animation(.easeInOut, value: cosmosMessage)

                Spacer()

                if step < questions.count {
                    // Voice input area
                    VStack(spacing: 16) {
                        Text(speechService.transcript)
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(minHeight: 60)
                            .padding(.horizontal)

                        HStack(spacing: 30) {
                            // Mic button
                            Button {
                                if speechService.isListening {
                                    speechService.stopListening()
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
                            if !speechService.transcript.isEmpty {
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
                        TextField("Or type here...", text: $speechService.transcript)
                            .textFieldStyle(.plain)
                            .foregroundStyle(.white)
                            .padding()
                            .background(.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 30)
                    }
                } else {
                    // Confirmation
                    Button("Let's go") {
                        Task { await completeOnboarding() }
                    }
                    .font(.headline)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(.white)
                    .clipShape(Capsule())
                }

                Spacer().frame(height: 40)
            }
        }
        .task {
            cosmosMessage = "Hey. I'm Cosmos. I'm here to help you become exactly who you're meant to be.\n\n\(questions[0])"
        }
    }

    private var flameGradient: LinearGradient {
        LinearGradient(colors: [.orange, .yellow], startPoint: .bottom, endPoint: .top)
    }

    private func handleResponse() {
        let response = speechService.transcript
        speechService.stopListening()
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
            cosmosMessage = "So \(userName), you're in \(userDomain) and you want to \(userDreamGoal). That's not a dream — that's a destination. Let's build the road. Starting today."
        }
    }

    private func completeOnboarding() async {
        guard let uid = auth.currentUser?.uid else { return }
        var user = CosmosUser(name: userName, domain: userDomain, dreamGoal: userDreamGoal)
        user.id = uid
        try? await firestore.saveUser(user)
    }
}
```

**Step 5: Verify build**

Run: `xcodebuild -scheme Cosmos -destination 'platform=iOS Simulator,name=iPhone 16' build`
Expected: BUILD SUCCEEDED

**Step 6: Commit**

```bash
git add Cosmos/Views/Onboarding/ Cosmos/Services/SpeechService.swift Cosmos/Services/ClaudeService.swift functions/src/claude.ts
git commit -m "feat: add voice onboarding with Speech framework and Claude integration"
```

---

## Task 7: Home Screen & Daily Check-In

**Files:**
- Create: `Cosmos/Views/Home/HomeView.swift`
- Create: `Cosmos/Views/Home/CheckInView.swift`
- Create: `Cosmos/Views/Home/CosmosScoreView.swift`
- Create: `Cosmos/ViewModels/HomeViewModel.swift`

**Step 1: Write HomeViewModel**

```swift
// Cosmos/ViewModels/HomeViewModel.swift
import Foundation

@Observable
class HomeViewModel {
    var user: CosmosUser?
    var todayScore: CosmosScore?
    var hasCheckedInToday = false
    var todayQuote: Quote?
    var isLoading = true

    private var firestore: FirestoreService
    private var health: HealthService

    init(firestore: FirestoreService, health: HealthService) {
        self.firestore = firestore
        self.health = health
    }

    func loadToday(userId: String) async {
        isLoading = true
        user = try? await firestore.getUser(id: userId)
        let scores = try? await firestore.getCosmosScores(userId: userId, limit: 1)
        if let latest = scores?.first, Calendar.current.isDateInToday(latest.date) {
            todayScore = latest
            hasCheckedInToday = true
        }
        let quotes = try? await firestore.getRandomQuotes(count: 1)
        todayQuote = quotes?.first
        isLoading = false
    }
}
```

**Step 2: Write HomeView**

```swift
// Cosmos/Views/Home/HomeView.swift
import SwiftUI

struct HomeView: View {
    @Environment(AuthService.self) private var auth
    @Environment(FirestoreService.self) private var firestore
    @Environment(HealthService.self) private var health
    @State private var viewModel: HomeViewModel?
    @State private var showCheckIn = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let vm = viewModel, !vm.isLoading {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Cosmos Score card
                            CosmosScoreView(score: vm.todayScore)
                                .padding(.top)

                            // Check-in button
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

                            // Quote of the day
                            if let quote = vm.todayQuote {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("\"\(quote.quote)\"")
                                        .font(.body)
                                        .foregroundStyle(.white)
                                        .italic()
                                    Text("— \(quote.personName)")
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal)
                            }

                            // Streak
                            if let user = vm.user {
                                HStack {
                                    Image(systemName: "flame.fill")
                                        .foregroundStyle(.orange)
                                    Text("\(user.currentStreak) day streak")
                                        .foregroundStyle(.white)
                                        .font(.headline)
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
                    ProgressView()
                        .tint(.orange)
                }
            }
            .navigationTitle("Cosmos")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showCheckIn) {
                CheckInView()
            }
        }
        .task {
            guard let uid = auth.currentUser?.uid else { return }
            let vm = HomeViewModel(firestore: firestore, health: health)
            viewModel = vm
            await vm.loadToday(userId: uid)
        }
    }
}
```

**Step 3: Write CosmosScoreView**

```swift
// Cosmos/Views/Home/CosmosScoreView.swift
import SwiftUI

struct CosmosScoreView: View {
    let score: CosmosScore?

    var body: some View {
        VStack(spacing: 12) {
            // Flame
            Image(systemName: "flame.fill")
                .font(.system(size: 50))
                .foregroundStyle(flameColor)
                .symbolEffect(.breathe)

            if let score {
                Text("\(score.total)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                HStack(spacing: 20) {
                    PillarLabel(name: "Body", value: score.body, max: 30)
                    PillarLabel(name: "Mind", value: score.mind, max: 30)
                    PillarLabel(name: "Path", value: score.path, max: 40)
                }
            } else {
                Text("Ready")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.gray)
                Text("Complete your check-in to see today's score")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal)
    }

    private var flameColor: Color {
        guard let score else { return .gray }
        switch score.total {
        case 0...30: return .red
        case 31...60: return .orange
        case 61...85: return .yellow
        default: return .cyan
        }
    }
}

struct PillarLabel: View {
    let name: String
    let value: Int
    let max: Int

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)/\(max)")
                .font(.headline)
                .foregroundStyle(.white)
            Text(name)
                .font(.caption2)
                .foregroundStyle(.gray)
        }
    }
}
```

**Step 4: Write CheckInView**

```swift
// Cosmos/Views/Home/CheckInView.swift
import SwiftUI

struct CheckInView: View {
    @Environment(AuthService.self) private var auth
    @Environment(FirestoreService.self) private var firestore
    @Environment(HealthService.self) private var health
    @Environment(\.dismiss) private var dismiss

    @State private var objectives: [CheckIn.Objective] = [
        .init(text: "", completed: false),
        .init(text: "", completed: false),
        .init(text: "", completed: false),
    ]
    @State private var journalResponse = ""
    @State private var step: CheckInStep = .objectives
    @State private var isSubmitting = false

    private let journalPrompts = [
        "What's one thing you're proud of today?",
        "What did you learn today?",
        "What's one thing you'd do differently?",
        "What are you grateful for right now?",
    ]

    @State private var todayPrompt = ""

    enum CheckInStep {
        case objectives, journal, confirm
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 24) {
                    switch step {
                    case .objectives:
                        objectivesView
                    case .journal:
                        journalView
                    case .confirm:
                        confirmView
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
                .font(.title2.bold())
                .foregroundStyle(.white)

            ForEach($objectives.indices, id: \.self) { i in
                HStack {
                    Button {
                        objectives[i].completed.toggle()
                    } label: {
                        Image(systemName: objectives[i].completed ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(objectives[i].completed ? .orange : .gray)
                            .font(.title2)
                    }
                    TextField("Objective \(i + 1)", text: $objectives[i].text)
                        .foregroundStyle(.white)
                        .padding()
                        .background(.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            Spacer()

            Button {
                step = .journal
            } label: {
                Text("Next")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var journalView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(todayPrompt)
                .font(.title2.bold())
                .foregroundStyle(.white)

            TextEditor(text: $journalResponse)
                .foregroundStyle(.white)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 150)
                .padding()
                .background(.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer()

            Button {
                step = .confirm
            } label: {
                Text("Next")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var confirmView: some View {
        VStack(spacing: 24) {
            Image(systemName: "flame.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
                .symbolEffect(.bounce)

            Text("Ready to submit?")
                .font(.title2.bold())
                .foregroundStyle(.white)

            let completed = objectives.filter(\.completed).count
            Text("\(completed)/\(objectives.count) objectives completed")
                .foregroundStyle(.gray)

            Spacer()

            Button {
                Task { await submitCheckIn() }
            } label: {
                if isSubmitting {
                    ProgressView().tint(.black)
                } else {
                    Text("Submit Check-In")
                }
            }
            .font(.headline)
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.orange)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .disabled(isSubmitting)
        }
    }

    private func submitCheckIn() async {
        guard let uid = auth.currentUser?.uid else { return }
        isSubmitting = true

        let checkIn = CheckIn(
            userId: uid,
            date: Date(),
            objectives: objectives,
            journalPrompt: todayPrompt,
            journalResponse: journalResponse
        )
        try? await firestore.saveCheckIn(checkIn)

        // Compute Cosmos Score
        let healthData = (try? await health.getTodayHealthData()) ?? HealthData(sleepScore: nil, recoveryScore: nil, activityScore: nil)

        let completedCount = objectives.filter(\.completed).count
        let mindData = MindData(
            streakDays: 1, // TODO: calculate from actual streak
            journalCompleted: !journalResponse.isEmpty,
            moodTrend: .neutral,
            reflectionDepth: journalResponse.count > 100 ? .detailed : journalResponse.count > 20 ? .brief : .none
        )
        let pathData = PathData(objectivesSet: objectives.count, objectivesCompleted: completedCount)

        var score = CosmosScore.compute(body: healthData, mind: mindData, path: pathData)
        score.userId = uid
        score.date = Date()
        try? await firestore.saveCosmosScore(score)

        dismiss()
    }
}
```

**Step 5: Verify build**

Run: `xcodebuild -scheme Cosmos -destination 'platform=iOS Simulator,name=iPhone 16' build`
Expected: BUILD SUCCEEDED

**Step 6: Commit**

```bash
git add Cosmos/Views/Home/ Cosmos/ViewModels/
git commit -m "feat: add home screen, daily check-in flow, and Cosmos Score display"
```

---

## Task 8: Tab Navigation & Remaining Screens

**Files:**
- Create: `Cosmos/Views/MainTabView.swift`
- Create: `Cosmos/Views/Quotes/QuotesView.swift`
- Create: `Cosmos/Views/Roadmap/CommunityRoadmapView.swift`
- Create: `Cosmos/Views/Profile/ProfileView.swift`
- Modify: `Cosmos/ContentView.swift`

**Step 1: Write MainTabView**

```swift
// Cosmos/Views/MainTabView.swift
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "flame.fill") {
                HomeView()
            }
            Tab("Quotes", systemImage: "quote.opening") {
                QuotesView()
            }
            Tab("Village", systemImage: "person.3.fill") {
                ComingSoonView(feature: "Your Village", description: "Connect with accountability partners and share your journey.")
            }
            Tab("Roadmap", systemImage: "map.fill") {
                CommunityRoadmapView()
            }
            Tab("Profile", systemImage: "person.crop.circle") {
                ProfileView()
            }
        }
        .tint(.orange)
    }
}
```

**Step 2: Write QuotesView**

```swift
// Cosmos/Views/Quotes/QuotesView.swift
import SwiftUI

struct QuotesView: View {
    @Environment(FirestoreService.self) private var firestore
    @State private var quotes: [Quote] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if isLoading {
                    ProgressView().tint(.orange)
                } else if quotes.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "quote.opening")
                            .font(.largeTitle)
                            .foregroundStyle(.gray)
                        Text("Quotes coming soon")
                            .foregroundStyle(.gray)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(quotes) { quote in
                                QuoteCard(quote: quote)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Quotes")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task {
            quotes = (try? await firestore.getRandomQuotes(count: 20)) ?? []
            isLoading = false
        }
    }
}

struct QuoteCard: View {
    let quote: Quote

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\"\(quote.quote)\"")
                .font(.body)
                .foregroundStyle(.white)
                .italic()
            HStack {
                Text("— \(quote.personName)")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
                Spacer()
                if let bio = quote.personBio {
                    Text(bio)
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
            }
        }
        .padding()
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
```

**Step 3: Write CommunityRoadmapView**

```swift
// Cosmos/Views/Roadmap/CommunityRoadmapView.swift
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
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Community Roadmap")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showSubmit = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showSubmit) {
                submitSheet
            }
        }
        .task {
            features = (try? await firestore.getFeatureRequests()) ?? []
            isLoading = false
        }
    }

    private var submitSheet: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 20) {
                    TextField("Feature title", text: $newTitle)
                        .foregroundStyle(.white)
                        .padding()
                        .background(.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    TextEditor(text: $newDescription)
                        .foregroundStyle(.white)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 100)
                        .padding()
                        .background(.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button("Submit") {
                        Task { await submitFeature() }
                    }
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Suggest a Feature")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func submitFeature() async {
        guard let uid = auth.currentUser?.uid, !newTitle.isEmpty else { return }
        let request = FeatureRequest(title: newTitle, description: newDescription, authorId: uid)
        try? await firestore.submitFeatureRequest(request)
        newTitle = ""
        newDescription = ""
        showSubmit = false
        features = (try? await firestore.getFeatureRequests()) ?? []
    }

    private func upvote(_ feature: FeatureRequest) async {
        guard let uid = auth.currentUser?.uid, let featureId = feature.id else { return }
        try? await firestore.upvoteFeature(featureId: featureId, userId: uid)
        features = (try? await firestore.getFeatureRequests()) ?? []
    }
}

struct FeatureCard: View {
    let feature: FeatureRequest
    let onUpvote: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onUpvote) {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.headline)
                    Text("\(feature.voteCount)")
                        .font(.caption.bold())
                }
                .foregroundStyle(.orange)
                .frame(width: 50)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(feature.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    StatusBadge(status: feature.status)
                }
                if !feature.description.isEmpty {
                    Text(feature.description)
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .lineLimit(2)
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
        Text(label)
            .font(.caption2.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .clipShape(Capsule())
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
```

**Step 4: Write ProfileView and ComingSoonView**

```swift
// Cosmos/Views/Profile/ProfileView.swift
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
                        // Profile header
                        VStack(spacing: 12) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.orange)

                            if let user {
                                Text(user.name)
                                    .font(.title.bold())
                                    .foregroundStyle(.white)

                                Text(user.domain)
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)

                                Text("\"\(user.dreamGoal)\"")
                                    .font(.body)
                                    .foregroundStyle(.white.opacity(0.7))
                                    .italic()
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.top, 30)

                        // Stats
                        if let user {
                            HStack(spacing: 30) {
                                StatItem(value: "\(user.currentStreak)", label: "Streak")
                                StatItem(value: "\(user.longestStreak)", label: "Best")
                                StatItem(value: "\(referralCount)", label: "Referrals")
                            }
                        }

                        // Referral
                        if let user {
                            Button {
                                shareReferralLink(code: user.referralCode)
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Invite a Friend")
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

                        // App Icon (placeholder)
                        ComingSoonButton(feature: "Change App Icon")

                        // Sign out
                        Button("Sign Out") {
                            try? auth.signOut()
                        }
                        .foregroundStyle(.red)
                        .padding(.top, 30)
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
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.gray)
        }
    }
}

struct ComingSoonButton: View {
    let feature: String

    var body: some View {
        HStack {
            Text(feature)
                .foregroundStyle(.white)
            Spacer()
            Text("Coming Soon")
                .font(.caption.bold())
                .foregroundStyle(.orange)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.orange.opacity(0.2))
                .clipShape(Capsule())
        }
        .padding()
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

struct ComingSoonView: View {
    let feature: String
    let description: String

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundStyle(.orange)

                    Text(feature)
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    Text(description)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Text("Coming Soon")
                        .font(.headline)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.orange.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            .navigationTitle(feature)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
```

**Step 5: Update ContentView to route through onboarding or main tab**

```swift
// Cosmos/ContentView.swift
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
                ProgressView().tint(.orange)
            } else if !hasCompletedOnboarding {
                VoiceOnboardingView()
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
```

**Step 6: Verify build**

Run: `xcodebuild -scheme Cosmos -destination 'platform=iOS Simulator,name=iPhone 16' build`
Expected: BUILD SUCCEEDED

**Step 7: Commit**

```bash
git add Cosmos/Views/ Cosmos/ContentView.swift
git commit -m "feat: add tab navigation, quotes, community roadmap, profile, and routing"
```

---

## Task 9: Flame Widget (WidgetKit)

**Files:**
- Create: `CosmosWidget/CosmosWidget.swift`
- Create: `CosmosWidget/CosmosWidgetBundle.swift`
- Create: `Cosmos/Services/SharedDataService.swift` (App Group shared data)

**Step 1: Create Widget Extension target**

Add a new Widget Extension target called "CosmosWidget" to the Xcode project. Configure an App Group (e.g., `group.com.cosmos.shared`) shared between the main app and widget.

**Step 2: Write SharedDataService for App Group**

```swift
// Cosmos/Services/SharedDataService.swift
import Foundation

struct SharedDataService {
    private static let suiteName = "group.com.cosmos.shared"

    static func saveWidgetData(score: Int?, streak: Int) {
        let defaults = UserDefaults(suiteName: suiteName)
        if let score { defaults?.set(score, forKey: "cosmosScore") }
        defaults?.set(streak, forKey: "currentStreak")
        defaults?.set(Date().timeIntervalSince1970, forKey: "lastUpdated")
    }

    static func getWidgetData() -> (score: Int?, streak: Int, lastUpdated: Date?) {
        let defaults = UserDefaults(suiteName: suiteName)
        let score = defaults?.object(forKey: "cosmosScore") as? Int
        let streak = defaults?.integer(forKey: "currentStreak") ?? 0
        let timestamp = defaults?.double(forKey: "lastUpdated")
        let lastUpdated = timestamp.map { Date(timeIntervalSince1970: $0) }
        return (score, streak, lastUpdated)
    }
}
```

**Step 3: Write the widget**

```swift
// CosmosWidget/CosmosWidget.swift
import WidgetKit
import SwiftUI

struct CosmosEntry: TimelineEntry {
    let date: Date
    let score: Int?
    let streak: Int
}

struct CosmosProvider: TimelineProvider {
    func placeholder(in context: Context) -> CosmosEntry {
        CosmosEntry(date: Date(), score: 75, streak: 7)
    }

    func getSnapshot(in context: Context, completion: @escaping (CosmosEntry) -> Void) {
        let data = SharedDataService.getWidgetData()
        completion(CosmosEntry(date: Date(), score: data.score, streak: data.streak))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CosmosEntry>) -> Void) {
        let data = SharedDataService.getWidgetData()
        let entry = CosmosEntry(date: Date(), score: data.score, streak: data.streak)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct CosmosWidgetView: View {
    let entry: CosmosEntry

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(.black)

            VStack(spacing: 4) {
                // Flame that burns brighter with higher score
                Image(systemName: "flame.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(flameColor)

                // Streak on the "belly"
                Text("\(entry.streak)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.white.opacity(0.2))
                    .clipShape(Capsule())

                if let score = entry.score {
                    Text("\(score)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                } else {
                    Text("Ready")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
            }
        }
    }

    private var flameColor: Color {
        guard let score = entry.score else { return .gray.opacity(0.5) }
        switch score {
        case 0...30: return .red
        case 31...60: return .orange
        case 61...85: return .yellow
        default: return .cyan
        }
    }

    private var flameOpacity: Double {
        guard let score = entry.score else { return 0.4 }
        return 0.4 + (Double(score) / 100.0 * 0.6)
    }
}

struct CosmosWidget: Widget {
    let kind = "CosmosWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CosmosProvider()) { entry in
            CosmosWidgetView(entry: entry)
        }
        .configurationDisplayName("Cosmos Score")
        .description("Track your daily Cosmos Score and streak.")
        .supportedFamilies([.systemSmall])
    }
}
```

```swift
// CosmosWidget/CosmosWidgetBundle.swift
import WidgetKit
import SwiftUI

@main
struct CosmosWidgetBundle: WidgetBundle {
    var body: some Widget {
        CosmosWidget()
    }
}
```

**Step 4: Update check-in to write shared data**

In `CheckInView.submitCheckIn()`, after saving the score, add:
```swift
SharedDataService.saveWidgetData(score: score.total, streak: user?.currentStreak ?? 0)
WidgetCenter.shared.reloadAllTimelines()
```

**Step 5: Verify build**

Run: `xcodebuild -scheme Cosmos -destination 'platform=iOS Simulator,name=iPhone 16' build`
Expected: BUILD SUCCEEDED

**Step 6: Commit**

```bash
git add CosmosWidget/ Cosmos/Services/SharedDataService.swift
git commit -m "feat: add flame widget with Cosmos Score and streak display"
```

---

## Task 10: Seed Quotes Data

**Files:**
- Create: `functions/src/seedQuotes.ts`

**Step 1: Write seed script**

```typescript
// functions/src/seedQuotes.ts
import * as admin from "firebase-admin";

const quotes = [
  { personName: "Tom Brady", quote: "I didn't come this far to only come this far.", category: "mindset", personBio: "7x Super Bowl Champion" },
  { personName: "Kobe Bryant", quote: "Everything negative – pressure, challenges – is all an opportunity for me to rise.", category: "resilience", personBio: "5x NBA Champion, Olympic Gold Medalist" },
  { personName: "Serena Williams", quote: "I really think a champion is defined not by their wins but by how they can recover when they fall.", category: "resilience", personBio: "23x Grand Slam Champion" },
  { personName: "Elon Musk", quote: "When something is important enough, you do it even if the odds are not in your favor.", category: "discipline", personBio: "CEO of Tesla & SpaceX" },
  { personName: "Michael Jordan", quote: "I've failed over and over and over again in my life. And that is why I succeed.", category: "mindset", personBio: "6x NBA Champion, 5x MVP" },
  { personName: "Simone Biles", quote: "I'm not the next Usain Bolt or Michael Phelps. I'm the first Simone Biles.", category: "leadership", personBio: "Most Decorated Gymnast in History" },
  { personName: "Steve Jobs", quote: "Your work is going to fill a large part of your life, and the only way to be truly satisfied is to do what you believe is great work.", category: "craft", personBio: "Co-founder of Apple" },
  { personName: "Muhammad Ali", quote: "I hated every minute of training, but I said, 'Don't quit. Suffer now and live the rest of your life as a champion.'", category: "discipline", personBio: "3x World Heavyweight Champion" },
  { personName: "Oprah Winfrey", quote: "The biggest adventure you can take is to live the life of your dreams.", category: "mindset", personBio: "Media Mogul, Philanthropist" },
  { personName: "David Goggins", quote: "You are in danger of living a life so comfortable and soft that you will die without ever realizing your potential.", category: "discipline", personBio: "Ultramarathon Runner, Navy SEAL" },
  { personName: "Marie Curie", quote: "Nothing in life is to be feared, it is only to be understood.", category: "craft", personBio: "2x Nobel Prize Winner" },
  { personName: "Usain Bolt", quote: "I don't think limits.", category: "mindset", personBio: "8x Olympic Gold Medalist, World Record Holder" },
  { personName: "Nelson Mandela", quote: "It always seems impossible until it's done.", category: "resilience", personBio: "Former President of South Africa, Nobel Laureate" },
  { personName: "Satya Nadella", quote: "Don't be a know-it-all; be a learn-it-all.", category: "leadership", personBio: "CEO of Microsoft" },
  { personName: "Maya Angelou", quote: "We delight in the beauty of the butterfly, but rarely admit the changes it has gone through to achieve that beauty.", category: "resilience", personBio: "Poet, Civil Rights Activist" },
  { personName: "Phil Knight", quote: "The cowards never started and the weak died along the way. That leaves us.", category: "discipline", personBio: "Co-founder of Nike" },
  { personName: "Brené Brown", quote: "Vulnerability is not winning or losing; it's having the courage to show up and be seen when we have no control over the outcome.", category: "mindset", personBio: "Research Professor, Author" },
  { personName: "Jensen Huang", quote: "I was different. But the different in me made me who I am.", category: "leadership", personBio: "CEO of NVIDIA" },
  { personName: "Billie Jean King", quote: "Pressure is a privilege — it only comes to those who earn it.", category: "mindset", personBio: "39x Grand Slam Champion, Equality Pioneer" },
  { personName: "Marcus Aurelius", quote: "The impediment to action advances action. What stands in the way becomes the way.", category: "resilience", personBio: "Roman Emperor, Stoic Philosopher" },
];

export async function seedQuotes() {
  const db = admin.firestore();
  const batch = db.batch();

  for (const quote of quotes) {
    const ref = db.collection("quotes").doc();
    batch.set(ref, quote);
  }

  await batch.commit();
  console.log(`Seeded ${quotes.length} quotes`);
}
```

**Step 2: Add a callable function to trigger seeding**

```typescript
// Add to functions/src/index.ts
import { seedQuotes } from "./seedQuotes";

export const seedInitialQuotes = functions.https.onCall(async (data, context) => {
  await seedQuotes();
  return { success: true, count: 20 };
});
```

**Step 3: Deploy and seed**

Run: `firebase deploy --only functions`
Then trigger the seed function once via Firebase console or a curl call.

**Step 4: Commit**

```bash
git add functions/src/seedQuotes.ts functions/src/index.ts
git commit -m "feat: add initial quotes seed data from elite performers"
```

---

## Task 11: Changeable App Icon

**Files:**
- Create: `Cosmos/Views/Profile/AppIconPickerView.swift`
- Add: App icon variants to `Assets.xcassets`

**Step 1: Add alternate icon assets**

Add icon variants to the Xcode asset catalog:
- `AppIcon` (default — orange flame on black)
- `AppIconBlue` (blue flame)
- `AppIconGold` (gold flame)
- `AppIconCosmic` (cosmic/galaxy flame)

Register alternate icons in Info.plist under `CFBundleIcons > CFBundleAlternateIcons`.

**Step 2: Write AppIconPickerView**

```swift
// Cosmos/Views/Profile/AppIconPickerView.swift
import SwiftUI

struct AppIconPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentIcon = UIApplication.shared.alternateIconName

    private let icons = [
        IconOption(name: nil, display: "Classic", description: "Orange flame"),
        IconOption(name: "AppIconBlue", display: "Ocean", description: "Blue flame"),
        IconOption(name: "AppIconGold", display: "Golden", description: "Gold flame"),
        IconOption(name: "AppIconCosmic", display: "Cosmic", description: "Galaxy flame"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                        ForEach(icons, id: \.display) { icon in
                            Button {
                                setIcon(icon.name)
                            } label: {
                                VStack(spacing: 8) {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.white.opacity(0.1))
                                        .frame(width: 80, height: 80)
                                        .overlay {
                                            Image(systemName: "flame.fill")
                                                .font(.largeTitle)
                                                .foregroundStyle(icon.color)
                                        }
                                        .overlay {
                                            if currentIcon == icon.name {
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(.orange, lineWidth: 3)
                                            }
                                        }

                                    Text(icon.display)
                                        .font(.caption)
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("App Icon")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func setIcon(_ name: String?) {
        UIApplication.shared.setAlternateIconName(name)
        currentIcon = name
    }
}

struct IconOption {
    let name: String?
    let display: String
    let description: String

    var color: Color {
        switch display {
        case "Classic": return .orange
        case "Ocean": return .cyan
        case "Golden": return .yellow
        case "Cosmic": return .purple
        default: return .orange
        }
    }
}
```

**Step 3: Wire into ProfileView**

Replace the `ComingSoonButton(feature: "Change App Icon")` in ProfileView with:
```swift
NavigationLink("Change App Icon", destination: AppIconPickerView())
```

**Step 4: Verify build**

Run: `xcodebuild -scheme Cosmos -destination 'platform=iOS Simulator,name=iPhone 16' build`
Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add Cosmos/Views/Profile/AppIconPickerView.swift
git commit -m "feat: add changeable app icon with multiple flame variants"
```

---

## Summary

| Task | What it delivers |
|---|---|
| 1 | Xcode project scaffold with Firebase + entitlements |
| 2 | Firebase backend: Firestore rules, Cloud Functions |
| 3 | All data models + Cosmos Score computation with tests |
| 4 | Service layer: Auth, Firestore, Health |
| 5 | Apple Sign In authentication flow |
| 6 | Voice onboarding with Speech + Claude |
| 7 | Home screen, daily check-in, Cosmos Score display |
| 8 | Tab navigation, quotes, roadmap, profile, routing |
| 9 | Flame widget (WidgetKit) with score + streak |
| 10 | Seed quotes from elite performers |
| 11 | Changeable app icon |

After all 11 tasks: The complete Phase 1 MVP of Cosmos is functional — voice onboarding, daily check-in loop, Cosmos Score from HealthKit data, streaks, motivational quotes, flame widget, Community Roadmap, referral system, and changeable app icon.
