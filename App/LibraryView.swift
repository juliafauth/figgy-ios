import SwiftUI
import UniformTypeIdentifiers

extension UTType { static let figgyPack = UTType(exportedAs: "com.figgy.stickerpack", conformingTo: .zip) }
struct LibraryView: View {
    @EnvironmentObject var model: AppModel
    @State private var importing = false
    @State private var creating = false
    @State private var name = ""
    @State private var search = ""
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack { Text("Seu cantinho\nde figurinhas.").font(.system(.largeTitle, design: .rounded, weight: .heavy)); Spacer(); Image(systemName: "heart.text.square.fill").font(.system(size: 40)).foregroundStyle(FiggyStyle.pink) }
                    HStack(spacing: 12) {
                        Button { creating = true } label: { Label("Novo pack", systemImage: "plus") }.buttonStyle(PrimaryButtonStyle())
                        Button { importing = true } label: { Label("Importar", systemImage: "square.and.arrow.down") }.buttonStyle(PrimaryButtonStyle(color: Color(hex: "368564")))
                    }
                    if model.packs.isEmpty {
                        EmptyState(icon: "square.stack.3d.up", title: "Seu primeiro pack te espera", subtitle: "Crie um pack, importe suas figurinhas ou baixe um dos packs da aba Explorar.")
                    }
                    ForEach(model.packs.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) }) { pack in
                        NavigationLink { PackDetailView(packID: pack.id) } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack { Text(pack.name).font(.title3.bold()); Spacer(); Image(systemName: "chevron.right").foregroundStyle(.secondary) }
                                Text("\(pack.stickers.count)/30 figurinhas · \(pack.author)").font(.caption).foregroundStyle(.secondary)
                                HStack(spacing: 8) {
                                    ForEach(Array(pack.stickers.prefix(4))) { StickerThumbnail(sticker: $0).frame(maxWidth: .infinity).frame(height: 74) }
                                    if pack.stickers.isEmpty { Text("Adicione sua primeira criação ✨").font(.subheadline).foregroundStyle(.secondary).frame(height: 74) }
                                }.padding(8).background(Color(hex: pack.color).opacity(0.16), in: RoundedRectangle(cornerRadius: 18))
                            }.padding(18).background(FiggyStyle.card, in: RoundedRectangle(cornerRadius: 26))
                        }.buttonStyle(.plain)
                    }
                    Text("Importe imagens, arquivos .figpack ou um ZIP exportado com mídia. Figurinhas animadas não são importadas nesta versão.").font(.footnote).foregroundStyle(.secondary)
                }.padding(20)
            }.background(FiggyStyle.background).navigationTitle("Meus packs").navigationBarTitleDisplayMode(.inline)
                .searchable(text: $search, prompt: "Buscar nos seus packs")
                .alert("Novo pack", isPresented: $creating) {
                    TextField("Nome do pack", text: $name)
                    Button("Criar") { _ = model.createPack(name); name = "" }
                    Button("Cancelar", role: .cancel) { name = "" }
                } message: { Text("Ex.: Minhas reações, Memes da Julia…") }
                .fileImporter(isPresented: $importing, allowedContentTypes: [.figgyPack, .zip, .image, .data], allowsMultipleSelection: true) { result in
                    switch result { case .success(let urls): Task { await model.importURLs(urls) }; case .failure(let error): model.error = error.localizedDescription }
                }
        }
    }
}
struct PackDetailView: View {
    let packID: UUID
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) var dismiss
    @State private var creator = false
    @State private var keyboardHelp = false
    @State private var share: SharedFile?
    @State private var exporting = false
    @State private var renaming = false
    @State private var name = ""
    @State private var deleting = false
    var pack: StickerPack? { model.packs.first { $0.id == packID } }
    var body: some View {
        Group {
            if let pack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        Text(pack.name).font(.system(.largeTitle, design: .rounded, weight: .heavy))
                        HStack { Text("\(pack.stickers.count)/30 figurinhas").foregroundStyle(.secondary); Spacer(); Text("SEU PACK").font(.caption.bold()).foregroundStyle(FiggyStyle.purple) }
                        HStack(spacing: 12) {
                            Button { Task { await send(pack) } } label: { Label("WhatsApp", systemImage: "message.fill") }.buttonStyle(PrimaryButtonStyle(color: Color(hex: "368564"))).disabled(exporting || pack.stickers.count < 3)
                            Button { keyboardHelp = true } label: { Label("iPhone", systemImage: "face.smiling.fill") }.buttonStyle(PrimaryButtonStyle()).disabled(pack.stickers.isEmpty)
                        }
                        if pack.stickers.count < 3 { Text("Adicione pelo menos 3 figurinhas para exportar para o WhatsApp.").font(.footnote).foregroundStyle(.secondary) }
                        if exporting { ProgressView("Preparando o pack para o WhatsApp…") }
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                            ForEach(pack.stickers) { sticker in
                                StickerThumbnail(sticker: sticker).frame(height: 110).padding(10)
                                    .background(FiggyStyle.card, in: RoundedRectangle(cornerRadius: 20))
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            do { try model.store.deleteSticker(sticker.id, from: packID); model.refresh() } catch { model.error = error.localizedDescription }
                                        } label: { Label("Excluir figurinha", systemImage: "trash") }
                                    }
                            }
                            Button { creator = true } label: {
                                VStack(spacing: 10) { Image(systemName: "plus.circle.fill").font(.largeTitle); Text("Criar nova").font(.caption.bold()) }
                                    .frame(maxWidth: .infinity).frame(height: 110).padding(10)
                                    .foregroundStyle(FiggyStyle.purple).background(FiggyStyle.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 20))
                            }.disabled(pack.stickers.count >= 30)
                        }
                        Button { Task { await sharePack(pack) } } label: { Label("Compartilhar este pack", systemImage: "square.and.arrow.up") }.buttonStyle(PrimaryButtonStyle()).disabled(pack.stickers.isEmpty || model.busy)
                        Text("A outra pessoa abre o arquivo .figpack no Figgy para salvar as figurinhas. Você pode enviar por AirDrop, WhatsApp, email ou Arquivos.").font(.footnote).foregroundStyle(.secondary)
                    }.padding(20)
                }.background(FiggyStyle.background)
            } else { EmptyState(icon: "square.stack", title: "Pack indisponível", subtitle: "Volte à biblioteca para escolher outro pack.") }
        }.navigationTitle("Meu pack").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .primaryAction) { Menu {
                Button("Renomear", systemImage: "pencil") { name = pack?.name ?? ""; renaming = true }
                Button("Excluir pack", systemImage: "trash", role: .destructive) { deleting = true }
            } label: { Image(systemName: "ellipsis.circle") } } }
            .sheet(isPresented: $creator) { EditorView(initialPackID: packID) }
            .sheet(isPresented: $keyboardHelp) { KeyboardHelpView() }
            .sheet(item: $share) { ActivitySheet(url: $0.url) }
            .alert("Renomear pack", isPresented: $renaming) {
                TextField("Nome", text: $name)
                Button("Salvar") { do { try model.store.rename(packID, name: name); model.refresh() } catch { model.error = error.localizedDescription } }
                Button("Cancelar", role: .cancel) {}
            }
            .confirmationDialog("Excluir este pack e todas as suas figurinhas?", isPresented: $deleting, titleVisibility: .visible) {
                Button("Excluir pack", role: .destructive) {
                    do { try model.store.deletePack(packID); model.refresh(); dismiss() } catch { model.error = error.localizedDescription }
                }
            }
    }
    private func send(_ pack: StickerPack) async {
        exporting = true; defer { exporting = false }
        do { try await WhatsAppExporter.send(pack) } catch { model.error = error.localizedDescription }
    }
    private func sharePack(_ pack: StickerPack) async {
        model.busy = true; defer { model.busy = false }
        do { share = SharedFile(url: try await Task.detached { try PackTransfer.export(pack) }.value) }
        catch { model.error = error.localizedDescription }
    }
}
struct KeyboardHelpView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var model: AppModel
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Image(systemName: "face.smiling.inverse").font(.system(size: 64)).foregroundStyle(FiggyStyle.purple)
                    Text("Seu pack no teclado.").font(.system(.largeTitle, design: .rounded, weight: .heavy))
                    if model.store.usesSharedContainer {
                        Text("As figurinhas salvas no Figgy ficam disponíveis na extensão do app. Não é preciso recriá-las no Fotos.").foregroundStyle(.secondary)
                        instruction("1", "Abra uma conversa", "Use um app compatível com o painel de stickers do iPhone, como Mensagens.")
                        instruction("2", "Toque no teclado de emojis", "Abra a área de stickers e procure o ícone do Figgy entre os packs/apps.")
                        instruction("3", "Escolha sua figurinha", "Toque para inserir ou arraste quando o app permitir.")
                        Text("Se o Figgy não aparecer, abra Mensagens → + → Stickers e confira os apps disponíveis. Feche e reabra o painel após criar um pack. A compatibilidade varia conforme o app em que você estiver digitando.").font(.footnote).foregroundStyle(.secondary)
                    } else {
                        Text("Esta instalação está usando o modo local. O editor funciona, mas a extensão do teclado ainda não compartilha sua biblioteca.")
                        Text("Para ativar, instale a configuração completa pelo Xcode, com o mesmo App Group habilitado nos três targets. As instruções estão no projeto.").foregroundStyle(.secondary)
                    }
                    Button("Entendi") { dismiss() }.buttonStyle(PrimaryButtonStyle())
                }.padding(24)
            }.navigationTitle("Stickers do iPhone").navigationBarTitleDisplayMode(.inline)
        }
    }
    private func instruction(_ number: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number).font(.headline).frame(width: 36, height: 36).background(FiggyStyle.purple.opacity(0.14), in: Circle())
            VStack(alignment: .leading, spacing: 5) { Text(title).font(.headline); Text(detail).font(.subheadline).foregroundStyle(.secondary) }
        }
    }
}
