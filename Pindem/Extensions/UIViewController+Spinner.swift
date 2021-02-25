import UIKit

/// Reused across all `UIViewController` instances, leaks insignificant amount of memory
fileprivate var spinnerView: UIView = {
    let spinnerView = UIView(frame: UIScreen.main.bounds)
    let activityIndicatorView = UIActivityIndicatorView()
    activityIndicatorView.center = spinnerView.center
    activityIndicatorView.startAnimating()
    spinnerView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    spinnerView.addSubview(activityIndicatorView)
    spinnerView.alpha = 0
    return spinnerView
}()

extension UIViewController {
    
    func showSpinner() {
        DispatchQueue.main.async {
            UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.addSubview(spinnerView)
            UIView.animate(withDuration: 0.2) { spinnerView.alpha = 1.0 }
        }
    }
    
    func hideSpinner() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2, animations: { spinnerView.alpha = 0.0 }) { _ in
                spinnerView.removeFromSuperview()
            }
        }
    }
    
}
