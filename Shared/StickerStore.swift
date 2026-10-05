import Foundation
import Darwin

/// Every process uses the same file lock and atomic manifest replacement.
/// Failed changes remove only new files; successful deletions clean up afterwards.
final class StickerStore {
    static let shared = StickerStore()
    let root: URL
    let usesSharedContainer: Bool
    init(root: URL? = nil) {
        if let root { self.root = root; usesSharedContainer = false; return }
        #if FIGGY_LOCAL_ONLY
        let shared: URL? = nil
        #else
        // AltStore writes the provisioned group IDs into every re-signed bundle.
        // The custom build setting still contains the original, unprovisioned ID.
        let shared = Self.appGroupCandidates(info: Bundle.main.infoDictionary ?? [:])
            .lazy.compactMap { FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: $0) }.first
        #endif
        usesSharedContainer = shared != nil
        self.root = (shared ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0])
            .appendingPathComponent("Figgy", isDirectory: true)
    }
    static func appGroupCandidates(info: [String: Any]) -> [String] {
        let provisioned = info["ALTAppGroups"] as? [String] ?? []
        let configured = info["FiggyAppGroup"] as? String ?? "group.com.julia.figgy"
        var seen = Set<String>()
        return (provisioned + [configured]).filter { !$0.isEmpty && seen.insert($0).inserted }
    }
    var images: URL { root.appendingPathComponent("Images", isDirectory: true) }
    func imageURL(_ sticker: Sticker) -> URL { images.appendingPathComponent(sticker.filename) }
    private func prepare() throws {
        try FileManager.default.createDirectory(at: images, withIntermediateDirectories: true)
    }
    private func locked<T>(_ work: () throws -> T) throws -> T {
        try prepare()
        let fd = open(root.appendingPathComponent("library.lock").path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard fd >= 0 else { throw FiggyError("Não foi possível abrir sua biblioteca.") }
        defer { flock(fd, LOCK_UN); close(fd) }
        guard flock(fd, LOCK_EX) == 0 else { throw FiggyError("Sua biblioteca está ocupada. Tente novamente.") }
        return try work()
    }
    private func readUnlocked() throws -> PackLibrary {
        let url = root.appendingPathComponent("library.json")
        guard FileManager.default.fileExists(atPath: url.path) else { return PackLibrary() }
        let value = try JSONDecoder().decode(PackLibrary.self, from: Data(contentsOf: url))
        guard value.version == 1 else { throw FiggyError("Esta biblioteca precisa de uma versão mais nova do Figgy.") }
        return value
    }
    private func writeUnlocked(_ library: PackLibrary) throws {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(library).write(to: root.appendingPathComponent("library.json"), options: .atomic)
    }
    func load() throws -> [StickerPack] { try locked { try readUnlocked().packs } }
    func create(name: String, author: String = "Você", color: String = "A78BFA") throws -> StickerPack {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, clean.count <= 80 else { throw FiggyError("Dê um nome ao pack, com até 80 caracteres.") }
        return try locked {
            var library = try readUnlocked()
            let pack = StickerPack(id: UUID(), name: clean, author: String(author.prefix(80)), color: color,
                                   stickers: [], createdAt: Date(), sourceID: nil)
            library.packs.insert(pack, at: 0); try writeUnlocked(library); return pack
        }
    }
    func add(png: Data, title: String, emojis: [String] = [], to packID: UUID) throws {
        try locked {
            var library = try readUnlocked()
            guard let i = library.packs.firstIndex(where: { $0.id == packID }) else { throw FiggyError("Esse pack não existe mais.") }
            guard library.packs[i].stickers.count < 30 else { throw FiggyError("Um pack comporta até 30 figurinhas. Crie outro para continuar.") }
            let id = UUID(); let filename = "\(id.uuidString).png"
            let url = images.appendingPathComponent(filename)
            try png.write(to: url, options: .atomic)
            do {
                library.packs[i].stickers.append(Sticker(id: id, filename: filename, title: String(title.prefix(125)), emojis: Array(emojis.prefix(3))))
                try writeUnlocked(library)
            } catch { try? FileManager.default.removeItem(at: url); throw error }
        }
    }
    func install(name: String, author: String, color: String, content: [(Data, String, [String])], sourceID: String? = nil) throws -> StickerPack {
        guard (1...30).contains(content.count) else { throw FiggyError("O pack precisa ter de 1 a 30 figurinhas.") }
        return try locked {
            var library = try readUnlocked()
            if let sourceID, let existing = library.packs.first(where: { $0.sourceID == sourceID }) { return existing }
            var added: [URL] = []
            do {
                var stickers: [Sticker] = []
                for (png, title, emojis) in content {
                    let id = UUID(); let filename = "\(id.uuidString).png"; let url = images.appendingPathComponent(filename)
                    try png.write(to: url, options: .atomic); added.append(url)
                    stickers.append(Sticker(id: id, filename: filename, title: String(title.prefix(125)), emojis: Array(emojis.prefix(3))))
                }
                let pack = StickerPack(id: UUID(), name: String(name.prefix(80)), author: String(author.prefix(80)),
                                       color: color, stickers: stickers, createdAt: Date(), sourceID: sourceID)
                library.packs.insert(pack, at: 0); try writeUnlocked(library); return pack
            } catch { added.forEach { try? FileManager.default.removeItem(at: $0) }; throw error }
        }
    }
    func rename(_ packID: UUID, name: String) throws {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count <= 80 else { throw FiggyError("Use um nome de 1 a 80 caracteres.") }
        try locked {
            var library = try readUnlocked()
            guard let i = library.packs.firstIndex(where: { $0.id == packID }) else { return }
            library.packs[i].name = name; try writeUnlocked(library)
        }
    }
    func deleteSticker(_ id: UUID, from packID: UUID) throws {
        try locked {
            var library = try readUnlocked()
            guard let i = library.packs.firstIndex(where: { $0.id == packID }),
                  let s = library.packs[i].stickers.first(where: { $0.id == id }) else { return }
            library.packs[i].stickers.removeAll { $0.id == id }; try writeUnlocked(library)
            try? FileManager.default.removeItem(at: imageURL(s))
        }
    }
    func deletePack(_ id: UUID) throws {
        try locked {
            var library = try readUnlocked()
            guard let pack = library.packs.first(where: { $0.id == id }) else { return }
            library.packs.removeAll { $0.id == id }; try writeUnlocked(library)
            pack.stickers.forEach { try? FileManager.default.removeItem(at: imageURL($0)) }
        }
    }
}
