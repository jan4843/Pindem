import UIKit

class LoginViewController: UITableViewController {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var logInCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isModalInPresentation = true
        
        usernameTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        usernameTextField.becomeFirstResponder()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) == logInCell else { return }
        logInCell.isSelected = false
        logIn()
    }
    
    func logIn() {
        guard let username = usernameTextField.text,
              let password = passwordTextField.text else {
            showAlert(title: "Invalid Login", message: "Fill the fields with your Pindboard credentails to log in.")
            return
        }
        
        self.showSpinner()
        DispatchQueue.global(qos: .background).async {
            guard let _ = try? AccountManager.shared.logIn(username: username, password: password) else {
                self.showAlert(title: "Invalid Login", message: "The Pinboard credentails cannot be verified.")
                self.hideSpinner()
                return
            }
            
            DispatchQueue.main.async {
                self.hideSpinner()
                self.dismiss(animated: true) { }
            }
        }
    }
    
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            logIn()
        }
        return true
    }
}
