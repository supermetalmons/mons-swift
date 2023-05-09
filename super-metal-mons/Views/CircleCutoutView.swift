// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

class CircleCutoutView: UIView {
    
    private var baseColor = UIColor.green
    private var isInverted = false
    
    init(color: UIColor, inverted: Bool = false) {
        super.init(frame: .zero)
        self.baseColor = color
        self.isInverted = inverted
        setupView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        if !isInverted {
            context.setFillColor(baseColor.cgColor)
            context.fill(rect)
        }
        
        let circleRadius = rect.width * 0.56
        let circleCenter = CGPoint(x: rect.midX, y: rect.midY)
        
        
        if !isInverted {
            context.setBlendMode(.clear)
            context.setFillColor(UIColor.clear.cgColor)
        } else {
            context.setFillColor(baseColor.cgColor)
        }
        
        context.fillEllipse(in: CGRect(x: circleCenter.x - circleRadius,
                                       y: circleCenter.y - circleRadius,
                                       width: circleRadius * 2,
                                       height: circleRadius * 2))
    }
    
}
