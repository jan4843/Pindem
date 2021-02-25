import UIKit

extension UITableViewCell {
    
    fileprivate class Stripe: UIView {
        convenience init(_ color: UIColor) {
            self.init()
            backgroundColor = color
            autoresizingMask = [.flexibleHeight, .flexibleRightMargin]
        }
    }
    
    private var stripe: Stripe? {
        subviews
            .filter { $0.isKind(of: UITableViewCell.Stripe.self) }
            .map { $0 as! Stripe }
            .first
    }
    
    var stripeColor: UIColor? {
        get {
            stripe?.backgroundColor
        }
        set {
            stripe?.removeFromSuperview()
            if let newColor = newValue {
                let stripe = Stripe(newColor)
                stripe.frame = CGRect(x: 0, y: 0, width: 3, height: frame.size.height)
                addSubview(stripe)
            }
        }
    }
    
}
