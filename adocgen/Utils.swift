//
//  Copyright © 2016 Pavel Sharanda. All rights reserved.
//

import UIKit

func typeName(some: Any) -> String {
    return (some is Any.Type) ? "\(some)" : "\(some.dynamicType)"
}

extension UIImage {
    class func imageWithView(view: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0)
        view.drawViewHierarchyInRect(view.bounds, afterScreenUpdates: true)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img
    }
}

