import Foundation

extension URL {
    func appendingQueryItems(_ queryItems: [String: String]) -> URL {
        guard var urlComponents = URLComponents(string: absoluteString) else { return absoluteURL }
        var newQueryItems: [URLQueryItem] = urlComponents.queryItems ?? []
        for (name, value) in queryItems {
            let queryItem = URLQueryItem(name: name, value: value)
            newQueryItems.append(queryItem)
        }
        urlComponents.queryItems = newQueryItems
        return urlComponents.url!
    }
}
