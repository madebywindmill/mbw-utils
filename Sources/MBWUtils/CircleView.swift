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

#endif
