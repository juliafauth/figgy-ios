import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct CreateLandingView: View {
    @State private var editor = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Uma ideia.\nMil conversas.").font(.system(.largeTitle, design: .rounded, weight: .heavy))
                    ZStack {
                        RoundedRectangle(cornerRadius: 30).fill(LinearGradient(colors: [Color(hex: "D9CEF7"), Color(hex: "F7D7E4")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        VStack(spacing: 14) {
                            Image(systemName: "wand.and.stars").font(.system(size: 64)).foregroundStyle(Color(hex: "7645D9"))
                            Text("Sua foto + sua vibe").font(.system(.title2, design: .rounded, weight: .heavy)).foregroundStyle(Color(hex: "33224E"))
                            Text("Imagem inteira, texto e cores.\nDo jeitinho que você quiser.").multilineTextAlignment(.center).foregroundStyle(Color(hex: "52405F"))
                        }.padding(30)
                    }.frame(minHeight: 270)
                    Button { editor = true } label: { Label("Criar minha figurinha", systemImage: "plus.circle.fill") }.buttonStyle(PrimaryButtonStyle())
                    Label("Mantenha o meme inteiro, inclusive o texto.", systemImage: "rectangle.expand.vertical")
                    Label("Remova o fundo só quando você escolher.", systemImage: "person.crop.rectangle")
                    Label("Salve, compartilhe e use nos dois lugares.", systemImage: "paperplane")
                }.padding(24)
            }.background(FiggyStyle.background).navigationTitle("Estúdio Figgy").navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $editor) { EditorView(initialPackID: nil) }
        }
    }
}
struct EditorView: View {
    let initialPackID: UUID?
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) var dismiss
    @State private var photo: PhotosPickerItem?
    @State private var original: UIImage?
    @State private var image: UIImage?
    @State private var options = EditorOptions()
    @State private var importing = false
    @State private var cutting = false
    @State private var localBusy = false
    @State private var selectedPack: UUID?
    @State private var newPackName = "Minhas criações"
    @State private var background = "Transparente"
    @State private var error: String?
    private let colors: [(String, String)] = [("Lilás", "E9DAFF"), ("Rosa", "FFD6E8"), ("Verde", "BDE9D1"), ("Amarelo", "FFE69B"), ("Branco", "FFFFFF"), ("Escuro", "322346")]
    var hasContent: Bool { image != nil || !options.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var preview: UIImage { ImageProcessor.draw(image, options: options) }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ZStack {
                        Checkerboard().clipShape(RoundedRectangle(cornerRadius: 28))
                        if hasContent { Image(uiImage: preview).resizable().scaledToFit().padding(8) }
                        else { VStack(spacing: 10) { Image(systemName: "photo.badge.plus").font(.system(size: 40)); Text("Sua criação começa aqui").font(.headline) }.foregroundStyle(FiggyStyle.purple) }
                    }.aspectRatio(1, contentMode: .fit).frame(maxWidth: 420).frame(maxWidth: .infinity)
                    HStack(spacing: 12) {
                        PhotosPicker(selection: $photo, matching: .images) { Label("Fotos", systemImage: "photo.on.rectangle") }.buttonStyle(PrimaryButtonStyle())
                        Button { importing = true } label: { Label("Arquivos", systemImage: "folder") }.buttonStyle(PrimaryButtonStyle(color: Color(hex: "368564")))
                    }
                    HStack {
                        VStack(alignment: .leading, spacing: 5) { Text(cutting ? "Fundo removido" : "Imagem inteira").font(.headline); Text(cutting ? "Volte ao original quando quiser." : "Preserva fundo, bordas e texto.").font(.caption).foregroundStyle(.secondary) }
                        Spacer()
                        Button(cutting ? "Restaurar" : "Remover fundo") { Task { await cut() } }.font(.subheadline.bold()).disabled(image == nil || localBusy)
                    }.padding(16).background(FiggyStyle.card, in: RoundedRectangle(cornerRadius: 18))
                    if localBusy { ProgressView("Preparando imagem…") }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Diga com uma figurinha").font(.headline)
                        TextField("Escreva seu texto…", text: $options.text, axis: .vertical).lineLimit(1...3).textFieldStyle(.roundedBorder)
                            .onChange(of: options.text) { _, text in if text.count > 100 { options.text = String(text.prefix(100)) } }
                        Toggle("Texto na parte de cima", isOn: $options.textAtTop)
                        HStack { Text("Tamanho"); Slider(value: $options.textSize, in: 24...76).accessibilityLabel("Tamanho do texto") }
                        HStack { Text("Cor do texto"); Spacer(); ColorPicker("Cor do texto", selection: Binding(get: { Color(uiColor: options.textColor) }, set: { options.textColor = UIColor($0) })).labelsHidden() }
                        HStack { Text("Cor do contorno do texto"); Spacer(); ColorPicker("Cor do contorno", selection: Binding(get: { Color(uiColor: options.accent) }, set: { options.accent = UIColor($0) })).labelsHidden() }
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Fundo e espaço").font(.headline)
                        Picker("Fundo", selection: $background) {
                            Text("Transparente").tag("Transparente")
                            ForEach(colors, id: \.0) { Text($0.0).tag($0.0) }
                        }.pickerStyle(.menu)
                            .onChange(of: background) { _, name in options.background = colors.first(where: { $0.0 == name }).map { UIColor(Color(hex: $0.1)) } }
                        HStack { Text("Margem"); Slider(value: $options.padding, in: 0...64).accessibilityLabel("Margem da imagem") }
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Salvar em um pack").font(.headline)
                        Picker("Pack", selection: $selectedPack) {
                            Text("Criar novo pack").tag(nil as UUID?)
                            ForEach(model.packs.filter { $0.stickers.count < 30 }) { Text($0.name).tag(Optional($0.id)) }
                        }.pickerStyle(.menu)
                        if selectedPack == nil { TextField("Nome do novo pack", text: $newPackName).textFieldStyle(.roundedBorder) }
                    }
                    if let error { Text(error).font(.subheadline).foregroundStyle(.red) }
                    Button { Task { await save() } } label: { Label("Salvar figurinha", systemImage: "checkmark.circle.fill") }.buttonStyle(PrimaryButtonStyle()).disabled(!hasContent || model.busy || localBusy)
                }.padding(20)
            }.background(FiggyStyle.background).navigationTitle("Criar figurinha").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Fechar") { dismiss() } } }
                .onAppear { selectedPack = initialPackID }
                .onChange(of: photo) { _, value in Task { await loadPhoto(value) } }
                .fileImporter(isPresented: $importing, allowedContentTypes: [.image, .data], allowsMultipleSelection: false) { result in
                    switch result { case .success(let urls): if let url = urls.first { Task { await loadFile(url) } }; case .failure(let error): self.error = error.localizedDescription }
                }
        }.interactiveDismissDisabled(localBusy || model.busy)
    }
    private func setImage(_ image: UIImage) { original = image; self.image = image; cutting = false; error = nil }
    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }; localBusy = true; defer { localBusy = false }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { throw FiggyError("Não consegui abrir a foto.") }
            setImage(try await Task.detached { try ImageProcessor.decode(data) }.value)
        } catch { self.error = error.localizedDescription }
    }
    private func loadFile(_ url: URL) async {
        localBusy = true; defer { localBusy = false }
        do {
            let image = try await Task.detached {
                let scoped = url.startAccessingSecurityScopedResource(); defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                guard size <= 20 * 1024 * 1024 else { throw FiggyError("Escolha uma imagem de até 20 MB.") }
                return try ImageProcessor.decode(Data(contentsOf: url))
            }.value
            setImage(image)
        } catch { self.error = error.localizedDescription }
    }
    private func cut() async {
        if cutting { image = original; cutting = false; return }
        guard let original else { return }; localBusy = true; defer { localBusy = false }
        do { image = try await Task.detached { try ImageProcessor.removeBackground(original) }.value; cutting = true }
        catch { self.error = error.localizedDescription }
    }
    private func save() async {
        let output = preview
        let packID: UUID
        if let selectedPack { packID = selectedPack }
        else { guard let pack = model.createPack(newPackName) else { error = model.error; model.error = nil; return }; packID = pack.id; selectedPack = packID }
        if await model.save(output, title: options.text, packID: packID) { dismiss() }
        else { error = model.error; model.error = nil }
    }
}
struct Checkerboard: View {
    var body: some View {
        Canvas { context, size in
            let side = size.width / 12
            for row in 0..<13 { for col in 0..<12 {
                let rect = CGRect(x: CGFloat(col) * side, y: CGFloat(row) * side, width: side, height: side)
                context.fill(Path(rect), with: .color((row + col) % 2 == 0 ? Color(uiColor: .systemGray5) : Color(uiColor: .systemGray6)))
            } }
        }.accessibilityHidden(true)
    }
}
