// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

class BoardView: UIView {
    
    private var playerSideColor = Color.white
    private var isFlipped: Bool {
        return playerSideColor != .white
    }
    
    private var subviewsArray: [UIView] = []

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutGrid(rows: 11, columns: 11) // TODO: DRY 11
    }
    
    func setPlayerSide(color: Color) {
        if playerSideColor != color {
            playerSideColor = color
            setNeedsLayout()
        }
    }
    
    func addArrangedSubview(_ view: UIView) {
        addSubview(view)
        subviewsArray.append(view)
    }

    private func layoutGrid(rows: Int, columns: Int) {
        let viewWidth = bounds.width / CGFloat(columns)
        let viewHeight = bounds.height / CGFloat(rows)

        for (index, view) in subviewsArray.enumerated() {
            let row = index / columns
            let column = index % columns
            let x = CGFloat(isFlipped ? columns - column - 1: column) * viewWidth
            let y = CGFloat(isFlipped ? rows - row - 1: row) * viewHeight
            view.frame = CGRect(x: x, y: y, width: viewWidth, height: viewHeight)
        }
    }
    
}
