import SwiftUI

struct AppIconPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentIcon = UIApplication.shared.alternateIconName

    private let icons = [
        IconOption(name: nil, display: "Classic", color: .orange),
        IconOption(name: "AppIconBlue", display: "Ocean", color: .cyan),
        IconOption(name: "AppIconGold", display: "Golden", color: .yellow),
        IconOption(name: "AppIconCosmic", display: "Cosmic", color: .purple),
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
    let color: Color
}
