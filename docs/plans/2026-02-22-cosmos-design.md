# Cosmos — Design Document

> **App Name:** Cosmos
> **Tagline:** Your universe. Your greatness.
> **Platform:** iOS (SwiftUI)
> **Backend:** Firebase (Auth, Firestore, Cloud Functions)
> **AI:** Claude API (Anthropic)
> **Date:** 2026-02-22

---

## Vision

Cosmos is a science-backed, AI-powered elite performance platform for people operating at the top of their field who want to become world-class. Unlike existing motivational apps that are generic, unscientific, and gated behind paywalls, Cosmos offers a free core experience with a coherent methodology, personalized AI coaching, and a supportive community.

The app measures self-actualization through the **Cosmos Score** — a daily metric that combines health data, mental check-ins, and progress toward personal objectives. A flame mascot evolves with the user's journey, and the entire experience is designed for **minimum friction, maximum value**.

---

## Design Principles

1. **Low friction** — every interaction completable in minimal taps
2. **Passive data** — automate everything that can be automated (HealthKit, Whoop, Oura sync automatically)
3. **Encouraging, never punishing** — missed a day? Flame is "ready," not dim
4. **Privacy-first** — anonymous dreams, opt-in everything
5. **Beautiful and delightful** — animations, mascot evolutions, celebrations
6. **No paywall on core value** — the free experience must be excellent on its own
7. **Users as co-creators** — Community Roadmap lets users shape the product

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│                   Cosmos iOS App                │
│                   (SwiftUI)                      │
│                                                  │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────┐ │
│  │ Onboard  │ │  Daily   │ │   AI Coach       │ │
│  │ (Voice)  │ │  Loop    │ │   (Chat UI)      │ │
│  ├──────────┤ ├──────────┤ ├──────────────────┤ │
│  │Community │ │  Cosmos  │ │  Quotes &        │ │
│  │& Village │ │  Score   │ │  Insights        │ │
│  ├──────────┤ ├──────────┤ ├──────────────────┤ │
│  │ Widgets  │ │ Streaks  │ │ Coach Marketplace│ │
│  └──────────┘ └──────────┘ └──────────────────┘ │
│                                                  │
│  ┌──────────────────────────────────────────────┐│
│  │  Local: HealthKit · Speech · WidgetKit       ││
│  └──────────────────────────────────────────────┘│
└─────────────────────┬───────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│              Firebase Backend                    │
│                                                  │
│  Auth ─── Firestore ─── Cloud Functions          │
│   │          │              │                    │
│   │    ┌─────┴─────┐   ┌───┴──────────────┐     │
│   │    │  Users     │   │ Claude API       │     │
│   │    │  Dreams    │   │ Whoop API        │     │
│   │    │  CheckIns  │   │ Oura API         │     │
│   │    │  Streaks   │   │ Cosmos Score     │     │
│   │    │  Messages  │   │ Push Notifs      │     │
│   │    │  Coaches   │   │ Content Moderate │     │
│   │    └───────────┘   └──────────────────┘     │
│                                                  │
│  Cloud Messaging ─── Storage (avatars, audio)    │
└─────────────────────────────────────────────────┘
```

### Tech Stack

| Layer | Technology |
|---|---|
| iOS App | SwiftUI, Observation framework, WidgetKit, HealthKit, Speech framework |
| Auth | Firebase Auth (Apple Sign In, Google, email) |
| Database | Cloud Firestore |
| Backend Logic | Firebase Cloud Functions (TypeScript) |
| AI | Claude API (Anthropic) |
| Health Data | HealthKit + Whoop API + Oura API |
| Push Notifications | Firebase Cloud Messaging |
| File Storage | Firebase Storage (avatars, audio) |
| Analytics | Firebase Analytics + custom events |
| Content Moderation | Claude API (lightweight moderation calls) |
| Speech | iOS Speech framework (STT) + AVSpeechSynthesizer (TTS) |

---

## Data Model (Firestore Collections)

| Collection | Purpose | Key Fields |
|---|---|---|
| `users` | Profile & preferences | name, domain, dreamGoal, voiceProfileData, cosmosScore, currentStreak, subscriptionTier, referralCode |
| `checkIns` | Daily check-ins | userId, date, objectives[], completed[], mood, reflection |
| `cosmosScores` | Historical scores | userId, date, score, healthData, objectiveCompletion, breakdown{body, mind, path} |
| `dreams` | Anonymous dream sharing | authorId (hidden from reads), dreamText, encouragements[], createdAt |
| `partnerships` | Accountability pairs | user1Id, user2Id, status, streakTogether |
| `messages` | Partner messaging | partnershipId, senderId, text, timestamp |
| `coaches` | Coach marketplace listings | name, bio, specialties[], rating, pricePerSession, availability |
| `conversations` | AI coach chat history | userId, messages[], context, createdAt |
| `quotes` | Curated quotes/insights | personName, quote, category, source, personBio |
| `communityPosts` | Village feed posts | authorId, text, reactions{}, createdAt |
| `featureRequests` | Community Roadmap ideas | title, description, authorId, status, voteCount, createdAt |
| `featureVotes` | Upvotes on features | featureId, userId, createdAt |
| `referrals` | Referral tracking | referrerId, referredUserId, createdAt |

---

## Feature Design

### 1. Voice Onboarding (< 2 minutes)

1. App opens → cosmic animation (stars coalescing into flame mascot)
2. Flame speaks: "Hey. I'm Cosmos. I'm here to help you become exactly who you're meant to be. Mind if I ask you a few things?"
3. User taps "Let's go" → microphone opens
4. Three conversational questions (Claude API + Speech-to-Text):
   - "What should I call you?" → name
   - "What's your world? Tech, athletics, arts, business... what's your arena?" → domain
   - "If you could fast-forward to the absolute best version of yourself — what does that look like?" → dream goal
5. Cosmos reflects back: "So [Name], you're in [domain] and you want to [dream goal]. That's not a dream — that's a destination. Let's build the road."
6. User confirms → profile created → HealthKit/Whoop/Oura permission prompts
7. Claude generates personalized first-day objectives based on responses

**Fallback:** Text input always available (accessibility + preference).

---

### 2. Cosmos Score (0–100, computed daily)

Three pillars:

| Pillar | Weight | Source | Measures |
|---|---|---|---|
| **Body** | 30% | HealthKit + Whoop + Oura | Sleep quality, recovery, activity, strain balance |
| **Mind** | 30% | Daily journal + streaks | Consistency, reflection, goal progress, mood trajectory |
| **Path** | 40% | Objective completion | Did you do what YOU said matters in YOUR domain? |

**Path is weighted highest** because Cosmos measures self-actualization, not just health. Completing objectives in your domain is the core of becoming who you want to be.

**Scoring details:**
- **Body (0–30):** Normalized from HealthKit sleep, Whoop recovery, Oura readiness. Adapts to available sources.
- **Mind (0–30):** Streak bonus (up to 10pts), journal completion (10pts), mood trend (5pts), reflection depth (5pts).
- **Path (0–40):** (Objectives completed / objectives set) × 40.

**Visual:**
- Single number (0–100) with flame visualization
- Flame color: red (0–30) → orange (31–60) → gold (61–85) → cosmic blue (86–100)
- Weekly/monthly trend line
- Pillar breakdown on tap

---

### 3. Daily Loop (< 60 seconds)

1. Open app → home shows today's score (or "Ready to check in")
2. Review objectives — 3 objectives, simple toggle: done / not done
3. Quick journal — one rotating prompt, voice or text (30s voice auto-transcribed):
   - "What's one thing you're proud of today?"
   - "What did you learn today?"
   - "What's one thing you'd do differently?"
   - "What are you grateful for right now?"
4. Set tomorrow's objectives — 3 objectives (AI suggests based on patterns + domain)
5. Cosmos Score reveal — animated flame burns to today's score, celebration if above average

---

### 4. Streaks & Retention

| Mechanic | How it works |
|---|---|
| Streak | Consecutive check-in days. Visible everywhere. Widget belly. |
| Quote notifications | 1-2x daily push with quotes from real achievers. Tapping opens app. |
| Partner nudges | Prompt to encourage partner who hasn't checked in. |
| Weekly recap | Sunday evening animated summary — score trend, streaks, highlights. |
| Milestone celebrations | 7, 30, 100, 365-day celebrations with flame evolutions. |

**Flame Mascot Evolutions:**
- Day 1–6: Small spark
- Day 7: Steady flame
- Day 30: Bright torch
- Day 100: Blazing fire
- Day 365: Cosmic supernova

---

### 5. Flame Widget (WidgetKit)

- Flame mascot displayed prominently
- Burns brighter/dimmer based on today's Cosmos Score
- Streak count displayed on mascot's belly (like a jersey number)
- If objectives not yet completed: flame at encouraging "ready" state (not dim)
- Tapping opens directly to daily check-in

---

### 6. Changeable App Icon

- Multiple icon variants (different flame colors/styles)
- Unlockable through milestones
- Standard iOS alternate icon API

---

### 7. Quotes & Insights

- Curated from real achievers: Tom Brady, Olympians, world-changers (not just motivational speakers)
- Categorized: mindset, discipline, resilience, leadership, craft
- Push notifications 1-2x daily
- In-app feed with person bio + context for the quote
- Users can save favorites

---

### 8. Community — "Your Village"

**Accountability Partners:**
- Opt-in matching by domain (or cross-domain)
- See each other's streaks (not full scores — privacy)
- In-app messaging, encouragement-focused
- "Duo streak" for days both partners check in

**Anonymous Dream Feed:**
- Share dreams anonymously
- Encouragement reactions only: flame, star, rocket, heart
- No free-text responses, no downvotes, no profiles visible
- Rotating daily feed

**Community Feed:**
- Posts: wins, reflections, milestones
- Community-curated quotes alongside editorial
- Same encouragement reaction system
- AI-powered content moderation (Claude flags negativity)

---

### 9. Community Roadmap (Dedicated Section)

- Feature cards ranked by upvotes, most wanted at top
- Users can suggest new feature ideas (title + description)
- One tap to upvote
- Status tags: "Suggested" → "Under Review" → "In Progress" → "Shipped!"
- Shipped celebration: card animates, voters get push notification
- Dev team uses this to prioritize what to build next

---

### 10. Referral System

- Unique referral link per user via iOS share sheet
- Referral tracking in Firestore
- "You've invited X friends!" badge
- Reward placeholder for future: streak bonus, cosmetic flame skins, etc.

---

### 11. AI Life Coach (Premium — $14.99/mo)

- Chat interface with flame mascot as avatar
- Claude API via Cloud Functions, long-context conversations
- Prompt-engineered for high-performance coaching (not therapy, not generic)
- Proactive insights: "I noticed your Cosmos Score dipped. Your sleep data shows..."
- Voice mode: speak to coach, get spoken responses
- Remembers conversation history and user context

---

### 12. Human Coach Marketplace (Commission model)

- Coach profiles: bio, specialties, credentials, ratings, price per session
- Booking system (Calendly-style or custom)
- In-app video calls or external link (Zoom/Meet)
- 15-20% platform fee per session
- Separate coach onboarding/application flow

---

## Rollout Phases

### Phase 1 — Core Loop (MVP)
1. Voice onboarding
2. Daily journal/survey check-in
3. Cosmos Score (HealthKit + Whoop + Oura)
4. Streaks
5. Motivational quote notifications
6. Flame widget (streak on belly)
7. Changeable app icon
8. Referral system
9. Community Roadmap (with Coming Soon placeholders for Phase 2-3 features)

### Phase 2 — Your Village
10. Accountability partners + messaging
11. Anonymous dream sharing
12. Community feed
13. Streak leaderboards & challenges

### Phase 3 — Premium
14. AI Life Coach (subscription)
15. Human Coach Marketplace
16. Advanced analytics & Cosmos Score breakdown

---

## Monetization

| Stream | Model | Phase |
|---|---|---|
| AI Life Coach | $14.99/mo subscription | Phase 3 |
| Human Coach Marketplace | 15-20% commission per session | Phase 3 |
| Premium cosmetics | Flame skins, icon packs (future) | TBD |

Core app is free. No paywalls on the habit loop, streaks, community, or Cosmos Score.
