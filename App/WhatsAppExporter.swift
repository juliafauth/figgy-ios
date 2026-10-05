import UIKit

@MainActor
enum WhatsAppExporter {
    static func send(_ pack: StickerPack, store: StickerStore = .shared) async throws {
        guard (3...30).contains(pack.stickers.count) else { throw FiggyError("O WhatsApp exige de 3 a 30 figurinhas por pack. Adicione mais antes de enviar.") }
        let scheme = URL(string: "whatsapp://stickerPack")!
        guard UIApplication.shared.canOpenURL(scheme) else { throw FiggyError("Instale o WhatsApp no iPhone para adicionar esse pack.") }
        let payload = try await Task.detached(priority: .userInitiated) { () throws -> Data in
            var stickers: [[String: Any]] = []
            for s in pack.stickers {
                let image = try ImageProcessor.decode(Data(contentsOf: store.imageURL(s)))
                let webp = try ImageProcessor.whatsappWebP(image)
                stickers.append(["image_data": webp.base64EncodedString(), "emojis": Array(s.emojis.prefix(3)),
                                 "accessibility_text": String(s.title.prefix(125))])
            }
            let first = try ImageProcessor.decode(Data(contentsOf: store.imageURL(pack.stickers[0])))
            let object: [String: Any] = ["identifier": pack.id.uuidString, "name": pack.name, "publisher": pack.author,
                "tray_image": try ImageProcessor.trayPNG(first).base64EncodedString(), "stickers": stickers]
            return try JSONSerialization.data(withJSONObject: object)
        }.value
        UIPasteboard.general.setItems([["net.whatsapp.third-party.sticker-pack": payload]],
            options: [.localOnly: true, .expirationDate: Date(timeIntervalSinceNow: 60)])
        let opened = await withCheckedContinuation { continuation in
            UIApplication.shared.open(scheme, options: [:]) { continuation.resume(returning: $0) }
        }
        guard opened else { throw FiggyError("Não consegui abrir o WhatsApp. Tente novamente.") }
        // This confirms handoff, never installation; WhatsApp asks the person to add the pack.
    }
}
