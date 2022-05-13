//
//  Animation.swift
//  
//  Created by John Scalo on 5/13/22.
//  Copyright © 2018-2022 Made by Windmill. All rights reserved.
//

#if os(iOS)

import UIKit

public extension UIView {

    func doIncorrectAttemptShakeAnimation() {
        // shakes the view like macOS's "wrong password" text field shake animation
        self.frame = self.frame.offsetBy(dx: -1.0, dy: 0.0)
        UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.2, initialSpringVelocity: 1800.0, options: [], animations: {
            self.frame = self.frame.offsetBy(dx: 1.0, dy: 0.0)
        }, completion: nil)
    }
    
    func doBumpUpAnimation() {
        self.frame = self.frame.offsetBy(dx: 0.0, dy: 1.0)
        UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 900.0, options: [], animations: {
            self.frame = self.frame.offsetBy(dx: 0.0, dy: -1.0)
        }, completion: nil)
    }
    
    func doBumpDownAnimation() {
        self.frame = self.frame.offsetBy(dx: 0.0, dy: -1.0)
        UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 900.0, options: [], animations: {
            self.frame = self.frame.offsetBy(dx: 0.0, dy: 1.0)
        }, completion: nil)
    }
    
    func doBounceAnimation(dur1: Double = 0.07,
                           dur2: Double = 0.2,
                           scale: CGFloat = 0.85,
                           completion: (()->())? = nil) {
        UIView.animate(withDuration: dur1,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 12,
                       options: [.allowUserInteraction],
                       animations: {
                        self.transform = CGAffineTransform(scaleX: scale, y: scale)
        }, completion: { _ in
            UIView.animate(withDuration: dur2,
                           delay: 0,
                           usingSpringWithDamping: 0.7,
                           initialSpringVelocity: 6,
                           options: [.allowUserInteraction],
                           animations: {
                            self.transform = CGAffineTransform.identity
            }, completion: { _ in
                completion?()
            })
        })
    }
    
    func fadeOut(duration: TimeInterval = 0.3) {
        UIView.animate(withDuration: duration) {
            self.alpha = 0
        }
    }

    func fadeIn(duration: TimeInterval = 0.3) {
        UIView.animate(withDuration: duration) {
            self.alpha = 1
        }
    }

    func fadeTransition(_ duration:CFTimeInterval) {
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = .fade
        animation.duration = duration
        self.layer.add(animation, forKey: "fade")
    }
    
    func doFlyToViewBumpAnimation(toView: UIView) {
        guard let superview = superview,
            let containerView = superview.window?.rootViewController?.view,
            let toViewScreenRect = toView.superview?.convert(toView.frame, to: nil)
            else { return }
        let viewImage = UIImage.imageFromView(self)
        let imageView = UIImageView(image: viewImage)
        
        let startScreenRect = superview.convert(frame, to: nil)
        let endScreenRect = CGRect(x: toViewScreenRect.midX, y: toViewScreenRect.midY, width: 20, height: 20)
        
        containerView.addSubview(imageView)
        imageView.frame = startScreenRect
        imageView.alpha = 1.0
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: [.curveEaseIn, .allowUserInteraction], animations: {
            imageView.frame = endScreenRect
            imageView.alpha = 0.5

        }) { (animated) in
            imageView.removeFromSuperview()
            toView.doBumpDownAnimation()
        }
                
    }
}

#endif
