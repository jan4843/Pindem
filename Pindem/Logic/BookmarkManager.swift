import CoreData
import Foundation
import UIKit

class BookmarkManager {
    
    enum BookmarkManagerError: Error {
        case busy
        case serverError
    }
    
    typealias CompletionHandler = (BookmarkManagerError?) -> Void
    
    static let shared = BookmarkManager()
    private init() {
        pinboard = Pinboard()
    }
    
    private let pinboard: Pinboard
    
    func add(url: URL, title: String, tags: String, description: String, unread: Bool, private: Bool, completion: @escaping CompletionHandler) {
        let bookmark = Bookmark(context: container.viewContext)
        bookmark.url     = url
        bookmark.title   = title
        bookmark.desc    = description
        bookmark.tags    = tags
        bookmark.unread  = unread
        bookmark.private = `private`
        bookmark.date    = Date()
        edit(bookmark: bookmark) { error in
            if let _ = error {
                bookmark.managedObjectContext?.delete(bookmark)
            }
            completion(error)
        }
    }
    
    func edit(bookmark: Bookmark, title: String? = nil, tags: String? = nil, description: String? = nil, unread: Bool? = nil, private: Bool? = nil, completion: @escaping CompletionHandler) {
        sequentially(completion) { [self] in
            withBackgroundContext { context in
                do {
                    try pinboard.add(url:         bookmark.url,
                                     title:       title       ?? bookmark.title,
                                     description: description ?? bookmark.desc,
                                     tags:        tags        ?? bookmark.tags,
                                     private:     `private`   ?? bookmark.private,
                                     unread:      unread      ?? bookmark.unread)
                    
                    if let title = title { bookmark.title = title }
                    if let tags = tags { bookmark.tags = tags }
                    if let desc = description { bookmark.desc = desc }
                    if let unread = unread { bookmark.unread = unread }
                    if let `private` = `private` { bookmark.private = `private` }
                    try context.save()
                    AppDelegate.shared.saveContext()
                    completion(nil)
                } catch {
                    completion(.serverError)
                }
            }
        }
    }
    
    func delete(bookmark: Bookmark, completion: @escaping CompletionHandler) {
        sequentially(completion) { [self] in
            do {
                try pinboard.delete(url: bookmark.url)
                bookmark.managedObjectContext?.delete(bookmark)
                completion(nil)
            } catch {
                completion(.serverError)
            }
        }
    }
    
    func sync(completion: @escaping CompletionHandler) {
        sequentially(completion) { [self] in
            withBackgroundContext { context in
                guard shouldPerformFullSync() else {
                    completion(nil)
                    return
                }
                
                do {
                    var metas: [String] = []
                    try self.pinboard.all { url, meta, title, description, tags, `private`, unread, date in
                        metas.append(meta)
                        updateOrCreateBookmark(context: context, url: url, meta: meta, title: title, description: description, tags: tags, private: `private`, unread: unread, date: date)
                    }
                    deleteBookmarks(context: context, withMetaNotIn: metas)
                    try context.save()
                    AppDelegate.shared.saveContext()
                    completion(nil)
                } catch {
                    completion(.serverError)
                }
            }
        }
    }
    
    func clear(completion: @escaping CompletionHandler) {
        sequentially(completion) { [self] in
            withBackgroundContext { context in
                deleteBookmarks(context: context, withMetaNotIn: [])
                try? context.save()
                AppDelegate.shared.saveContext()
                completion(nil)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func shouldPerformFullSync() -> Bool {
        guard Date() > UserDefaults.lastSync + Pinboard.rateLimit else {
            return false
        }
        
        UserDefaults.lastSync = Date()
        return true
    }
    
    private func updateOrCreateBookmark(context: NSManagedObjectContext, url: URL, meta: String, title: String, description: String, tags: String, private: Bool, unread: Bool, date: Date) {
        let request: NSFetchRequest<Bookmark> = Bookmark.fetchRequest()
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(Bookmark.url), url.absoluteString)
        guard let bookmarks = try? context.fetch(request) else { return }
        
        if let bookmark = bookmarks.first, let previousMeta = bookmark.meta {
            guard previousMeta != meta else { return }
        }
        
        let bookmark = (bookmarks.count == 1) ? bookmarks.first! : Bookmark(context: context)
        bookmark.url      = url
        bookmark.title    = title
        bookmark.desc     = description
        bookmark.tags     = tags
        bookmark.private  = `private`
        bookmark.unread   = unread
        bookmark.date     = date
        bookmark.meta     = meta
    }
    
    private func deleteBookmarks(context: NSManagedObjectContext, withMetaNotIn metas: [String]) {
        let request: NSFetchRequest<Bookmark> = Bookmark.fetchRequest()
        request.predicate = NSPredicate(format: "NOT (%K IN %@)", #keyPath(Bookmark.meta), metas)
        if let bookmarks = try? context.fetch(request) {
            for bookmark in bookmarks {
                context.delete(bookmark)
            }
        }
    }
    
    // MARK: - Persistency
    
    private var container: NSPersistentContainer {
        AppDelegate.shared.persistentContainer
    }
    
    private func withBackgroundContext(background: Bool = true, block: @escaping (NSManagedObjectContext) -> Void) {
        let semaphore = DispatchSemaphore(value: 0)
        AppDelegate.shared.persistentContainer.performBackgroundTask { context in
            block(context)
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .distantFuture)
    }
    
    private func saveContext() {
        AppDelegate.shared.saveContext()
    }
    
    // MARK: - Concurrency
    
    private var queue = DispatchQueue(label: #fileID, qos: .background)
    private var busy = false
    
    private func sequentially(_ completion: @escaping CompletionHandler, _ block: @escaping () -> Void) {
        guard !busy else {
            completion(.busy)
            return
        }
        
        NotificationCenter.default.post(name: Notification.Name("SyncStarted"), object: nil)
        busy = true
        queue.async {
            block()
            self.busy = false
            NotificationCenter.default.post(name: Notification.Name("SyncFinished"), object: nil)
        }
    }
    
}
