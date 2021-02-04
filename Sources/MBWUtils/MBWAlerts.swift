//
//  MBWAlerts.swift
//
//  Created by John Scalo on 7/17/18.
//  Copyright © 2018-2021 Made by Windmill. All rights reserved.
//

#if os(iOS)

import UIKit

public class AlertController : UIAlertController {
    public class func showSimpleAlert(title: String, message: String, vc: UIViewController, completion: (() -> Void)? = nil) {
        let alert = AlertController(title: title, message: message, preferredStyle: .alert)
        
        if completion == nil {
            alert.addAction(UIAlertAction(title: "OK", style: .default))
        } else {
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {(UIAlertAction) in
                completion!()
            }))
        }
        vc.present(alert, animated: true)
    }
    
    public class func showErrorAlert(title: String, error: Error, vc: UIViewController, completion: (() -> Void)? = nil) {
        AlertController.showSimpleAlert(title: title, message: "\(error.localizedDescription) (\((error as NSError).code))", vc: vc) {
            completion?()
        }
    }
    
    public class func showBlockingAlertWithSpinner(title: String, allowCancel: Bool = false, vc: UIViewController, cancelBlock: (()->Void)? = nil) -> AlertController {
        let alert = AlertController(title: title + "\n\n\n", message: nil, preferredStyle: .alert)
        if allowCancel {
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                cancelBlock?()
            }))
        }
        
        //create an activity indicator
        let indicator = UIActivityIndicatorView()
        if #available(iOS 13.0, *) {
            indicator.style = .large
        } else {
            indicator.style = .whiteLarge
        }
        indicator.color = #colorLiteral(red: 0.1956433058, green: 0.2113749981, blue: 0.2356699705, alpha: 1)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        
        //add the activity indicator as a subview of the alert controller's view
        alert.view.addSubview(indicator)
        
        if title.isEmpty {
            indicator.constrainToSuperviewYCenter()
        } else {
            indicator.constrainToSuperviewBottom(offset: allowCancel ? 60 : 30)
        }
        indicator.constrainToSuperviewXCenter()
        
        indicator.isUserInteractionEnabled = false // required otherwise if there buttons in the UIAlertController you will not be able to press them
        indicator.startAnimating()
        
        vc.present(alert, animated: true)
        
        return alert
    }
    
    
}

#endif
