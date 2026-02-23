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
                        Image(systemName: "quote.opening").font(.largeTitle).foregroundStyle(.gray)
                        Text("Quotes coming soon").foregroundStyle(.gray)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(quotes) { quote in
                                QuoteCard(quote: quote)
                            }
                        }.padding()
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
            Text("\"\(quote.quote)\"").font(.body).foregroundStyle(.white).italic()
            HStack {
                Text("— \(quote.personName)").font(.caption.bold()).foregroundStyle(.orange)
                Spacer()
                if let bio = quote.personBio {
                    Text(bio).font(.caption2).foregroundStyle(.gray)
                }
            }
        }
        .padding()
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
