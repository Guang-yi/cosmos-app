import SwiftUI

struct CosmosScoreView: View {
    let score: CosmosScore?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.system(size: 50))
                .foregroundStyle(flameColor)

            if let score {
                Text("\(score.total)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("\(score.objectivesCompleted)/\(score.objectivesSet) objectives")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
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
