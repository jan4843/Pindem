import CoreData
import SafariServices
import UIKit

extension BookmarkListController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let bookmark = fetchedResultsController.object(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "BookmarkCell")!
        
        // Title
        if let boldFontDescriptor = cell.textLabel?.font.fontDescriptor.withSymbolicTraits(.traitBold) {
            cell.textLabel?.font = UIFont(descriptor: boldFontDescriptor, size: 0)
        }
        cell.textLabel?.text = bookmark.title
        
        // Subtitle
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.current
        let details = [
            bookmark.url.host ?? bookmark.url.absoluteString,
            dateFormatter.string(from: bookmark.date),
        ]
        cell.detailTextLabel?.text = details.compactMap{ $0 }.joined(separator: " • ")
        
        // Stripe
        cell.stripeColor = bookmark.unread ? UIColor.systemBlue : nil
        
        // Accessory
        let accessorySymbol = bookmark.private ? "lock" : "globe"
        let imageConfiguration = UIImage.SymbolConfiguration(textStyle: .caption1)
        let image = UIImage(systemName: accessorySymbol, withConfiguration: imageConfiguration)
        cell.accessoryView = UIImageView(image: image?.withTintColor(UIColor.tertiaryLabel, renderingMode: .alwaysOriginal))
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let bookmark = fetchedResultsController.object(at: indexPath)
        
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        guard bookmark.url.scheme == "http" || bookmark.url.scheme == "https" else { return }
        
        if UserDefaults.openExternally {
            UIApplication.shared.open(bookmark.url)
        } else {
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = UserDefaults.useReaderView
            let vc = SFSafariViewController(url: bookmark.url, configuration: config)
            present(vc, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let bookmark = fetchedResultsController.object(at: indexPath)
        
        let readAction = UIContextualAction(style: .normal, title: bookmark.unread ? "Read" : "Unread") { action, view, completion in
            completion(true)
            BookmarkManager.shared.edit(bookmark: bookmark, unread: !bookmark.unread, completion: self.handleError)
        }
        readAction.backgroundColor = UIColor.systemBlue
        
        return UISwipeActionsConfiguration(actions: [readAction])
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let bookmark = fetchedResultsController.object(at: indexPath)
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { action, view, completion in
            completion(true)
            
            let dialogMessage = UIAlertController(title: "Delete Bookmark", message: "Are you sure you want to delete the bookmark?", preferredStyle: .alert)
            let confirm = UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                BookmarkManager.shared.delete(bookmark: bookmark, completion: self.handleError)
            })
            let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in }
            dialogMessage.addAction(confirm)
            dialogMessage.addAction(cancel)
            self.present(dialogMessage, animated: true, completion: nil)
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { action, view, completion in
            completion(true)
            self.selectedBookmarkForEditing = bookmark
            self.performSegue(withIdentifier: "ShowEditor", sender: self)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowEditor" {
            if let navigationController = segue.destination as? UINavigationController,
               let viewController = navigationController.topViewController as? EditorViewController {
                viewController.editingBookmark = selectedBookmarkForEditing
                selectedBookmarkForEditing = nil
             }
        }
    }
    
}
