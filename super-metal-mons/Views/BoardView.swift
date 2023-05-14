// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

class BoardView: UIView {
    
    private let rows = Config.boardSize
    
    private var playerSideColor = Color.white
    private var gradientLayers: [UUID: CAGradientLayer] = [:]
    private var lines: [UUID: Line] = [:]
    private var subviewsArray: [UIView] = []
    
    private var isFlipped: Bool { return playerSideColor != .white }
    
    // TODO: pass the whole board model instead
    func addArrangedSubview(_ view: UIView) {
        addSubview(view)
        subviewsArray.append(view)
    }
    
    func setPlayerSide(color: Color) {
        if playerSideColor != color {
            playerSideColor = color
            setNeedsLayout()
        }
    }
    
    func showTrace(from: Location, to: Location) {
        let half = CGFloat(1) / CGFloat(rows * 2)
        let from = CGPoint(x: CGFloat(from.j) / CGFloat(rows) + half, y: CGFloat(from.i) / CGFloat(rows) + half)
        let to = CGPoint(x: CGFloat(to.j) / CGFloat(rows) + half, y: CGFloat(to.i) / CGFloat(rows) + half)
        drawTraceLine(from: to, to: from, color: .green, width: 10)
    }
    
    // MARK: - Private
    
    private func drawTraceLine(from startPoint: CGPoint, to endPoint: CGPoint, color: UIColor, width: CGFloat) {
        let line = Line(from: startPoint, to: endPoint, color: color, width: width)
        let id = UUID()
        lines[id] = line
        createGradientLayer(for: line, id: id)
    }
    
    private func createGradientLayer(for line: Line, id: UUID) {
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = drawPathForLine(line)
        shapeLayer.strokeColor = UIColor.black.cgColor
        shapeLayer.lineWidth = line.width
        shapeLayer.fillColor = nil
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.startPoint = line.from
        gradientLayer.endPoint = line.to
        gradientLayer.colors = [line.color.cgColor, UIColor.clear.cgColor]
        gradientLayer.frame = bounds
        gradientLayer.mask = shapeLayer
        
        layer.addSublayer(gradientLayer)
        gradientLayers[id] = gradientLayer
        
        fadeLine(id: id)
    }
    
    private func fadeLine(id: UUID) {
        guard let gradientLayer = gradientLayers[id] else { return }
        let animation = CABasicAnimation(keyPath: AnimationKey.opacity)
        animation.fromValue = 1
        animation.toValue = 0
        animation.duration = 2
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        animation.delegate = self
        gradientLayer.add(animation, forKey: nil)
    }
    
    private func layoutGrid() {
        let viewWidth = bounds.width / CGFloat(rows)
        let viewHeight = bounds.height / CGFloat(rows)
        
        for (index, view) in subviewsArray.enumerated() {
            let row = index / rows
            let column = index % rows
            let x = CGFloat(isFlipped ? rows - column - 1: column) * viewWidth
            let y = CGFloat(isFlipped ? rows - row - 1: row) * viewHeight
            view.frame = CGRect(x: x, y: y, width: viewWidth, height: viewHeight)
        }
    }
    
    private func drawPathForLine(_ line: Line) -> CGPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: bounds.width * line.from.x, y: bounds.height * line.from.y))
        path.addLine(to: CGPoint(x: bounds.width * line.to.x, y: bounds.height * line.to.y))
        return path.cgPath
    }
    
    // MARK: layout subviews
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutGrid()
        
        for (id, gradientLayer) in gradientLayers {
            guard let line = lines[id] else { continue }
            gradientLayer.frame = bounds
            guard let shapeLayer = gradientLayer.mask as? CAShapeLayer else { continue }
            shapeLayer.path = drawPathForLine(line)
        }
    }
    
}

extension BoardView: CAAnimationDelegate {
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if let id = gradientLayers.first(where: { $0.value.animation(forKey: AnimationKey.opacity) == anim })?.key {
            gradientLayers[id]?.removeFromSuperlayer()
            gradientLayers.removeValue(forKey: id)
        }
    }
    
}

fileprivate struct Line {
    let from: CGPoint
    let to: CGPoint
    let color: UIColor
    let width: CGFloat
}
