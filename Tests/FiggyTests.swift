import XCTest
import UIKit
import ZIPFoundation
@testable import Figgy

final class FiggyTests: XCTestCase {
    var root: URL!
    var store: StickerStore!
    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        store = StickerStore(root: root)
    }
    override func tearDownWithError() throws { try? FileManager.default.removeItem(at: root) }
    func testAltStoreProvisionedGroupsTakePriorityWithoutDuplicates() {
        XCTAssertEqual(StickerStore.appGroupCandidates(info: [
            "ALTAppGroups": ["group.signed.figgy", "group.signed.figgy", ""],
            "FiggyAppGroup": "group.original.figgy"
        ]), ["group.signed.figgy", "group.original.figgy"])
        XCTAssertEqual(StickerStore.appGroupCandidates(info: ["FiggyAppGroup": "group.xcode.figgy"]),
                       ["group.xcode.figgy"])
        XCTAssertEqual(StickerStore.appGroupCandidates(info: [:]), ["group.com.julia.figgy"])
    }
    func image() -> UIImage {
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 512, height: 512), format: format).image { c in
            UIColor.red.setFill(); c.fill(CGRect(x: 0, y: 0, width: 512, height: 512))
            UIColor.blue.setFill(); c.fill(CGRect(x: 0, y: 0, width: 40, height: 40))
            UIColor.green.setFill(); c.fill(CGRect(x: 472, y: 472, width: 40, height: 40))
        }
    }
    func pixel(_ image: UIImage, x: Int, y: Int) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: 4)
        bytes.withUnsafeMutableBytes { raw in
            let c = CGContext(data: raw.baseAddress, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            c.translateBy(x: -CGFloat(x), y: -CGFloat(y)); c.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: 512, height: 512))
        }
        return bytes
    }
    func testWholeImagePreservesBothCorners() throws {
        var options = EditorOptions(); options.padding = 0
        let before = image(); let after = ImageProcessor.draw(before, options: options)
        XCTAssertEqual(pixel(before, x: 10, y: 10), pixel(after, x: 10, y: 10))
        XCTAssertEqual(pixel(before, x: 490, y: 490), pixel(after, x: 490, y: 490))
    }
    func testWhatsAppEncodingDimensionsLimitAndOrientation() throws {
        let original = image()
        let data = try ImageProcessor.whatsappWebP(original)
        XCTAssertLessThanOrEqual(data.count, 100_000)
        let decoded = try ImageProcessor.decode(data)
        XCTAssertEqual(decoded.size, CGSize(width: 512, height: 512))
        let beforeTop = pixel(original, x: 20, y: 20)
        let afterTop = pixel(decoded, x: 20, y: 20)
        for c in 0..<3 { XCTAssertLessThan(abs(Int(beforeTop[c]) - Int(afterTop[c])), 40) }
    }
    func testPortablePackRoundTrip() throws {
        let pack = try store.create(name: "Meu pack")
        let png = try ImageProcessor.applePNG(image())
        try store.add(png: png, title: "Inteira", emojis: ["💜"], to: pack.id)
        let loaded = try XCTUnwrap(store.load().first)
        let url = try PackTransfer.export(loaded, store: store); defer { try? FileManager.default.removeItem(at: url) }
        let imported = try PackTransfer.importFile(url, store: store)
        XCTAssertEqual(imported.packs.count, 1)
        XCTAssertEqual(imported.packs.first?.stickers.first?.title, "Inteira")
        XCTAssertEqual(imported.packs.first?.stickers.first?.emojis, ["💜"])
        XCTAssertEqual(try store.load().count, 2)
    }
    func testThirtyStickerLimitDoesNotMutateOnFailure() throws {
        let p = try store.create(name: "Limite")
        let data = try ImageProcessor.applePNG(image())
        for _ in 0..<30 { try store.add(png: data, title: "a", to: p.id) }
        XCTAssertThrowsError(try store.add(png: data, title: "extra", to: p.id))
        XCTAssertEqual(try store.load().first?.stickers.count, 30)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(at: store.images, includingPropertiesForKeys: nil).count, 30)
    }
    func testMalformedPackIsRejectedWithoutWrites() throws {
        let url = root.appendingPathExtension("figpack"); defer { try? FileManager.default.removeItem(at: url) }
        let archive = try Archive(url: url, accessMode: .create)
        let manifest = PortableManifest(name: "Unsafe", author: "x", color: "FFFFFF",
            stickers: [PortableSticker(file: "../../outside.png", title: "x", emojis: [])])
        let data = try JSONEncoder().encode(manifest)
        try archive.addEntry(with: "manifest.json", type: .file, uncompressedSize: Int64(data.count)) { pos, size in
            data.subdata(in: Int(pos)..<min(Int(pos)+size, data.count))
        }
        XCTAssertThrowsError(try PackTransfer.importFile(url, store: store))
        XCTAssertEqual(try store.load().count, 0)
    }
    func testCatalogInstallIsIdempotent() throws {
        let data = try ImageProcessor.applePNG(image())
        _ = try store.install(name: "Original", author: "Figgy", color: "A78BFA", content: [(data, "a", [])], sourceID: "a")
        _ = try store.install(name: "Original", author: "Figgy", color: "A78BFA", content: [(data, "a", [])], sourceID: "a")
        XCTAssertEqual(try store.load().count, 1)
    }
    func testDeleteRemovesOnlySelectedSticker() throws {
        let p = try store.create(name: "Delete")
        let data = try ImageProcessor.applePNG(image())
        try store.add(png: data, title: "a", to: p.id); try store.add(png: data, title: "b", to: p.id)
        let before = try XCTUnwrap(store.load().first)
        try store.deleteSticker(before.stickers[0].id, from: p.id)
        let after = try XCTUnwrap(store.load().first)
        XCTAssertEqual(after.stickers.map(\.title), ["b"])
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.imageURL(before.stickers[0]).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.imageURL(before.stickers[1]).path))
    }
}
