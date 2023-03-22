// Copyright © 2023 super metal mons. All rights reserved.

import UIKit

class SpaceView: UIView {
    var row = 0
    var col = 0
    var isSelected = false
}

class MonsboardViewController: UIViewController {
    
    @IBOutlet weak var boardContainerView: UIView!
    @IBOutlet weak var overlayView: UIView!
    
    private let boardSize = 11
    private lazy var squares: [[SpaceView?]] = Array(repeating: Array(repeating: nil, count: boardSize), count: boardSize)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupChessboard()
    }

    @IBAction func playButtonTapped(_ sender: Any) {
        overlayView.isHidden = true
    }
    
    
    @IBAction func ggButtonTapped(_ sender: Any) {
        overlayView.isHidden = false
        // TODO: restart the game
    }
    
    private func setupChessboard() {
        #if targetEnvironment(macCatalyst)
        let screenWidth: CGFloat = 800
        let screenHeight: CGFloat = 1200
        #else
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        #endif
        let squareSize = screenWidth / CGFloat(boardSize)
        let totalBoardSize = screenWidth
        let yOffset = (screenHeight - totalBoardSize) / 2

        for row in 0..<boardSize {
            for col in 0..<boardSize {
                let x = CGFloat(col) * squareSize
                let y = CGFloat(row) * squareSize + yOffset

                let square = SpaceView(frame: CGRect(x: x, y: y, width: squareSize, height: squareSize))
                square.backgroundColor = (row + col) % 2 == 0 ? .white : UIColor(hex: "#CECECE")
                boardContainerView.addSubview(square)
                squares[row][col] = square
                
                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapSquare))
                square.addGestureRecognizer(tapGestureRecognizer)
                square.col = col
                square.row = row
            }
        }
        
        for (i, j) in [(0, 0), (5, 5), (10, 10), (0, 10), (10, 0)] {
            squares[i][j]?.backgroundColor = UIColor(hex: "#1407F5")
        }
        
        for (i, j) in [(5, 0), (5, 10)] {
            squares[i][j]?.backgroundColor = UIColor(hex: "#DDB6F9")
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize * 0.8, height: squareSize * 0.8))
            imageView.image = UIImage(named: "potion")
            imageView.contentMode = .scaleAspectFit
            imageView.center = squares[i][j]?.center ?? CGPoint.zero
            boardContainerView.addSubview(imageView)
            
            monsOnBoard[i][j] = imageView
        }
        
        for (i, j) in [(3, 4), (3, 6), (7, 4), (7, 6), (4, 3), (4, 5), (4, 7), (6, 3), (6, 5), (6, 7)] {
            squares[i][j]?.backgroundColor = UIColor(hex: "#9CE8FC")
            
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize * 0.6, height: squareSize * 0.6))
            imageView.image = UIImage(named: "mana")
            imageView.contentMode = .scaleAspectFit
            imageView.center = squares[i][j]?.center ?? CGPoint.zero
            boardContainerView.addSubview(imageView)
            
            monsOnBoard[i][j] = imageView
        }
        
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize, height: squareSize))
        imageView.image = UIImage(named: "super-mana")
        imageView.contentMode = .scaleAspectFit
        imageView.center = squares[5][5]?.center ?? CGPoint.zero
        boardContainerView.addSubview(imageView)
        monsOnBoard[5][5] = imageView
        
        let mons = ["demon": [(10, 3)], "angel": [(10, 4)], "drainer": [(10, 5)], "spirit": [(10, 6)], "mystic": [(10, 7)]]
        for (key, value) in mons {
            for (i, j) in value {
                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize * 0.9, height: squareSize * 0.9))
                imageView.image = UIImage(named: key)
                imageView.contentMode = .scaleAspectFit
                imageView.center = squares[i][j]?.center ?? CGPoint.zero
                boardContainerView.addSubview(imageView)
                
                monsOnBoard[i][j] = imageView
            }
        }
        
        let flippedMons = ["demon": [(0, 7)], "angel": [(0, 6)], "drainer": [(0, 5)], "spirit": [(0, 4)], "mystic": [(0, 3)]]
        for (key, value) in flippedMons {
            for (i, j) in value {
                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize * 0.9, height: squareSize * 0.9))
                imageView.image = UIImage(named: key)
                imageView.layer.transform = CATransform3DMakeScale(1, -1, 1)
                imageView.contentMode = .scaleAspectFit
                imageView.center = squares[i][j]?.center ?? CGPoint.zero
                boardContainerView.addSubview(imageView)
                
                monsOnBoard[i][j] = imageView
            }
        }
    }
    
    private lazy var monsOnBoard: [[UIImageView?]] = Array(repeating: Array(repeating: nil, count: boardSize), count: boardSize)
    
    var selectedSpace: SpaceView?
    var selectedMon: UIImageView?
    
    @objc private func didTapSquare(sender: UITapGestureRecognizer) {
        guard let spaceView = sender.view as? SpaceView else { return }
        
        let i = spaceView.row
        let j = spaceView.col
        
        // TODO: implement generic input processing depending on game state
        // disable moving into a mon
        // allow moving only
        
        if let mon = monsOnBoard[i][j], selectedMon == nil {
            if spaceView.isSelected {
                spaceView.layer.borderWidth = 0
                spaceView.isSelected = false
                
                selectedSpace = nil
                selectedMon = nil
            } else {
                spaceView.layer.borderWidth = 5
                spaceView.layer.borderColor = UIColor.green.cgColor
                spaceView.isSelected = true
                
                selectedSpace = spaceView
                selectedMon = mon
            }
        } else if let selectedMon = selectedMon, let selectedSpace = selectedSpace {
            selectedMon.center = spaceView.center
            selectedSpace.layer.borderWidth =  0
            selectedSpace.isSelected = false
            self.selectedMon = nil
            self.selectedSpace = nil
            
            monsOnBoard[selectedSpace.row][selectedSpace.col] = nil
            monsOnBoard[i][j] = selectedMon
        }
        

        
        
    }
}

// UIColor extension for handling hex color strings
extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased())
        if hex.hasPrefix("#") {
            scanner.currentIndex = hex.index(after: hex.startIndex)
        }

        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = (rgbValue & 0xFF0000) >> 16
        let g = (rgbValue & 0x00FF00) >> 8
        let b = rgbValue & 0x0000FF

        self.init(
            red: CGFloat(r) / 0xFF,
            green: CGFloat(g) / 0xFF,
            blue: CGFloat(b) / 0xFF,
            alpha: 1.0
        )
    }
}
