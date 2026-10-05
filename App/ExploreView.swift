import SwiftUI

struct ExploreView: View {
    @EnvironmentObject var model: AppModel
    @State private var search = ""
    @State private var category = "Todos"
    @State private var showCatalog = false
    let categories = ["Todos", "Reações", "Fofo", "Estudos"]
    var filtered: [CatalogItem] {
        model.catalog.filter { (category == "Todos" || $0.category == category) && (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)) }
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        HStack(spacing: 8) { Image(systemName: "face.smiling.inverse").foregroundStyle(FiggyStyle.purple); Text("figgy").font(.system(.largeTitle, design: .rounded, weight: .heavy)) }
                        Spacer()
                        Text("FEITO PARA EXPRESSAR").font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary)
                    }
                    hero
                    HStack { Text("Um pack para cada mood").font(.title3.bold()); Spacer() }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { item in
                                Button { withAnimation { category = item } } label: {
                                    Text(item).font(.subheadline.weight(.semibold)).padding(.horizontal, 18).padding(.vertical, 12)
                                        .foregroundStyle(category == item ? .white : .primary)
                                        .background(category == item ? FiggyStyle.purple : FiggyStyle.card, in: Capsule())
                                }.accessibilityAddTraits(category == item ? .isSelected : [])
                            }
                        }
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                        ForEach(filtered) { item in
                            NavigationLink { CatalogDetailView(item: item) } label: { CatalogCard(item: item) }.buttonStyle(.plain)
                        }
                    }
                    if filtered.isEmpty { EmptyState(icon: "magnifyingglass", title: "Nenhum pack por aqui", subtitle: "Tente outro nome ou categoria.") }
                    Button { showCatalog = true } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "link.circle.fill").font(.title).foregroundStyle(FiggyStyle.purple)
                            VStack(alignment: .leading, spacing: 5) { Text("Recebeu um catálogo?").font(.headline); Text("Abra um link e baixe mais packs grátis.").font(.subheadline).foregroundStyle(.secondary) }
                            Spacer(); Image(systemName: "chevron.right")
                        }.padding(20).background(FiggyStyle.card, in: RoundedRectangle(cornerRadius: 24))
                    }.buttonStyle(.plain)
                    Text("Sem anúncios. Sem assinatura. Suas criações ficam no seu iPhone.").font(.footnote).foregroundStyle(.secondary).frame(maxWidth: .infinity).multilineTextAlignment(.center)
                }.padding(20)
            }.background(FiggyStyle.background).toolbar(.hidden, for: .navigationBar)
                .searchable(text: $search, prompt: "Encontre seu próximo pack")
                .sheet(isPresented: $showCatalog) { RemoteCatalogView() }
        }
    }
    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sua conversa,\ncom a sua cara.").font(.system(.largeTitle, design: .rounded, weight: .heavy)).foregroundStyle(Color(hex: "33224E"))
            Text("Crie, colecione e compartilhe.\nNo WhatsApp e no seu iPhone.").font(.subheadline).foregroundStyle(Color(hex: "52405F"))
            HStack(spacing: 4) {
                if let first = model.catalog.first {
                    ForEach(Array(first.files.prefix(3).enumerated()), id: \.offset) { i, file in
                        CatalogThumbnail(file: file).frame(height: 100).rotationEffect(.degrees(i == 1 ? 8 : -7))
                    }
                }
            }.frame(maxWidth: .infinity)
            Label("Packs grátis, sempre", systemImage: "heart.fill").font(.caption.bold()).foregroundStyle(Color(hex: "503273"))
        }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
            .background(LinearGradient(colors: [Color(hex: "E9DAFF"), Color(hex: "FFDCEA")], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 30))
    }
}
struct CatalogCard: View {
    let item: CatalogItem
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 0) { ForEach(Array(item.files.prefix(2)), id: \.self) { CatalogThumbnail(file: $0).frame(maxWidth: .infinity) } }
                .frame(height: 100).padding(12).background(Color(hex: item.color).opacity(0.23), in: RoundedRectangle(cornerRadius: 18))
            Text(item.name).font(.headline)
            HStack { Text("\(item.files.count) figurinhas").font(.caption).foregroundStyle(.secondary); Spacer(); Text("GRÁTIS").font(.system(size: 10, weight: .heavy)).foregroundStyle(FiggyStyle.purple) }
        }.padding(12).background(FiggyStyle.card, in: RoundedRectangle(cornerRadius: 24))
    }
}
struct CatalogDetailView: View {
    let item: CatalogItem
    @EnvironmentObject var model: AppModel
    var installed: Bool { model.packs.contains { $0.sourceID == item.id } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(item.name).font(.system(.largeTitle, design: .rounded, weight: .heavy))
                Text("Por \(item.author) · \(item.files.count) figurinhas estáticas").foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                    ForEach(item.files, id: \.self) { CatalogThumbnail(file: $0).frame(height: 110).padding(10).background(FiggyStyle.card, in: RoundedRectangle(cornerRadius: 20)) }
                }
                Button { Task { await model.install(item) } } label: { Label(installed ? "Salvo em Meus packs" : "Baixar pack grátis", systemImage: installed ? "checkmark.circle" : "arrow.down.circle") }
                    .buttonStyle(PrimaryButtonStyle()).disabled(installed || model.busy)
                Text("Depois de baixar, abra Meus packs para adicionar ao WhatsApp, usar no iPhone ou compartilhar com alguém.").font(.subheadline).foregroundStyle(.secondary)
            }.padding(20)
        }.background(FiggyStyle.background).navigationTitle("Conheça o pack").navigationBarTitleDisplayMode(.inline)
    }
}
struct RemoteCatalogView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) var dismiss
    @State private var link = ""
    @State private var packs: [RemotePack] = []
    @State private var busy = false
    @State private var error: String?
    @State private var downloaded: Set<String> = []
    var body: some View {
        NavigationStack {
            List {
                Section("Link do catálogo") {
                    TextField("https://…/catalog.json", text: $link).keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                    Button("Abrir catálogo") { Task { await load() } }.disabled(busy || link.isEmpty)
                    Text("Cole o link de um catálogo Figgy compartilhado por alguém. O app não envia suas fotos para o catálogo.").font(.footnote).foregroundStyle(.secondary)
                }
                if busy { ProgressView("Baixando…") }
                if let error { Text(error).foregroundStyle(.red) }
                ForEach(packs) { pack in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(pack.name).font(.headline); Text("\(pack.author) · \(pack.category)").font(.caption).foregroundStyle(.secondary)
                        Button(downloaded.contains(pack.id) ? "Baixado" : "Baixar grátis") { Task { await download(pack) } }.disabled(busy || downloaded.contains(pack.id))
                    }.padding(.vertical, 6)
                }
            }.navigationTitle("Mais packs").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Fechar") { dismiss() } } }
        }
    }
    private func load() async {
        guard let url = URL(string: link), url.scheme == "https" else { error = "Cole um link HTTPS válido."; return }
        busy = true; error = nil; defer { busy = false }
        do { packs = try await CatalogClient.load(url); downloaded = [] } catch { self.error = error.localizedDescription }
    }
    private func download(_ pack: RemotePack) async {
        busy = true; error = nil; defer { busy = false }
        do { _ = try await CatalogClient.download(pack); model.refresh(); downloaded.insert(pack.id); model.notice = "\(pack.name) salvo em Meus packs!" }
        catch { self.error = error.localizedDescription }
    }
}
