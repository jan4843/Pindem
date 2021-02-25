import Foundation
import UIKit

class SettingsViewController: UITableViewController {
    
    @IBOutlet weak var openExternallyCell: UITableViewCell!
    @IBOutlet weak var readerViewCell: UITableViewCell!
    @IBOutlet weak var defaultUnreadCell: UITableViewCell!
    @IBOutlet weak var defaultPrivateCell: UITableViewCell!
    @IBOutlet weak var logOutCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isModalInPresentation = true
        
        let cells: [UITableViewCell] = [
            openExternallyCell,
            readerViewCell,
            defaultUnreadCell,
            defaultPrivateCell,
        ]
        for cell in cells {
            let accessorySwitch = UISwitch()
            cell.accessoryView = accessorySwitch
        }
        
        if let optionSwitch = openExternallyCell.accessoryView as? UISwitch {
            optionSwitch.isOn = UserDefaults.openExternally
            optionSwitch.addTarget(self, action: #selector(openExternallyOptionSwitchValueChanged), for: UIControl.Event.valueChanged)
        }
        if let optionSwitch = readerViewCell.accessoryView as? UISwitch {
            optionSwitch.isOn = UserDefaults.useReaderView
            optionSwitch.addTarget(self, action: #selector(redaerViewOptionSwitchValueChanged), for: UIControl.Event.valueChanged)
        }
        if let optionSwitch = defaultUnreadCell.accessoryView as? UISwitch {
            optionSwitch.isOn = UserDefaults.defaultUnread
            optionSwitch.addTarget(self, action: #selector(defaultUnreadOptionSwitchValueChanged), for: UIControl.Event.valueChanged)
        }
        if let optionSwitch = defaultPrivateCell.accessoryView as? UISwitch {
            optionSwitch.isOn = UserDefaults.defaultPrivate
            optionSwitch.addTarget(self, action: #selector(defaultPrivateOptionSwitchValueChanged), for: UIControl.Event.valueChanged)
        }
    }
    
    @objc func openExternallyOptionSwitchValueChanged(_ sender: UISwitch) {
        UserDefaults.openExternally = sender.isOn
    }
    
    @objc func redaerViewOptionSwitchValueChanged(_ sender: UISwitch) {
        UserDefaults.useReaderView = sender.isOn
    }
    
    @objc func defaultUnreadOptionSwitchValueChanged(_ sender: UISwitch) {
        UserDefaults.defaultUnread = sender.isOn
    }
    
    @objc func defaultPrivateOptionSwitchValueChanged(_ sender: UISwitch) {
        UserDefaults.defaultPrivate = sender.isOn
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.cellForRow(at: indexPath) == logOutCell {
            logOutCell.setSelected(false, animated: true)
            
            let alert = UIAlertController(title: "Log Out", message: "You need to log in again to continue using the app", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { _ in
                self.showSpinner()
                DispatchQueue.global(qos: .background).async {
                    guard let _ = try? AccountManager.shared.logOut() else {
                        self.showAlert(title: "Pending Operations", message: "Wait for pending operations to be synchronized before logging out.")
                        self.hideSpinner()
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self.hideSpinner()
                        self.dismiss(animated: true) { }
                    }
                }
            })
            
            present(alert, animated: true)
        }
    }
    
    @IBAction func doneButtonClicked(_ sender: UIBarButtonItem) {
        dismiss(animated: true) { }
    }
    
}
