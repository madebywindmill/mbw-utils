//
//  GradientView.swift
//
//  Created by David McGavern on 4/20/18.
//  Copyright © 2018-2022 Made by Windmill. All rights reserved.
//

#if os(iOS)

import UIKit

open class GradientView: UIView {
    
    @IBInspectable open var topColor: UIColor? {
        didSet {
            setNeedsLayout()
        }
    }
    @IBInspectable open var bottomColor: UIColor? {
        didSet {
            setNeedsLayout()
        }
    }
    
    open var isHorizontal: Bool = false {
        didSet {
            setNeedsLayout()
        }
    }
    
    private let gradientLayer = CAGradientLayer()
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setUpView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpView()
    }
    
    
    open override func layoutSubviews() {
        super.layoutSubviews()

        var topColorToUse = topColor
        var bottomColorToUse = bottomColor
        
        if topColorToUse == nil && bottomColorToUse != nil {
            topColorToUse = bottomColorToUse?.withAlphaComponent(0.0)
        }
        
        if bottomColorToUse == nil && topColorToUse != nil {
            bottomColorToUse = topColorToUse?.withAlphaComponent(0.0)
        }
        
        guard let topColor = topColorToUse, let bottomColor = bottomColorToUse else {
            gradientLayer.colors = nil
            return
        }
        
        gradientLayer.frame = bounds
        
        if gradientLayer.superlayer == nil {
            layer.insertSublayer(gradientLayer, at: 0)
        }
        
        gradientLayer.colors = [topColor.cgColor, bottomColor.cgColor]
        
        if isHorizontal {
            gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        } else {
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        }

        gradientLayer.frame = bounds
    }
    
    private func setUpView() {
        // Disable these property animations for best performance while scrolling.
        let actions = ["bounds": NSNull(),
            "position": NSNull(),
            "frame": NSNull()]
        gradientLayer.actions = actions
        backgroundColor = nil
        setNeedsLayout()
    }
    
}

#endif
