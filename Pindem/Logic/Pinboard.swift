import Foundation

class Pinboard {
    
    enum PinboardError: Error {
        case unauthorized
        case rateLimitExceeded
        case unknown
    }
    
    typealias PostHandler = (_ url: URL, _ meta: String, _ title: String, _ description: String, _ tags: String, _ private: Bool, _ unread: Bool, _ date: Date) -> Void
    
    static let baseURL = URL(string: "https://api.pinboard.in/v1")!
    static let rateLimit: TimeInterval = 1 /// TODO: Change to actual `5 * 60`
    
    func add(url: URL, title: String, description: String, tags: String, `private`: Bool, unread: Bool) throws {
        let response = try call("/posts/add", [
            "url":         url.absoluteString,
            "description": title,
            "extended":    description,
            "tags":        tags,
            "shared":      `private` ? "no" : "yes",
            "toread":      unread ? "yes" : "no"
        ]) as GenericResponse
        try response.ensureValid()
    }
    
    func delete(url: URL) throws {
        let response = try call("/posts/delete", ["url": url.absoluteString]) as GenericResponse
        try response.ensureValid()
    }
    
    func all(postHandler: PostHandler) throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        
        /// TODO: Use `XMLParserDelegate` for better performance with huge amount of bookmarks
        let posts = try call("/posts/all") as [Post]
        for post in posts {
            postHandler(
                URL(string: post.href)!,
                post.meta,
                post.description,
                post.extended,
                post.tags,
                (post.shared != "yes"),
                (post.toread == "yes"),
                dateFormatter.date(from: post.time) ?? Date()
            )
        }
    }
    
    static func token(username: String, password: String) throws -> String {
        let session = URLSession(configuration: URLSessionConfiguration.ephemeral)
        let url = Pinboard.baseURL
            .appendingPathComponent("/user/api_token/")
            .appendingQueryItems(["format": "json"])
        var request = URLRequest(url: url)
        let basicAuth = "\(username):\(password)".toBase64()
        request.addValue("Basic \(basicAuth)", forHTTPHeaderField: "Authorization")
        var token: String?
        let semaphore = DispatchSemaphore(value: 0)
        session.dataTask(with: request) { data, response, error in
            if let data = data, let response = try? JSONDecoder().decode(ResultResponse.self, from: data) {
                token = response.result
            }
            semaphore.signal()
        }.resume()
        _ = semaphore.wait(timeout: .distantFuture)
        
        if let token = token { return token }
        throw PinboardError.unknown
    }
    
    // MARK: - Helpers
    
    var authToken: String {
        (AccountManager.shared.username ?? "") + ":" + (AccountManager.shared.token ?? "")
    }
    
    private var defaultQueryItems: [String: String] {[
        "format":     "json",
        "auth_token": authToken
    ]}
    
    private func call<T>(_ path: String, _ query: [String: String] = [:]) throws -> T where T : Decodable {
        let session = URLSession(configuration: URLSessionConfiguration.ephemeral)
        let url = Pinboard.baseURL
            .appendingPathComponent(path)
            .appendingQueryItems(defaultQueryItems)
            .appendingQueryItems(query)
        let request = URLRequest(url: url)
        
        var parsedResponse: T?
        var pinboardError: PinboardError? = .unknown
        
        let semaphore = DispatchSemaphore(value: 0)
        session.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }
            
            guard error == nil else { return }
            guard let response = response as? HTTPURLResponse else { return }
            
            /// Don't bother checking/handling other codes (400 Client Error, 500 Server Error) since the server doesn't respect the standards
            guard response.statusCode == 200 else {
                if response.statusCode == 401 { pinboardError = .unauthorized }
                if response.statusCode == 429 { pinboardError = .rateLimitExceeded }
                return
            }
            
            if let data = data, let response = try? JSONDecoder().decode(T.self, from: data) {
                parsedResponse = response
                pinboardError = nil
            }
        }.resume()
        _ = semaphore.wait(timeout: .distantFuture)
        
        guard pinboardError == nil else { throw pinboardError! }
        return parsedResponse!
    }
    
}

// MARK: - Responses

fileprivate struct GenericResponse: Decodable {
    let result_code: String
    
    func ensureValid() throws {
        if result_code != "done" {
            throw Pinboard.PinboardError.unknown
        }
    }
}

fileprivate struct ResultResponse: Decodable {
    let result: String
}

fileprivate struct Post: Decodable {
    let description: String
    let extended: String
    let href: String
    let meta: String
    let shared: String
    let tags: String
    let time: String
    let toread: String
}
