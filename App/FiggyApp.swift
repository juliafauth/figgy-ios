import SwiftUI

@main
struct FiggyApp: App {
    @StateObject private var model = AppModel()
    var body: some Scene {
        WindowGroup { RootView().environmentObject(model).tint(FiggyStyle.purple) }
    }
}
struct RootView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.scenePhase) private var phase
    @State private var tab = 0
    var body: some View {
        TabView(selection: $tab) {
            ExploreView().tabItem { Label("Explorar", systemImage: "sparkles") }.tag(0)
            CreateLandingView().tabItem { Label("Criar", systemImage: "plus.app.fill") }.tag(1)
            LibraryView().tabItem { Label("Meus packs", systemImage: "square.stack.3d.up.fill") }.tag(2)
        }
        .onChange(of: phase) { _, value in if value == .active { model.refresh() } }
        .onOpenURL { url in Task { await model.importURLs([url]); tab = 2 } }
        .alert("Ops!", isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) {
            Button("Entendi", role: .cancel) { model.error = nil }
        } message: { Text(model.error ?? "") }
        .safeAreaInset(edge: .top, spacing: 0) {
            if model.busy { HStack(spacing: 10) { ProgressView(); Text("Preparando suas figurinhas…").font(.subheadline) }.padding(12).frame(maxWidth: .infinity).background(.regularMaterial) }
        }
        .overlay(alignment: .top) {
            if let notice = model.notice {
                HStack { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green); Text(notice).font(.subheadline); Spacer(); Button { model.notice = nil } label: { Image(systemName: "xmark") }.accessibilityLabel("Fechar aviso") }
                    .padding(16).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18)).padding()
                    .task(id: notice) { try? await Task.sleep(for: .seconds(5)); if model.notice == notice { model.notice = nil } }
            }
        }
    }
}
