import CoreData
import UIKit

class BookmarkListController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    enum Filter {
        case unread
        case `private`
        case `public`
    }
    
    @IBOutlet weak var filterButton: UIBarButtonItem!
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var statusButton: UIBarButtonItem!
    
    var searchController: UISearchController!
    var fetchedResultsController: NSFetchedResultsController<Bookmark>!
    
    var selectedBookmarkForEditing: Bookmark?
    
    var query: String? {
        didSet {
            reloadFilters()
        }
    }
    var filter: Filter? {
        didSet {
            reloadFilters()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Search Controller
        searchController = UISearchController()
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.isActive = true
        navigationItem.searchController = searchController
        
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.caption1)
        label.text = " Synchronizing…"
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.startAnimating()
        let scale = label.font.pointSize / activityIndicator.intrinsicContentSize.height
        activityIndicator.transform = CGAffineTransform(scaleX: scale, y: scale)
        statusButton.customView = UIStackView(arrangedSubviews: [activityIndicator, label])
        statusButton.customView?.alpha = 0
        
        // Filter Menu
        setUpFilterButton()
        
        // Fetched Results
        let request: NSFetchRequest<Bookmark> = Bookmark.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor.init(key: #keyPath(Bookmark.date), ascending: false)]
        request.fetchBatchSize = 20
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: AppDelegate.shared.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        fetchedResultsController.fetchRequest.predicate = Bookmark.createPredicate()
        
        // Notifications
        NotificationCenter.default.addObserver(self, selector: #selector(updateStarted), name: Notification.Name("SyncStarted"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateFinished), name: Notification.Name("SyncFinished"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        try? fetchedResultsController.performFetch()
        tableView.reloadData()
        
        if !AccountManager.shared.loggedIn {
            performSegue(withIdentifier: "ShowLogin", sender: self)
        }
    }
    
    @IBAction func refreshControlValueChanged(_ sender: UIRefreshControl) {
        sender.endRefreshing()
        BookmarkManager.shared.sync() { _ in }
    }
    
    func reloadFilters() {
        var unread: Bool?
        var `private`: Bool?
        
        if let filter = filter {
            switch filter {
            case .unread:
                unread = true
            case .private:
                `private` = true
            case .public:
                `private` = false
            }
        }
        
        NSFetchedResultsController<NSFetchRequestResult>.deleteCache(withName: nil)
        fetchedResultsController.fetchRequest.predicate = Bookmark.createPredicate(query: query, unread: unread, private: `private`)
        try? fetchedResultsController.performFetch()
        tableView.reloadData()
    }
    
    func setUpFilterButton() {
        func handler(filter: Filter?, title: String) -> (UIAction) -> Void {
            return { _ in
                self.filter = filter
                self.setUpFilterButton()
                self.title = title
                let image = "line.horizontal.3.decrease.circle" + (filter == nil ? "" : ".fill")
                self.filterButton.image = UIImage(systemName: image)
            }
        }
        
        func action(filter: Filter, title: String, image: String) -> UIAction {
            let state: UIMenuElement.State = self.filter == filter ? .on : .off
            return UIAction(title: title, image: UIImage(systemName: image), state: state, handler: handler(filter: filter, title: title))
        }
        
        let clear = UIAction(title: "All", image: UIImage(systemName: "multiply"), attributes: .destructive, handler: handler(filter: nil, title: "Bookmarks"))
        let filters = UIMenu(title: "More", options: .displayInline, children: [
            action(filter: .unread, title: "Unread", image: "circle"),
            action(filter: .private, title: "Private", image: "lock"),
            action(filter: .public, title: "Public", image: "globe"),
        ])
        
        filterButton.menu = UIMenu(title: "Filter", children: filter == nil ? [filters] : [clear, filters])
    }
    
    @objc func updateStarted() {
        toggleStatusLabel(visible: true)
    }
    
    @objc func updateFinished() {
        toggleStatusLabel(visible: false)
    }
    
    func toggleStatusLabel(visible: Bool) {
        DispatchQueue.main.async { [weak self] in
            if let label = self?.statusButton.customView {
                UIView.transition(with: label, duration: 0.2, options: .curveEaseOut) {
                    label.alpha = (visible ? 1 : 0)
                }
            }
        }
    }
    
    func handleError(error: BookmarkManager.BookmarkManagerError?) {
        guard let error = error else { return }
        
        switch error {
        case .busy:
            showAlert(title: "Sync in Progress", message: "A synchronization is currently in progress, please retry shortly.")
        default:
            showAlert(title: "Sync Error", message: "The action cannot be performed due to a server error.")
        }
    }
    
}
