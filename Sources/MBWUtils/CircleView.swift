//
//  CircleView.swift
//  
//
//  Created by John Scalo on 5/13/22.
//  Copyright © 2018-2022 Made by Windmill. All rights reserved.
//

#if os(iOS)

import UIKit

/// A UIView that draws itself as a circle, using corner radii.
open class CircleView: UIView {
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width/2
    }
}

/// A UIImageView that draws itself as a circle, using corner radii.
open class CircleImageView: UIImageView {

    open override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width/2
    }

}

/// A UIButton that draws itself as a circle, using corner radii.
open class CircleButton: UIButton {

    open override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width/2
    }

}

#endif
