// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

protocol BoardViewDelegate: AnyObject {
    func didTapSquare(location: Location)
}

class BoardView: UIView {
    
    private weak var delegate: BoardViewDelegate?
    
    private let boardSize = Config.boardSize
    private var playerSideColor = Color.white
    private var isFlipped: Bool { playerSideColor != .white }
    private var squareSize: CGFloat { bounds.height / CGFloat(boardSize) }
    
    private var board: Board!
    private var style: BoardStyle!
    
    private var squares = [BoardSquareView]()
    private var effectViews = [Location: UIView]()
    private var itemViews = [Location: BoardItemView]()
    
    private var gradientLayers = [UUID: CAGradientLayer]()
    private var traces = [UUID: Trace]()
    
    private lazy var tracesColors = Colors.traces(style: style)
    private var currentTraceColorIndex = 0
    private var nextTraceColors: [CGColor] {
        guard currentTraceColorIndex < tracesColors.count - 1 else {
            currentTraceColorIndex = 0
            return self.nextTraceColors
        }
        
        let from = tracesColors[currentTraceColorIndex]
        let to = tracesColors[currentTraceColorIndex + 1]
        currentTraceColorIndex += 1
        
        return [from.cgColor, to.cgColor]
    }
    
    func setup(board: Board, style: BoardStyle, delegate: BoardViewDelegate) {
        self.delegate = delegate
        self.board = board
        self.style = style
        for i in 0..<boardSize {
            for j in 0..<boardSize {
                let location = Location(i, j)
                let square = BoardSquareView(location: location)
                square.backgroundColor = Colors.square(board.square(at: location).color(location: location), style: style)
                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapSquare))
                square.addGestureRecognizer(tapGestureRecognizer)
                squares.append(square)
                addSubview(square)
                
                if case .manaPool = board.square(at: location) {
                    let waveView = WaveView(frame: CGRect(origin: .zero, size: CGSize(width: squareSize, height: squareSize)))
                    square.addSubviewConstrainedToFrame(waveView) // TODO: use manual layout here as well
                }
            }
        }
    }
    
    func setNewBoard(_ board: Board) {
        self.board = board
        reloadItems()
    }
    
    func removeHighlights() {
        effectViews.values.forEach { $0.removeFromSuperview() }
        effectViews = [:]
    }
    
    func updateCells(_ locations: [Location]) {
        for location in locations {
            updateCell(location)
        }
    }
    
    func reloadItems() {
        itemViews.values.forEach { $0.removeFromSuperview() }
        itemViews = [:]
        updateCells(Array(Set(Array(board.items.keys) + board.allMonsBases)))
    }
    
    func setPlayerSide(color: Color) {
        if playerSideColor != color {
            playerSideColor = color
            setNeedsLayout()
        }
    }
    
    func showTraces(_ traces: [Trace]) {
        for trace in traces {
            showTrace(trace)
        }
    }
    
    func addHighlights(_ highlights: [Highlight]) {
        var blinkingViews = [UIView]()
        
        for highlight in highlights {
            
            let containerView = UIView()
            containerView.layer.zPosition = 500
            containerView.isUserInteractionEnabled = false
            effectViews[highlight.location] = containerView
            addSubview(containerView)
            
            let color = highlight.color
            switch highlight.kind {
            case .selected:
                let effectView = CircleCutoutView(color: Colors.highlight(color, style: style), inverted: true)
                containerView.addSubviewConstrainedToFrame(effectView)
                
            case .emptySquare:
                let effectView = CircleView()
                effectView.backgroundColor = Colors.highlight(color, style: style)
                effectView.translatesAutoresizingMaskIntoConstraints = false
                
                containerView.addSubview(effectView)
                NSLayoutConstraint.activate([
                    effectView.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.3),
                    effectView.heightAnchor.constraint(equalTo: containerView.heightAnchor, multiplier: 0.3),
                    effectView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                    effectView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
                ])
                
            case .targetSuggestion:
                let effectView = CircleCutoutView(color: Colors.highlight(color, style: style), inverted: false)
                containerView.addSubviewConstrainedToFrame(effectView)
                if highlight.isBlink {
                    blinkingViews.append(containerView)
                }
            }
        }
        
        if !blinkingViews.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                for blinkingView in blinkingViews {
                    blinkingView.removeFromSuperview()
                }
                blinkingViews = []
            }
        }
    }
    
    // MARK: Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let squareSize = self.squareSize
        
        for view in squares {
            view.frame = frame(location: view.location, squareSize: squareSize)
            
        }
        
        for (location, view) in effectViews {
            view.frame = frame(location: location, squareSize: squareSize)
        }
        
        for (location, view) in itemViews {
            view.frame = frame(location: location, squareSize: squareSize)
        }
        
        for (id, gradientLayer) in gradientLayers {
            guard let trace = traces[id] else { continue }
            gradientLayer.frame = bounds
            guard let shapeLayer = gradientLayer.mask as? CAShapeLayer else { continue }
            shapeLayer.lineWidth = squareSize * trace.proportionalWidth
            shapeLayer.path = drawPathForTrace(trace)
        }
    }
    
    private func frame(location: Location, squareSize: CGFloat) -> CGRect {
        let x = CGFloat(isFlipped ? boardSize - location.j - 1: location.j) * squareSize
        let y = CGFloat(isFlipped ? boardSize - location.i - 1: location.i) * squareSize
        return CGRect(x: x, y: y, width: squareSize, height: squareSize)
    }
    
    // MARK: - Private
    
    private func updateCell(_ location: Location) {
        itemViews[location]?.removeFromSuperview()
        itemViews.removeValue(forKey: location)
        
        let item = board.item(at: location)
        
        let containerView = BoardItemView()
        containerView.layer.zPosition = 1000
        containerView.isUserInteractionEnabled = false
        itemViews[location] = containerView
        addSubview(containerView)
        
        switch item {
        case let .consumable(consumable):
            let sparklingView = SparklingView(frame: containerView.bounds, style: style)
            containerView.addSubviewConstrainedToFrame(sparklingView)
            
            let imageView = UIImageView(image: Images.consumable(consumable, style: style))
            imageView.contentMode = .scaleAspectFit
            sparklingView.addSubviewConstrainedToFrame(imageView)
            
        case let .mon(mon: mon):
            let imageView = UIImageView(image: Images.mon(mon, style: style))
            
            if mon.isFainted {
                imageView.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
            }
            
            imageView.contentMode = .scaleAspectFit
            
            containerView.addSubviewConstrainedToFrame(imageView)
            
        case let .monWithMana(mon: mon, mana: mana):
            let imageView = UIImageView(image: Images.mon(mon, style: style))
            
            imageView.contentMode = .scaleAspectFit
            containerView.addSubviewConstrainedToFrame(imageView)
            
            let manaView = UIImageView(image: Images.mana(mana, picked: true, style: style))
            manaView.contentMode = .scaleAspectFit
            
            imageView.addSubview(manaView)
            manaView.translatesAutoresizingMaskIntoConstraints = false
            
            switch mana {
            case .regular:
                NSLayoutConstraint.activate([
                    manaView.widthAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.93),
                    manaView.heightAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: 0.93),
                    NSLayoutConstraint(item: manaView, attribute: .centerX, relatedBy: .equal, toItem: imageView, attribute: .centerX, multiplier: 1.61, constant: 0),
                    NSLayoutConstraint(item: manaView, attribute: .centerY, relatedBy: .equal, toItem: imageView, attribute: .centerY, multiplier: 1.45, constant: 0)
                ])
            case .supermana:
                NSLayoutConstraint.activate([
                    manaView.widthAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.74),
                    manaView.heightAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: 0.74),
                    manaView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
                    NSLayoutConstraint(item: manaView, attribute: .centerY, relatedBy: .equal, toItem: imageView, attribute: .centerY, multiplier: 0.5, constant: 0)
                ])
            }
            
        case let .mana(mana: mana):
            switch mana {
            case .regular:
                let imageView = UIImageView(image: Images.mana(mana, style: style))
                imageView.contentMode = .scaleAspectFit
                containerView.addSubviewConstrainedToFrame(imageView)
            case .supermana:
                let imageView = UIImageView(image: Images.mana(mana, style: style))
                imageView.contentMode = .scaleAspectFit
                containerView.addSubviewConstrainedToFrame(imageView)
            }
        case .none:
            if case let .monBase(kind: kind, color: color) = board.square(at: location) {
                let imageView = UIImageView(image: Images.mon(Mon(kind: kind, color: color), style: style))
                imageView.contentMode = .scaleAspectFit
                imageView.translatesAutoresizingMaskIntoConstraints = false
                
                containerView.addSubview(imageView)
                NSLayoutConstraint.activate([
                    imageView.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.6),
                    imageView.heightAnchor.constraint(equalTo: containerView.heightAnchor, multiplier: 0.6),
                    imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                    imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
                ])
                
                imageView.alpha = 0.4
            }
            
        case .monWithConsumable(mon: let mon, consumable: let consumable):
            let imageView = UIImageView(image: Images.mon(mon, style: style))
            
            imageView.contentMode = .scaleAspectFit
            containerView.addSubviewConstrainedToFrame(imageView)
            
            let consumableView = UIImageView(image: Images.consumable(consumable, style: style))
            consumableView.contentMode = .scaleAspectFit
            
            imageView.addSubview(consumableView)
            consumableView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                consumableView.widthAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.54),
                consumableView.heightAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: 0.54),
                NSLayoutConstraint(item: consumableView, attribute: .centerX, relatedBy: .equal, toItem: imageView, attribute: .centerX, multiplier: 1.60, constant: 0),
                NSLayoutConstraint(item: consumableView, attribute: .centerY, relatedBy: .equal, toItem: imageView, attribute: .centerY, multiplier: 1.50, constant: 0)
            ])
        }
    }
    
    @objc private func didTapSquare(sender: UITapGestureRecognizer) {
        guard let squareView = sender.view as? BoardSquareView else { return }
        delegate?.didTapSquare(location: squareView.location)
    }
    
    private func showTrace(_ trace: Trace) {
        let id = UUID()
        traces[id] = trace
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = drawPathForTrace(trace)
        shapeLayer.strokeColor = UIColor.black.cgColor
        shapeLayer.lineWidth = squareSize * trace.proportionalWidth
        shapeLayer.fillColor = nil
        
        let gradientLayer = CAGradientLayer()
        
        gradientLayer.startPoint = trace.toPointRelativePosition(boardSize: boardSize, isFlipped: isFlipped)
        gradientLayer.endPoint = trace.fromPointRelativePosition(boardSize: boardSize, isFlipped: isFlipped)
        
        gradientLayer.colors = nextTraceColors
        gradientLayer.frame = bounds
        gradientLayer.mask = shapeLayer
        
        layer.addSublayer(gradientLayer)
        gradientLayers[id] = gradientLayer
        
        let animation = CABasicAnimation(keyPath: AnimationKey.opacity)
        animation.fromValue = 1
        animation.toValue = 0
        animation.duration = 2
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        animation.delegate = self
        gradientLayer.add(animation, forKey: nil)
    }
    
    private func drawPathForTrace(_ trace: Trace) -> CGPath {
        let path = UIBezierPath()
        let from = trace.fromPointRelativePosition(boardSize: boardSize, isFlipped: isFlipped)
        let to = trace.toPointRelativePosition(boardSize: boardSize, isFlipped: isFlipped)
        path.move(to: CGPoint(x: bounds.width * from.x, y: bounds.height * from.y))
        path.addLine(to: CGPoint(x: bounds.width * to.x, y: bounds.height * to.y))
        return path.cgPath
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
