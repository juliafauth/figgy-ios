import Foundation
import UIKit
import ZIPFoundation

struct ImportReport {
    var packs: [StickerPack] = []
    var skipped = 0
}
enum PackTransfer {
    static let maxArchiveBytes = 30 * 1024 * 1024
    static let maxEntryBytes = 20 * 1024 * 1024
    static func export(_ pack: StickerPack, store: StickerStore = .shared) throws -> URL {
        guard !pack.stickers.isEmpty else { throw FiggyError("Adicione uma figurinha antes de compartilhar.") }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("FiggyShares", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("Figgy-\(pack.id.uuidString)-\(UUID().uuidString.prefix(6)).figpack")
        let archive = try Archive(url: url, accessMode: .create)
        let manifest = PortableManifest(name: pack.name, author: pack.author, color: pack.color,
            stickers: pack.stickers.map { PortableSticker(file: "images/\($0.id.uuidString).png", title: $0.title, emojis: $0.emojis) })
        try add(try JSONEncoder().encode(manifest), path: "manifest.json", archive: archive)
        for s in pack.stickers { try add(Data(contentsOf: store.imageURL(s)), path: "images/\(s.id.uuidString).png", archive: archive) }
        return url
    }
    private static func add(_ data: Data, path: String, archive: Archive) throws {
        try archive.addEntry(with: path, type: .file, uncompressedSize: Int64(data.count), compressionMethod: .deflate) { position, size in
            let start = Int(position); return data.subdata(in: start..<min(start + size, data.count))
        }
    }
    private static func read(_ entry: Entry, archive: Archive, limit: Int) throws -> Data {
        guard entry.type == .file, entry.uncompressedSize <= UInt64(limit) else { throw FiggyError("Esse arquivo excede o limite de importação.") }
        var data = Data()
        _ = try archive.extract(entry) { chunk in
            guard data.count + chunk.count <= limit else { throw FiggyError("O arquivo descompactado é grande demais.") }
            data.append(chunk)
        }
        return data
    }
    static func importFile(_ url: URL, store: StickerStore = .shared) throws -> ImportReport {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard size <= maxArchiveBytes else { throw FiggyError("Use um arquivo de até 30 MB. Divida exportações grandes em partes.") }
        let ext = url.pathExtension.lowercased()
        if ext == "zip" || ext == "figpack" {
            return try importArchive(url, store: store)
        }
        let image = try ImageProcessor.decode(Data(contentsOf: url))
        let data = try ImageProcessor.applePNG(ImageProcessor.draw(image, options: EditorOptions()))
        let p = try store.install(name: "Figurinha importada", author: "Você", color: "A78BFA",
                                  content: [(data, url.deletingPathExtension().lastPathComponent, [])])
        return ImportReport(packs: [p])
    }
    private static func importArchive(_ url: URL, store: StickerStore) throws -> ImportReport {
        let archive = try Archive(url: url, accessMode: .read)
        let entries = Array(archive)
        guard entries.count <= 2_000 else { throw FiggyError("O ZIP contém arquivos demais. Exporte uma conversa menor.") }
        if let entry = archive["manifest.json"] {
            let manifest = try JSONDecoder().decode(PortableManifest.self, from: read(entry, archive: archive, limit: 64_000))
            guard manifest.format == "figgy-pack", manifest.version == 1,
                  (1...30).contains(manifest.stickers.count), !manifest.name.isEmpty,
                  manifest.name.count <= 80, manifest.author.count <= 80 else { throw FiggyError("Esse pack não é compatível com o Figgy.") }
            var content: [(Data, String, [String])] = []
            var seen = Set<String>()
            for s in manifest.stickers {
                guard s.file.range(of: "^images/[A-Za-z0-9_-]+\\.png$", options: .regularExpression) != nil,
                      seen.insert(s.file).inserted, let imageEntry = archive[s.file], s.title.count <= 125,
                      s.emojis.count <= 3 else { throw FiggyError("O pack contém referências inválidas.") }
                let data = try read(imageEntry, archive: archive, limit: 500_000)
                let image = try ImageProcessor.decode(data)
                content.append((try ImageProcessor.applePNG(image), s.title, s.emojis))
            }
            // Validate every asset before writing: malformed packs cannot partially install.
            let pack = try store.install(name: manifest.name, author: manifest.author, color: manifest.color, content: content)
            return ImportReport(packs: [pack])
        }
        let imageEntries = entries.filter { $0.type == .file && ["png", "jpg", "jpeg", "heic", "webp"].contains(URL(fileURLWithPath: $0.path).pathExtension.lowercased()) }
        let whatsapp = imageEntries.filter { URL(fileURLWithPath: $0.path).lastPathComponent.uppercased().contains("STK-") }
        let candidates = whatsapp.isEmpty ? imageEntries : whatsapp
        guard !candidates.isEmpty, candidates.count <= 300 else { throw FiggyError("Não encontrei imagens, ou o ZIP tem mais de 300. Importe uma parte menor.") }
        guard candidates.allSatisfy({ $0.uncompressedSize <= UInt64(maxEntryBytes) }) else { throw FiggyError("Uma imagem descompactada ultrapassa 20 MB.") }
        guard candidates.reduce(UInt64(0), { $0 + $1.uncompressedSize }) <= 60 * 1024 * 1024 else { throw FiggyError("As imagens descompactadas excedem 60 MB.") }
        var report = ImportReport()
        var content: [(Data, String, [String])] = []
        for entry in candidates {
            do {
                let image = try ImageProcessor.decode(read(entry, archive: archive, limit: maxEntryBytes))
                let png = try ImageProcessor.applePNG(ImageProcessor.draw(image, options: EditorOptions()))
                content.append((png, "Figurinha importada", []))
            } catch { report.skipped += 1 }
        }
        guard !content.isEmpty else { throw FiggyError("Nenhuma imagem estática compatível foi encontrada.") }
        for start in stride(from: 0, to: content.count, by: 30) {
            let slice = Array(content[start..<min(start + 30, content.count)])
            report.packs.append(try store.install(name: "Importadas \(start / 30 + 1)", author: "Você", color: "A78BFA", content: slice))
        }
        return report
    }
    static func installCatalog(_ item: CatalogItem, bundle: Bundle = .main, store: StickerStore = .shared) throws -> StickerPack {
        var content: [(Data, String, [String])] = []
        for (index, name) in item.files.enumerated() {
            guard let url = bundle.url(forResource: name, withExtension: nil, subdirectory: "Catalog") else { throw FiggyError("Uma imagem do catálogo não foi encontrada.") }
            let image = try ImageProcessor.decode(Data(contentsOf: url))
            content.append((try ImageProcessor.applePNG(image), index < item.titles.count ? item.titles[index] : item.name, []))
        }
        return try store.install(name: item.name, author: item.author, color: item.color, content: content, sourceID: item.id)
    }
}
