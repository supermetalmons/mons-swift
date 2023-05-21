// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

// TODO: refactor, optimize, remove magic numbers
class WaveView: UIImageView {
    
    private var animationImagesCache: [UIImage] = []
    private let numberOfWaves = 10
    private var waveWidths: [Int] = []
    private var waveXs: [Int] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupWaveWidths()
        setupAnimationImages()
        startAnimating()
        alpha = 0.69
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWaveWidths()
        setupAnimationImages()
        startAnimating()
    }

    private func setupWaveWidths() {
        waveWidths = (0..<numberOfWaves).map { _ in Int.random(in: 3...6) }
        waveXs = waveWidths.map { Int.random(in: 0..<(32 - $0)) }
    }

    private func setupAnimationImages() {
        for phase in 0..<12 {
            let frameImage = drawWave(phase: phase)
            animationImagesCache.append(frameImage)
        }
        self.animationImages = animationImagesCache
        self.animationDuration = 0.9 * 12
        self.animationRepeatCount = 0 // repeat indefinitely
    }

    private func drawWave(phase: Int) -> UIImage {
        let scale = UIScreen.main.scale
        let pointSize: CGFloat = 64
        let size: CGFloat = pointSize * scale
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { context in
            let rectangleHeight: CGFloat = 2 * scale
            // TODO: remove 24 magic
            let spaceBetweenWaves: CGFloat = ((pointSize-24) / CGFloat(numberOfWaves - 1)).rounded() * scale
            
            for i in 0..<numberOfWaves {
                let rectangleWidth = CGFloat(waveWidths[i]) * rectangleHeight
                
                let startWaveY = 2 * rectangleHeight
                let waveX = CGFloat(waveXs[i]) * rectangleHeight
                let waveY = startWaveY + CGFloat(i) * (rectangleHeight + spaceBetweenWaves)
                
//                let color: UIColor = i < 5 ? .cyan : .white
                let color: UIColor = .white
                context.cgContext.setFillColor(color.cgColor)

                for j in 0..<(Int(rectangleWidth / rectangleHeight)) {
                    let x = waveX + CGFloat(j) * rectangleHeight
                    let isUp = (phase + j).isMultiple(of: 2)
                    let y = waveY + (isUp ? -rectangleHeight : 0)

                    let rect = CGRect(x: x, y: y, width: rectangleHeight, height: rectangleHeight)
                    context.cgContext.fill(rect)
                }
            }
        }
        return image
    }
    
}
