import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var packs: [StickerPack] = []
    @Published var catalog: [CatalogItem] = []
    @Published var busy = false
    @Published var error: String?
    @Published var notice: String?
    let store = StickerStore.shared
    init() {
        refresh()
        if let url = Bundle.main.url(forResource: "catalog", withExtension: "json", subdirectory: "Catalog") {
            do { catalog = try JSONDecoder().decode([CatalogItem].self, from: Data(contentsOf: url)) }
            catch { self.error = "Não consegui carregar os packs do Figgy: \(error.localizedDescription)" }
        }
    }
    func refresh() {
        do { packs = try store.load() } catch { self.error = error.localizedDescription }
    }
    func createPack(_ name: String) -> StickerPack? {
        do { let pack = try store.create(name: name); refresh(); return pack }
        catch { self.error = error.localizedDescription; return nil }
    }
    func install(_ item: CatalogItem) async {
        guard !busy else { return }; busy = true; defer { busy = false }
        do {
            _ = try await Task.detached(priority: .userInitiated) { try PackTransfer.installCatalog(item) }.value
            refresh(); notice = "Pack salvo! Abra Meus packs para usar e compartilhar."
        } catch { self.error = error.localizedDescription }
    }
    func importURLs(_ urls: [URL]) async {
        guard !busy else { return }; busy = true; defer { busy = false }
        var imported = 0; var skipped = 0; var problems: [String] = []
        for url in urls {
            do {
                let report = try await Task.detached(priority: .userInitiated) { try PackTransfer.importFile(url) }.value
                imported += report.packs.reduce(0) { $0 + $1.stickers.count }; skipped += report.skipped
            } catch { problems.append("\(url.lastPathComponent): \(error.localizedDescription)") }
        }
        refresh()
        if imported > 0 { notice = "\(imported) figurinha(s) importada(s)." + (skipped > 0 ? " \(skipped) arquivo(s) incompatível(is) ignorado(s)." : "") }
        if !problems.isEmpty { error = problems.joined(separator: "\n") }
    }
    func save(_ image: UIImage, title: String, packID: UUID) async -> Bool {
        guard !busy else { return false }; busy = true; defer { busy = false }
        do {
            let data = try await Task.detached(priority: .userInitiated) { try ImageProcessor.applePNG(image) }.value
            try store.add(png: data, title: title.isEmpty ? "Minha figurinha" : title, to: packID)
            refresh(); notice = "Figurinha salva no seu pack!"; return true
        } catch { self.error = error.localizedDescription; return false }
    }
}
