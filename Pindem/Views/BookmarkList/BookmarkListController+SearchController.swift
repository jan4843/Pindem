import UIKit

extension BookmarkListController: UISearchControllerDelegate, UISearchBarDelegate {
    
    func willDismissSearchController(_ searchController: UISearchController) {
        query = nil
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        query = searchController.searchBar.text
    }
    
}
