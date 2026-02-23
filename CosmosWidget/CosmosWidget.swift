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
            Color.black

            VStack(spacing: 4) {
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
        .containerBackground(.black, for: .widget)
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
