// ∅ 2024 super-metal-mons

import UIKit

class SparklingView: UIView {
    
    private var emitter: CAEmitterLayer!
    private var cell: CAEmitterCell!
    private let style: BoardStyle
    
    init(frame: CGRect, style: BoardStyle) {
        self.style = style
        super.init(frame: frame)
        setupEmitter()
    }
    
    required init?(coder: NSCoder) {
        self.style = .pixel
        super.init(coder: coder)
        setupEmitter()
    }
    
    private func setupEmitter() {
        clipsToBounds = true
        
        emitter = CAEmitterLayer()
        emitter.emitterShape = .rectangle
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        emitter.emitterSize = bounds.size
        emitter.renderMode = .additive
        emitter.beginTime = CACurrentMediaTime()
        
        cell = CAEmitterCell()
        cell.contents = Images.sparkle(style: style).cgImage
        cell.birthRate = 8
        cell.lifetime = 3
        cell.lifetimeRange = 1
        cell.velocity = 5
        cell.velocityRange = 2
        cell.emissionLongitude = 3 * CGFloat.pi / 2
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
        let scaleFactor = min(bounds.width, bounds.height) / 10
        cell.scale = 0.1 * scaleFactor
        cell.scaleRange = 0.05 * scaleFactor
    }
}
