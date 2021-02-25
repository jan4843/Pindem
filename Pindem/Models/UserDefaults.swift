import Foundation

extension UserDefaults {
    
    // MARK: - Preferences
    
    @UserDefault(key: "open_externally", defaultValue: false)
    static var openExternally: Bool
    
    @UserDefault(key: "use_reader_view", defaultValue: false)
    static var useReaderView: Bool
    
    @UserDefault(key: "default_unread", defaultValue: false)
    static var defaultUnread: Bool
    
    @UserDefault(key: "default_private", defaultValue: false)
    static var defaultPrivate: Bool
    
    // MARK: - Configurations
    
    @UserDefault(key: "last_sync", defaultValue: Date(timeIntervalSince1970: 0))
    static var lastSync: Date
    
}
