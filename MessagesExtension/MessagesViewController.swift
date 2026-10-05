import UIKit
import Messages

final class MessagesViewController: MSMessagesAppViewController, MSStickerBrowserViewDataSource {
    private let browser = MSStickerBrowserViewController(stickerSize: .medium)
    private var stickers: [MSSticker] = []
    private let empty = UILabel()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        addChild(browser); view.addSubview(browser.view); browser.didMove(toParent: self)
        browser.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            browser.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            browser.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            browser.view.topAnchor.constraint(equalTo: view.topAnchor),
            browser.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        browser.stickerBrowserView.dataSource = self
        empty.text = "Abra o Figgy e salve um pack para ver suas figurinhas aqui."
        empty.numberOfLines = 0; empty.textAlignment = .center; empty.textColor = .secondaryLabel
        empty.font = .preferredFont(forTextStyle: .body); empty.adjustsFontForContentSizeCategory = true
        empty.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(empty)
        NSLayoutConstraint.activate([empty.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            empty.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            empty.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)])
        reload()
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); reload() }
    override func willBecomeActive(with conversation: MSConversation) { super.willBecomeActive(with: conversation); reload() }
    private func reload() {
        let store = StickerStore.shared
        guard store.usesSharedContainer else {
            empty.text = "A biblioteca compartilhada ainda não foi ativada. Configure o App Group no Xcode para usar seus packs no teclado."
            stickers = []; empty.isHidden = false; browser.stickerBrowserView.reloadData(); return
        }
        do {
            let packs = try store.load()
            stickers = packs.flatMap(\.stickers).compactMap { s in
                try? MSSticker(contentsOfFileURL: store.imageURL(s), localizedDescription: s.title.isEmpty ? "Figurinha Figgy" : s.title)
            }
            empty.text = "Abra o Figgy e salve um pack para ver suas figurinhas aqui."
        } catch { stickers = []; empty.text = "Não consegui abrir os packs. Abra o Figgy e tente novamente." }
        empty.isHidden = !stickers.isEmpty; browser.stickerBrowserView.reloadData()
    }
    func numberOfStickers(in stickerBrowserView: MSStickerBrowserView) -> Int { stickers.count }
    func stickerBrowserView(_ stickerBrowserView: MSStickerBrowserView, stickerAt index: Int) -> MSSticker { stickers[index] }
}
