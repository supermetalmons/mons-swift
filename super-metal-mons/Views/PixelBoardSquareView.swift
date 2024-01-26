// ∅ 2024 super-metal-mons

import UIKit

// TODO: refactor, cleanup
class PixelBoardSquareView: UIImageView {
    
    let squaresPerSide: Int = 32
    let rightPixelsColor: UIColor?
    let bottomPixelsColor: UIColor?

    let location: Location
    
    init(location: Location, rightPixelsColor: UIColor?, bottomPixelsColor: UIColor?) {
        self.location = location
        self.rightPixelsColor = rightPixelsColor
        self.bottomPixelsColor = bottomPixelsColor
        super.init(frame: CGRect.zero)
        setup()
        isUserInteractionEnabled = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        contentMode = .scaleAspectFill
        if rightPixelsColor != nil || bottomPixelsColor != nil {
            drawPixels()
        }
    }

    private func drawPixels() {
        let size = CGSize(width: 64 * UIScreen.main.scale, height: 64 * UIScreen.main.scale)
        let pixelSize: CGFloat = size.width / CGFloat(squaresPerSide)

        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        let ctx = UIGraphicsGetCurrentContext()

        for i in 0..<squaresPerSide {
            if i % 2 == 0 {
                if let bottomPixelsColor = bottomPixelsColor {
                    let x = CGFloat(i) * pixelSize
                    let bottomPixelRect = CGRect(x: x, y: size.height - pixelSize, width: pixelSize, height: pixelSize)
                    ctx?.setFillColor(bottomPixelsColor.cgColor)
                    ctx?.fill(bottomPixelRect)
                }
                
                if let rightPixelsColor = rightPixelsColor {
                    let y = CGFloat(i) * pixelSize
                    let rightPixelRect = CGRect(x: size.width - pixelSize, y: y, width: pixelSize, height: pixelSize)
                    ctx?.setFillColor(rightPixelsColor.cgColor)
                    ctx?.fill(rightPixelRect)
                }
            }
        }

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.image = image
    }
}
