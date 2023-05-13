// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

class StarTraceView: UIView {

    override class var layerClass: AnyClass {
        return CAEmitterLayer.self
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupEmitter()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupEmitter()
    }

    private func setupEmitter() {
        let emitter = self.layer as! CAEmitterLayer

        emitter.emitterShape = .line
        emitter.emitterPosition = CGPoint(x: frame.size.width / 2.0, y: 0)
        emitter.emitterSize = CGSize(width: frame.size.width, height: 1)

        let star = CAEmitterCell()

        star.contents = generateParticleImage()
        star.birthRate = 2
        star.lifetime = 3.0
        star.velocity = CGFloat(100)
        star.velocityRange = CGFloat(20)
        star.emissionRange = CGFloat(Double.pi)
        star.yAcceleration = 70.0
        star.scale = 0.02
        star.scaleRange = 0.5
        
        emitter.emitterCells = [star]
    }

    private func generateParticleImage() -> CGImage {
        let size = CGSize(width: 10, height: 10)
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()

        let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        context!.setFillColor(UIColor.white.cgColor)
        path.fill()

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image!.cgImage!
    }
    
}
