import UIKit
import ImageIO
import Vision
import CoreImage
import libwebp

struct EditorOptions {
    var text = ""
    var background: UIColor? = nil
    var textColor: UIColor = .white
    var accent: UIColor = UIColor(red: 0.49, green: 0.28, blue: 0.91, alpha: 1)
    var padding: CGFloat = 16
    var textAtTop = false
    var textSize: CGFloat = 46
}

enum ImageProcessor {
    static func decode(_ data: Data) throws -> UIImage {
        guard data.count <= 20 * 1024 * 1024 else { throw FiggyError("A imagem é grande demais. Use um arquivo de até 20 MB.") }
        if let source = CGImageSourceCreateWithData(data as CFData, nil) {
            guard CGImageSourceGetCount(source) == 1 else {
                throw FiggyError("Esta versão cria figurinhas estáticas. Escolha uma imagem sem animação.")
            }
            let options: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: 2048, kCGImageSourceCreateThumbnailWithTransform: true]
            if let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) { return UIImage(cgImage: cg) }
        }
        // libwebp also handles static WebP on OS versions that ImageIO cannot decode.
        return try data.withUnsafeBytes { buffer in
            guard let bytes = buffer.bindMemory(to: UInt8.self).baseAddress else { throw FiggyError("Imagem vazia.") }
            var features = WebPBitstreamFeatures()
            guard WebPGetFeatures(bytes, data.count, &features) == VP8_STATUS_OK,
                  features.has_animation == 0 else { throw FiggyError("WebP inválido ou animado. Use uma figurinha estática.") }
            guard features.width > 0, features.height > 0,
                  Int64(features.width) * Int64(features.height) <= 16_000_000 else { throw FiggyError("A resolução da imagem é grande demais.") }
            var width: Int32 = 0; var height: Int32 = 0
            guard let decoded = WebPDecodeRGBA(bytes, data.count, &width, &height) else { throw FiggyError("Não consegui ler essa imagem.") }
            defer { WebPFree(decoded) }
            let rgba = Data(bytes: decoded, count: Int(width * height * 4))
            guard let provider = CGDataProvider(data: rgba as CFData),
                  let cg = CGImage(width: Int(width), height: Int(height), bitsPerComponent: 8, bitsPerPixel: 32,
                    bytesPerRow: Int(width) * 4, space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue), provider: provider,
                    decode: nil, shouldInterpolate: true, intent: .defaultIntent) else { throw FiggyError("Não consegui converter o WebP.") }
            return UIImage(cgImage: cg)
        }
    }
    static func draw(_ image: UIImage?, options: EditorOptions, size: CGFloat = 512) -> UIImage {
        let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = false
        return UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format).image { context in
            let scale = size / 512
            let rect = CGRect(x: 0, y: 0, width: size, height: size)
            if let background = options.background { background.setFill(); context.fill(rect) }
            let hasText = !options.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let padding = options.padding * scale
            let captionHeight = hasText ? min(180 * scale, max(100 * scale, options.textSize * 2.8 * scale)) : 0
            let available = CGRect(x: padding, y: padding + (hasText && options.textAtTop ? captionHeight : 0),
                width: max(1, size - 2 * padding), height: max(1, size - 2 * padding - captionHeight))
            if let image {
                let ratio = min(available.width / image.size.width, available.height / image.size.height)
                let fitted = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
                image.draw(in: CGRect(x: available.midX - fitted.width / 2, y: available.midY - fitted.height / 2,
                                      width: fitted.width, height: fitted.height))
            }
            if hasText {
                let paragraph = NSMutableParagraphStyle(); paragraph.alignment = .center
                paragraph.lineBreakMode = .byWordWrapping
                var fontSize = options.textSize * scale
                let textRect = CGRect(x: max(padding, 12 * scale),
                    y: options.textAtTop ? padding : size - captionHeight - padding,
                    width: size - 2 * max(padding, 12 * scale), height: captionHeight)
                var attributes: [NSAttributedString.Key: Any] = [:]
                while fontSize >= 14 * scale {
                    attributes = [.font: UIFont.systemFont(ofSize: fontSize, weight: .heavy),
                        .foregroundColor: options.textColor, .paragraphStyle: paragraph,
                        .strokeColor: options.accent, .strokeWidth: -5]
                    let measured = (options.text as NSString).boundingRect(with: CGSize(width: textRect.width, height: .greatestFiniteMagnitude),
                        options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
                    if measured.height <= textRect.height { break }; fontSize -= 2 * scale
                }
                (options.text as NSString).draw(with: textRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
            }
        }
    }
    static func applePNG(_ image: UIImage) throws -> Data {
        // Always fit the entire canvas; never crop or detect a subject implicitly.
        for edge in [CGFloat(512), 480, 448, 384, 320, 300] {
            var options = EditorOptions(); options.padding = 0
            if let png = draw(image, options: options, size: edge).pngData(), png.count < 500_000 { return png }
        }
        throw FiggyError("Não consegui reduzir a imagem para o limite do iPhone.")
    }
    static func whatsappWebP(_ image: UIImage) throws -> Data {
        var options = EditorOptions(); options.padding = 8
        let square = draw(image, options: options)
        guard let cg = square.cgImage else { throw FiggyError("Imagem inválida.") }
        var pixels = [UInt8](repeating: 0, count: 512 * 512 * 4)
        let rendered = pixels.withUnsafeMutableBytes { raw -> Bool in
            guard let context = CGContext(data: raw.baseAddress, width: 512, height: 512, bitsPerComponent: 8,
                bytesPerRow: 512 * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue) else { return false }
            context.draw(cg, in: CGRect(x: 0, y: 0, width: 512, height: 512)); return true
        }
        guard rendered else { throw FiggyError("Não consegui preparar a figurinha.") }
        // CGContext produces premultiplied RGBA; libwebp expects straight RGBA.
        for i in stride(from: 0, to: pixels.count, by: 4) {
            let alpha = Int(pixels[i + 3])
            if alpha > 0 && alpha < 255 {
                for channel in 0..<3 { pixels[i + channel] = UInt8(min(255, (Int(pixels[i + channel]) * 255 + alpha / 2) / alpha)) }
            }
        }
        for quality in [Float(90), 80, 70, 55, 40, 25, 10, 1] {
            let data: Data? = pixels.withUnsafeBufferPointer { buffer in
                var output: UnsafeMutablePointer<UInt8>?
                let count = WebPEncodeRGBA(buffer.baseAddress, 512, 512, 512 * 4, quality, &output)
                guard count > 0, let output else { return nil }
                defer { WebPFree(output) }; return Data(bytes: output, count: count)
            }
            if let data, data.count <= 100_000 { return data }
        }
        throw FiggyError("Essa imagem não cabe no limite do WhatsApp. Tente uma imagem mais simples.")
    }
    static func trayPNG(_ image: UIImage) throws -> Data {
        var options = EditorOptions(); options.padding = 0
        guard let data = draw(image, options: options, size: 96).pngData(), data.count <= 50_000 else { throw FiggyError("Ícone inválido.") }
        return data
    }
    static func removeBackground(_ image: UIImage) throws -> UIImage {
        guard let cg = image.cgImage else { throw FiggyError("Imagem inválida.") }
        let handler = VNImageRequestHandler(cgImage: cg)
        let request = VNGenerateForegroundInstanceMaskRequest()
        try handler.perform([request])
        guard let result = request.results?.first, !result.allInstances.isEmpty else {
            throw FiggyError("Não encontrei um objeto para recortar. Você pode manter a imagem inteira.")
        }
        let buffer = try result.generateMaskedImage(ofInstances: result.allInstances, from: handler, croppedToInstancesExtent: true)
        let ci = CIImage(cvPixelBuffer: buffer)
        guard let output = CIContext().createCGImage(ci, from: ci.extent) else { throw FiggyError("Não consegui remover o fundo.") }
        return UIImage(cgImage: output)
    }
}
