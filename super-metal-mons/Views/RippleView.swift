// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

class RippleView: UIView {
    
    private var rippleColor: UIColor
    private var ripples: [CALayer] = []
    private var maxRippleCount = 2
    private let initialSize: CGFloat = 2
    private var lineWidth: CGFloat { return max(self.bounds.width, self.bounds.height) * 0.002 } // Adjust this for thinner lines
    
    init(frame: CGRect, rippleColor: UIColor) {
        self.rippleColor = rippleColor
        super.init(frame: frame)
        self.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 0...4) * 400)) {
            self.startAnimating()
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(2000)) {
                self.startAnimating()
            }
        }
    }
    
    private func startAnimating() {
        if ripples.count >= maxRippleCount { return }
        
        let duration: CGFloat = 4
        
        let ripple = CALayer()
        ripple.bounds = CGRect(origin: CGPoint.zero, size: CGSize(width: initialSize, height: initialSize))
        ripple.position = self.center
        ripple.cornerRadius = initialSize / 2
        ripple.borderWidth = lineWidth
        ripple.borderColor = rippleColor.cgColor
        ripple.opacity = 1.0
        
        self.layer.addSublayer(ripple)
        self.ripples.append(ripple)
        
        let maxScale = (min(self.frame.width, self.frame.height) * 0.8) / initialSize
        
        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.toValue = maxScale
        scale.duration = duration
        scale.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 1
        fade.toValue = 0
        fade.duration = duration
        
        let group = CAAnimationGroup()
        group.animations = [scale, fade]
        group.duration = duration
        group.isRemovedOnCompletion = true
        group.fillMode = .forwards
        
        ripple.add(group, forKey: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            ripple.removeFromSuperlayer()
            if let index = self.ripples.firstIndex(of: ripple) {
                self.ripples.remove(at: index)
            }
            self.startAnimating()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        for ripple in ripples {
            ripple.borderWidth = lineWidth
        }
    }
}
