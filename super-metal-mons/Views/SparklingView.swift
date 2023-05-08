// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

class SparklingView: UIView {
    
    private var emitter: CAEmitterLayer!
    private var cell: CAEmitterCell!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupEmitter()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupEmitter()
    }
    
    private func setupEmitter() {
        clipsToBounds = true
        
        emitter = CAEmitterLayer()
        emitter.emitterShape = .circle
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        emitter.emitterSize = bounds.size
        emitter.renderMode = .additive
        emitter.beginTime = CACurrentMediaTime()
        
        cell = CAEmitterCell()
        cell.contents = Images.moveEmoji(.action).cgImage
        cell.birthRate = 50
        cell.lifetime = 3
        cell.lifetimeRange = 1
        cell.velocity = 50
        cell.velocityRange = 20
        cell.emissionLongitude = CGFloat.pi
        cell.alphaSpeed = -0.15
        
        updateSparkleSize()
        
        emitter.emitterCells = [cell]
        layer.addSublayer(emitter)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        emitter.emitterSize = bounds.size
        updateSparkleSize()
    }
    
    private func updateSparkleSize() {
        let scaleFactor = min(bounds.width, bounds.height) / 100.0
        cell.scale = 0.1 * scaleFactor
        cell.scaleRange = 0.05 * scaleFactor
    }
}
