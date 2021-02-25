import Foundation
import Security

class AccountManager {
    
    enum AuthenticationError: Error {
        case unauthorized
        case pendingOperations
    }
    
    static let shared = AccountManager()
    private init() { }
    
    var username: String? {
        get { Keychain.load(key: "username") }
        set {
            if let value = newValue {
                Keychain.save(key: "username", value: value)
            } else {
                Keychain.delete(key: "username")
            }
        }
    }
    
    var token: String? {
        get { Keychain.load(key: "token") }
        set {
            if let value = newValue {
                Keychain.save(key: "token", value: value)
            } else {
                Keychain.delete(key: "token")
            }
        }
    }
    
    var loggedIn: Bool {
        username != nil && token != nil
    }
    
    func logIn(username: String, password: String) throws {
        guard let token = try? Pinboard.token(username: username, password: password) else {
            throw AuthenticationError.unauthorized
        }
        
        self.username = username
        self.token = token
        
        UserDefaults.lastSync = Date(timeIntervalSince1970: 0)
        BookmarkManager.shared.sync() { _ in }
    }
    
    func logOut() throws {
        var returnedError: AuthenticationError? = AuthenticationError.pendingOperations
        
        let semaphore = DispatchSemaphore(value: 0)
        BookmarkManager.shared.clear() { error in
            guard error == nil else { return }
            
            self.username = nil
            self.token = nil
            returnedError = nil
            
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .distantFuture)
        
        if let returnedError = returnedError { throw returnedError }
    }
    
}

fileprivate class Keychain {
    
    class func save(key: String, value: String) {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String:   value.data(using: String.Encoding.utf8)!
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    class func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    class func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String:  kCFBooleanTrue!,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ] as [String: Any]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == noErr else { return nil }
        guard let data = item as? Data,
              let value = String(data: data, encoding: String.Encoding.utf8) else { return nil }
        
        return value
    }
    
}
