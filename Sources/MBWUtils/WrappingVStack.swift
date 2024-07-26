//
//  WrappingVStack.swift
//
//
//  Created by John Scalo on 7/26/24.
//

#if os(iOS)

import UIKit

/// A UIStackView-like thing that stacks vertically but will wrap onto the next line. Currently only supports very simple views and hasn't been tested with anything complicated like a table or collection view.
open class WrappingVStack: UIView {
    
    /// The views to arrange in the stack.
    public var arrangedSubviews = [UIView]() {
        didSet {
            setNeedsLayout()
        }
    }

    /// The spacing between stack rows. Defaults to 0.
    public var spacing: CGFloat = 0 {
        didSet {
            vstack.spacing = spacing
        }
    }
    
    private var debugLogging = false
    private let vstack = UIStackView(arrangedSubviews: []).forAutoLayout()
    private var layoutWidth: CGFloat = 0
    private var layoutHeight: CGFloat = 0

    public init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        setUpViews()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpViews()
    }
    
    private func setUpViews() {
        vstack.axis = .vertical
        vstack.distribution = .fill
        vstack.alignment = .leading
        addSubview(vstack)
        vstack.constrainToSuperviewEdges()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        guard !arrangedSubviews.isEmpty else {
            layoutWidth = 0
            layoutHeight = 0
            return
        }
        
        func makeNewHStack() -> UIStackView {
            let hstack = UIStackView(arrangedSubviews: [])
            hstack.axis = .horizontal
            hstack.distribution = .equalSpacing
            hstack.spacing = 0
            hstack.alignment = .center
            return hstack
        }
        
        // Avoid unnecessary rebuilds. (Possible bug if arranged views changes after display…)
        if layoutWidth == bounds.width {
            return
        }
        
        layoutWidth = bounds.width
        layoutHeight = 0
        
        // Clear old hstacks
        vstack.arrangedSubviews.forEach { hstack in
            guard let hstack = hstack as? UIStackView else {
                assertionFailure(); return
            }
            hstack.arrangedSubviews.forEach { subview in
                hstack.removeArrangedSubview(subview)
                subview.removeFromSuperview()
            }
            vstack.removeArrangedSubview(hstack)
        }

        
        // Rebuild new hstacks
        var curW: CGFloat = 0 // running width of the current row
        var curMaxH: CGFloat = 0 // running max height of each view, to be added to layoutHeight
        var curHStack: UIStackView = makeNewHStack()
        vstack.addArrangedSubview(curHStack)
        
        for nextView in arrangedSubviews {
            let viewWidth = nextView.autolayoutWidth(for: .greatestFiniteMagnitude)
            let viewHeight = nextView.autolayoutHeight(for: .greatestFiniteMagnitude)
            
            if viewHeight > curMaxH {
                curMaxH = viewHeight
            }
            
            if debugLogging {
                Logger.log("[WrappingVStack] width for \(type(of:nextView)): \(viewWidth)")
                Logger.log("[WrappingVStack] height for \(type(of:nextView)): \(viewHeight)")
            }
            
            if curW + viewWidth > layoutWidth {
                // about to overflow bounds width, start next row
                layoutHeight += curMaxH + spacing
                curMaxH = viewHeight
                curW = 0

                curHStack = makeNewHStack()
                vstack.addArrangedSubview(curHStack)
            }
            
            curHStack.addArrangedSubview(nextView)
            curW += viewWidth
        }
        
        layoutHeight += curMaxH
        
        if debugLogging {
            Logger.log("[WrappingVStack] layoutWidth: \(layoutWidth); layoutHeight: \(layoutHeight)")
        }
    }
    
    public override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric,
                      height: layoutHeight)
    }

}

#endif
