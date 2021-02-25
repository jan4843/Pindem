import UIKit

class EditorViewController: UITableViewController {
    
    @IBOutlet weak var unreadCell: UITableViewCell!
    @IBOutlet weak var privateCell: UITableViewCell!
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var tagsTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    
    var editingBookmark: Bookmark?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isModalInPresentation = true
        
        // Text Fields
        urlTextField.delegate = self
        titleTextField.delegate = self
        tagsTextField.delegate = self
        
        // Option Cells
        let unreadSwitch = UISwitch()
        unreadSwitch.isOn = UserDefaults.defaultUnread
        unreadCell.accessoryView = unreadSwitch
        let privateSwitch = UISwitch()
        privateSwitch.isOn = UserDefaults.defaultPrivate
        privateCell.accessoryView = privateSwitch
        
        // Existing values
        if let bookmark = editingBookmark {
            navigationItem.title = navigationItem.title?.replacingOccurrences(of: "Add", with: "Edit")
            
            urlTextField.isEnabled = false
            urlTextField.textColor = .secondaryLabel
            
            urlTextField.text = bookmark.url.absoluteString
            titleTextField.text = bookmark.title
            tagsTextField.text = bookmark.tags
            descriptionTextView.text = bookmark.desc
            unreadSwitch.isOn = bookmark.unread
            privateSwitch.isOn = bookmark.private
        }
    }
    
    @IBAction func cancelButtonClicked(_ sender: UIBarButtonItem) {
        dismiss(animated: true) { }
    }
    
    @IBAction func saveButtonClicked(_ sender: UIBarButtonItem) {
        guard let urlString = urlTextField.text, let url = URL(string: urlString) else {
            showAlert(title: "Invalid URL", message: "The provided URL is not valid.")
            return
        }
        guard !(titleTextField.text?.isEmpty ?? true) else {
            showAlert(title: "Missing Title", message: "A title for the bookmark is required.")
            return
        }
        
        self.showSpinner()
        let completionHandler: BookmarkManager.CompletionHandler = { error in
            DispatchQueue.main.async {
                self.hideSpinner()
                guard error == nil else {
                    self.showAlert(title: "Error Saving", message: "An error occurred while saving the bookmark.")
                    return
                }
                self.dismiss(animated: true) { }
            }
        }
        
        if let bookmark = editingBookmark {
            BookmarkManager.shared.edit(
                bookmark: bookmark,
                title: titleTextField.text,
                tags: tagsTextField.text,
                description: descriptionTextView.text,
                unread: (unreadCell.accessoryView as? UISwitch)?.isOn,
                private: (privateCell.accessoryView as? UISwitch)?.isOn,
                completion: completionHandler
            )
        } else {
            BookmarkManager.shared.add(
                url: url,
                title: titleTextField.text ?? "",
                tags: tagsTextField.text ?? "",
                description: descriptionTextView.text ?? "",
                unread: (unreadCell.accessoryView as? UISwitch)?.isOn ?? false,
                private: (privateCell.accessoryView as? UISwitch)?.isOn ?? false,
                completion: completionHandler
            )
        }
    }
    
}

extension EditorViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let nextField = tableView.viewWithTag(textField.tag + 1) as? UITextField {
            nextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return false
    }
}
