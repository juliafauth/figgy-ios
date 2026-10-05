import Foundation

struct Sticker: Codable, Identifiable, Equatable {
    var id: UUID
    var filename: String
    var title: String
    var emojis: [String]
}
struct StickerPack: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var author: String
    var color: String
    var stickers: [Sticker]
    var createdAt: Date
    var sourceID: String?
}
struct PackLibrary: Codable { var version = 1; var packs: [StickerPack] = [] }
struct CatalogItem: Codable, Identifiable {
    var id: String
    var name: String
    var author: String
    var category: String
    var color: String
    var files: [String]
    var titles: [String]
}
struct PortableManifest: Codable {
    var format = "figgy-pack"
    var version = 1
    var name: String
    var author: String
    var color: String
    var stickers: [PortableSticker]
}
struct PortableSticker: Codable { var file: String; var title: String; var emojis: [String] }
struct RemoteCatalog: Codable { var version: Int; var packs: [RemotePack] }
struct RemotePack: Codable, Identifiable {
    var id: String; var name: String; var author: String; var category: String
    var color: String; var url: URL
}
struct FiggyError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}
