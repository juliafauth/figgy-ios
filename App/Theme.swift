import SwiftUI

extension Color {
    init(hex: String) {
        let number = UInt64(hex, radix: 16) ?? 0xA78BFA
        self.init(red: Double((number >> 16) & 255) / 255, green: Double((number >> 8) & 255) / 255, blue: Double(number & 255) / 255)
    }
}
enum FiggyStyle {
    static let purple = Color(hex: "7645D9")
    static let pink = Color(hex: "EC7BAC")
    static let mint = Color(hex: "BDE9D1")
    static let background = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
}
struct PrimaryButtonStyle: ButtonStyle {
    var color = FiggyStyle.purple
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).frame(maxWidth: .infinity).padding(.vertical, 16)
            .foregroundStyle(.white).background(color.gradient, in: RoundedRectangle(cornerRadius: 19))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}
struct StickerThumbnail: View {
    let sticker: Sticker
    var body: some View {
        if let image = UIImage(contentsOfFile: StickerStore.shared.imageURL(sticker).path) {
            Image(uiImage: image).resizable().scaledToFit().accessibilityLabel(sticker.title)
        } else {
            Image(systemName: "photo").font(.largeTitle).foregroundStyle(.secondary).accessibilityLabel("Imagem indisponível")
        }
    }
}
struct CatalogThumbnail: View {
    let file: String
    var body: some View {
        if let url = Bundle.main.url(forResource: file, withExtension: nil, subdirectory: "Catalog"), let image = UIImage(contentsOfFile: url.path) {
            Image(uiImage: image).resizable().scaledToFit().accessibilityHidden(true)
        }
    }
}
struct EmptyState: View {
    let icon: String; let title: String; let subtitle: String
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 42)).foregroundStyle(FiggyStyle.purple)
            Text(title).font(.title3.bold())
            Text(subtitle).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }.padding(36).frame(maxWidth: .infinity)
    }
}
struct ActivitySheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: [url], applicationActivities: nil) }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
struct SharedFile: Identifiable { let id = UUID(); let url: URL }
