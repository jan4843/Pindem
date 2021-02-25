import Foundation
import CoreData

@objc(Bookmark)
class Bookmark: NSManagedObject, Identifiable {

    @NSManaged public var url: URL
    @NSManaged public var title: String
    @NSManaged public var desc: String
    @NSManaged public var tags: String
    @NSManaged public var `private`: Bool
    @NSManaged public var unread: Bool
    @NSManaged public var date: Date
    @NSManaged public var meta: String?
    
    @nonobjc class func fetchRequest() -> NSFetchRequest<Bookmark> {
        return NSFetchRequest<Bookmark>(entityName: "Bookmark")
    }
    
    @nonobjc class func createPredicate(query: String? = nil, unread: Bool? = nil, private: Bool? = nil) -> NSPredicate {
        var predicates: [String] = ["1 = 1"]
        var arguments: [Any] = []
        
        if let query = query {
            var textPredicates: [String] = []
            var textArguments: [Any] = []
            for field in [#keyPath(Bookmark.title), #keyPath(Bookmark.url), #keyPath(Bookmark.desc)] {
                textPredicates.append("%K CONTAINS[cd] %@")
                textArguments.append(contentsOf: [field, query])
            }
            predicates.append("(" + textPredicates.joined(separator: " OR ") + ")")
            arguments.append(contentsOf: textArguments)
        }
        
        if let unread = unread {
            predicates.append("%K = %@")
            arguments.append(contentsOf: [#keyPath(CachedLink.unread), NSNumber(booleanLiteral: unread)])
        }
        
        if let `private` = `private` {
            predicates.append("%K = %@")
            arguments.append(contentsOf: [#keyPath(Bookmark.private), NSNumber(booleanLiteral: `private`)])
        }
        
        let format = predicates.joined(separator: " AND ")
        return NSPredicate(format: format, argumentArray: arguments)
    }
    
}
