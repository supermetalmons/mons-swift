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
        alpha = 0.5
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

    let upupup = [
        [],
        [0],
        [0, 1],
        [0, 1, 2],
        [1, 2, 3],
        [2, 3, 4],
        [3, 4, 5],
        [4, 5],
        [5],
    ]

    private func setupAnimationImages() {
        for phase in 0..<9 {
            let frameImage = drawWave(phase: phase)
            animationImagesCache.insert(frameImage, at: 0)
        }
        self.animationImages = animationImagesCache
        self.animationDuration = 9 * 0.2 // 0.5s * 12 frames
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

                let color: UIColor = i.isMultiple(of: 2) ? .init(red: 0.4, green: 0.4, blue: 1, alpha: 1) : .cyan
                context.cgContext.setFillColor(color.cgColor)

                let waveWidth = Int(rectangleWidth / rectangleHeight)
                for j in 0..<waveWidth {
                    let x = waveX + CGFloat(j) * rectangleHeight

                    let isUp = upupup[phase].contains(6-waveWidth+j)
                    let y = waveY + (isUp ? -rectangleHeight : 0)

                    let rect = CGRect(x: x, y: y, width: rectangleHeight, height: rectangleHeight)
                    context.cgContext.fill(rect)
                }
            }
        }
        return image
    }

}
