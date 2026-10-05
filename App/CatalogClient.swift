import Foundation

/// Limits transfer size while streaming and disables persistent cookies and caches.
private final class LimitedFetch: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    let limit: Int
    var buffer = Data()
    var continuation: CheckedContinuation<Data, Error>?
    var session: URLSession?
    init(limit: Int) { self.limit = limit }
    func fetch(_ url: URL) async throws -> Data {
        guard url.scheme?.lowercased() == "https" else { throw FiggyError("Use um link HTTPS.") }
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = 30; config.timeoutIntervalForResource = 60
            config.httpCookieStorage = nil
            let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
            self.session = session
            session.dataTask(with: url).resume()
        }
    }
    private func finish(_ result: Result<Data, Error>) {
        guard let continuation else { return }
        self.continuation = nil; continuation.resume(with: result)
        session?.invalidateAndCancel(); session = nil
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        if request.url?.scheme?.lowercased() == "https" { completionHandler(request) }
        else { completionHandler(nil); finish(.failure(FiggyError("O servidor redirecionou para um link inseguro."))) }
    }
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode),
              response.expectedContentLength <= Int64(limit) else {
            completionHandler(.cancel); finish(.failure(FiggyError("O servidor recusou o download ou o arquivo é grande demais."))); return
        }
        completionHandler(.allow)
    }
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard buffer.count + data.count <= limit else { finish(.failure(FiggyError("O download excedeu o limite permitido."))); return }
        buffer.append(data)
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error { finish(.failure(error)) } else { finish(.success(buffer)) }
    }
}
enum CatalogClient {
    static func load(_ url: URL) async throws -> [RemotePack] {
        let data = try await LimitedFetch(limit: 256_000).fetch(url)
        let catalog = try JSONDecoder().decode(RemoteCatalog.self, from: data)
        guard catalog.version == 1, catalog.packs.count <= 100,
              Set(catalog.packs.map(\.id)).count == catalog.packs.count,
              catalog.packs.allSatisfy({ !$0.id.isEmpty && !$0.name.isEmpty && $0.name.count <= 80 && $0.author.count <= 80 && $0.url.scheme == "https" }) else {
            throw FiggyError("Catálogo inválido. Use um catálogo Figgy versão 1.")
        }
        return catalog.packs
    }
    static func download(_ pack: RemotePack) async throws -> ImportReport {
        let data = try await LimitedFetch(limit: PackTransfer.maxArchiveBytes).fetch(pack.url)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).figpack")
        defer { try? FileManager.default.removeItem(at: url) }
        try data.write(to: url)
        return try await Task.detached(priority: .userInitiated) { try PackTransfer.importFile(url) }.value
    }
}
