import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private let status = UILabel()
    private let action = UIButton(type: .system)
    private let cancel = UIButton(type: .system)
    private let spinner = UIActivityIndicatorView(style: .medium)
    private var importing = false
    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = .systemBackground
        let icon = UIImageView(image: UIImage(systemName: "face.smiling.fill"))
        icon.tintColor = UIColor(red: 0.46, green: 0.27, blue: 0.85, alpha: 1); icon.contentMode = .scaleAspectFit
        icon.heightAnchor.constraint(equalToConstant: 56).isActive = true
        let title = UILabel(); title.text = "Salvar no Figgy"; title.font = .preferredFont(forTextStyle: .title1); title.textAlignment = .center
        title.adjustsFontForContentSizeCategory = true
        status.text = "Importe imagens ou packs mantendo a imagem inteira. Suas figurinhas ficam no seu iPhone."
        status.numberOfLines = 0; status.textAlignment = .center; status.font = .preferredFont(forTextStyle: .body)
        status.adjustsFontForContentSizeCategory = true
        action.setTitle("Importar figurinhas", for: .normal); action.addTarget(self, action: #selector(start), for: .touchUpInside)
        action.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        cancel.setTitle("Cancelar", for: .normal); cancel.addTarget(self, action: #selector(finish), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [icon, title, status, spinner, action, cancel])
        stack.axis = .vertical; stack.spacing = 20; stack.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(stack)
        NSLayoutConstraint.activate([stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)])
        if !StickerStore.shared.usesSharedContainer {
            status.text = "A biblioteca compartilhada não foi ativada nesta instalação. Configure o App Group no Xcode, ou abra o arquivo diretamente no app Figgy."
            action.isEnabled = false
        }
    }
    @objc private func finish() { guard !importing else { return }; extensionContext?.completeRequest(returningItems: nil) }
    @objc private func start() {
        guard !importing else { return }; importing = true; action.isEnabled = false; cancel.isEnabled = false
        spinner.startAnimating(); status.text = "Preparando suas figurinhas…"
        Task { await importAttachments() }
    }
    private func importAttachments() async {
        let items = extensionContext?.inputItems as? [NSExtensionItem] ?? []
        let providers = items.flatMap { $0.attachments ?? [] }
        var count = 0; var skipped = 0; var failures: [String] = []
        guard providers.count <= 30 else { complete(count: 0, skipped: 0, failures: ["Selecione até 30 arquivos de cada vez."]); return }
        for provider in providers {
            var local: URL?
            do {
                let url = try await materialize(provider); local = url
                let report = try await Task.detached { try PackTransfer.importFile(url) }.value
                count += report.packs.reduce(0) { $0 + $1.stickers.count }; skipped += report.skipped
            } catch { failures.append(error.localizedDescription) }
            if let local { try? FileManager.default.removeItem(at: local) }
        }
        complete(count: count, skipped: skipped, failures: failures)
    }
    private func complete(count: Int, skipped: Int, failures: [String]) {
        importing = false; spinner.stopAnimating()
        status.text = "\(count) figurinha(s) salva(s). Abra o Figgy para organizar e compartilhar seus packs."
            + (skipped > 0 ? " \(skipped) arquivo(s) incompatível(is) ignorado(s)." : "")
            + (!failures.isEmpty ? "\n\n" + failures.joined(separator: "\n") : "")
        action.setTitle("Concluído", for: .normal); action.removeTarget(self, action: #selector(start), for: .touchUpInside)
        action.addTarget(self, action: #selector(finish), for: .touchUpInside); action.isEnabled = true
        cancel.isHidden = true
    }
    private func materialize(_ provider: NSItemProvider) async throws -> URL {
        let supported = provider.registeredTypeIdentifiers.first { id in
            if id == "com.figgy.stickerpack" { return true }
            guard let type = UTType(id) else { return false }
            return type.conforms(to: .image) || type.conforms(to: .zip)
        }
        if let supported {
            return try await withCheckedThrowingContinuation { continuation in
                provider.loadFileRepresentation(forTypeIdentifier: supported) { url, error in
                    do {
                        if let error { throw error }
                        guard let url else { throw FiggyError("Arquivo indisponível.") }
                        let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                        guard size <= PackTransfer.maxArchiveBytes else { throw FiggyError("O arquivo ultrapassa 30 MB.") }
                        let ext = url.pathExtension.isEmpty ? (UTType(supported)?.preferredFilenameExtension ?? "png") : url.pathExtension
                        let target = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).\(ext)")
                        try FileManager.default.copyItem(at: url, to: target)
                        continuation.resume(returning: target)
                    } catch { continuation.resume(throwing: error) }
                }
            }
        }
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            return try await withCheckedThrowingContinuation { continuation in
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                    do {
                        if let error { throw error }
                        let url: URL?
                        if let value = item as? URL { url = value }
                        else if let data = item as? Data { url = URL(dataRepresentation: data, relativeTo: nil) }
                        else { url = nil }
                        guard let url, url.isFileURL else { throw FiggyError("Selecione uma imagem, ZIP ou .figpack.") }
                        let scoped = url.startAccessingSecurityScopedResource(); defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                        let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                        guard size <= PackTransfer.maxArchiveBytes else { throw FiggyError("O arquivo ultrapassa 30 MB.") }
                        let target = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).\(url.pathExtension)")
                        try FileManager.default.copyItem(at: url, to: target); continuation.resume(returning: target)
                    } catch { continuation.resume(throwing: error) }
                }
            }
        }
        throw FiggyError("O app de origem não compartilhou um arquivo de imagem ou pack. Tente exportar para Arquivos primeiro.")
    }
}
