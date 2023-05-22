// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

// TODO: refactor, tune sizes
class FoggyView: UIView {
    
    private var cell: CAEmitterCell!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupFogEffect()
        clipsToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupFogEffect()
    }

    private func setupFogEffect() {
        let fogEmitter = CAEmitterLayer()
        fogEmitter.emitterShape = .rectangle
        fogEmitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        fogEmitter.emitterSize = bounds.size

        let fog = makeEmitterCell()
        fogEmitter.emitterCells = [fog]

        layer.addSublayer(fogEmitter)
    }
    
    private func makeEmitterCell() -> CAEmitterCell {
        cell = CAEmitterCell()
        cell.alphaRange = 0.5
        cell.alphaSpeed = -0.05
        cell.birthRate = 1
        cell.lifetime = 20.0
        cell.lifetimeRange = 0
        cell.yAcceleration = -0.1
        cell.emissionLongitude = .pi
        cell.emissionRange = .pi / 4

        cell.scaleRange = 0.4
        cell.contents = createCloudShape().cgImage
        return cell
    }

    private func createCloudShape() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 80, height: 60))
        return renderer.image { ctx in
            ctx.cgContext.setFillColor(UIColor.white.withAlphaComponent(0.1).cgColor)
            ctx.cgContext.fillEllipse(in: CGRect(x: 20, y: 20, width: 40, height: 20))
            ctx.cgContext.fillEllipse(in: CGRect(x: 10, y: 30, width: 40, height: 20))
            ctx.cgContext.fillEllipse(in: CGRect(x: 30, y: 30, width: 40, height: 20))
            ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 40, width: 80, height: 20))
            ctx.cgContext.fillEllipse(in: CGRect(x: 20, y: 10, width: 40, height: 20))
            ctx.cgContext.fillEllipse(in: CGRect(x: 10, y: 50, width: 40, height: 20))
            ctx.cgContext.fillEllipse(in: CGRect(x: 30, y: 50, width: 40, height: 20))
        }
    }

    private func updateCloudSize() {
        let scaleFactor = min(bounds.width, bounds.height) / 10
        cell.scale = 0.1 * scaleFactor
        cell.scaleRange = 0.05 * scaleFactor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let emitter = layer.sublayers?.first as? CAEmitterLayer {
            emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
            emitter.emitterSize = bounds.size
            updateCloudSize()
        }
    }
}
