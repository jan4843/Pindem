import UIKit

extension UIViewController {
    func showAlert(title: String?, message: String?) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
            self?.present(alert, animated: true, completion: nil)
        }
    }
}
