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

    lazy var game: MonsGame = {
        return MonsGame()
//        if let fen = UserDefaults.standard.string(forKey: "fen"), let game = MonsGame(fen: fen) {
//            return game
//        } else {
//            return MonsGame()
//        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMonsboard()
    }

    @IBAction func playButtonTapped(_ sender: Any) {
        overlayView.isHidden = true
    }
    
    
    @IBAction func ggButtonTapped(_ sender: Any) {
        overlayView.isHidden = false
        // TODO: restart the game
    }
    
    // TODO: remove this one, this is for development only
    func restartBoardForTest() {
        boardContainerView.subviews.forEach { $0.removeFromSuperview() }
        squares = Array(repeating: Array(repeating: nil, count: 11), count: 11)
        monsOnBoard = Array(repeating: Array(repeating: nil, count: 11), count: 11)
        setupMonsboard()
    }
    
    private func setupMonsboard() {
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
        
        // TODO: move to board class
        for (i, line) in game.board.enumerated() {
            for (j, space) in line.enumerated() {
                switch space {
                case .consumable:
                    squares[i][j]?.backgroundColor = UIColor(hex: "#DDB6F9")
                    let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize * 0.8, height: squareSize * 0.8))
                    imageView.image = UIImage(named: "potion") // TODO: get name from consumable enum
                    imageView.contentMode = .scaleAspectFit
                    imageView.center = squares[i][j]?.center ?? CGPoint.zero
                    boardContainerView.addSubview(imageView)
                    monsOnBoard[i][j] = imageView
                case let .mon(mon: mon):
                    
                    // TODO: move it from here
                    let name: String
                    switch mon.kind {
                    case .mystic: name = "mystic"
                    case .demon: name = "demon"
                    case .drainer: name = "drainer"
                    case .angel: name = "angel"
                    case .spirit: name = "spirit"
                    }
                    
                    let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize * 0.9, height: squareSize * 0.9))
                    imageView.image = UIImage(named: name)
                    
                    if mon.color == .blue {
                        imageView.layer.transform = CATransform3DMakeScale(1, -1, 1)
                    }
                    
                    imageView.contentMode = .scaleAspectFit
                    imageView.center = squares[i][j]?.center ?? CGPoint.zero
                    boardContainerView.addSubview(imageView)
                    
                    monsOnBoard[i][j] = imageView
                    
                case let .monWithMana(mon: mon, mana: mana):
                    // TODO: implement
                    print(mon, mana)
                case let .mana(mana: mana):
                    switch mana {
                    case let .regular(color: color):
                        squares[i][j]?.backgroundColor = UIColor(hex: "#9CE8FC")
                        
                        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize * 0.6, height: squareSize * 0.6))
                        imageView.image = UIImage(named: "mana")
                        
                        if color == .blue {
                            imageView.layer.transform = CATransform3DMakeScale(1, -1, 1)
                        }
                        
                        imageView.contentMode = .scaleAspectFit
                        imageView.center = squares[i][j]?.center ?? CGPoint.zero
                        boardContainerView.addSubview(imageView)
                        monsOnBoard[i][j] = imageView
                    case .superMana:
                        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize, height: squareSize))
                        imageView.image = UIImage(named: "super-mana")
                        imageView.contentMode = .scaleAspectFit
                        imageView.center = squares[i][j]?.center ?? CGPoint.zero
                        boardContainerView.addSubview(imageView)
                        monsOnBoard[i][j] = imageView
                    }
                case .empty:
                    break
                }
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
            game.move(from: (selectedSpace.row, selectedSpace.col), to: (i, j))
            UserDefaults.standard.setValue(game.fen, forKey: "fen")
            restartBoardForTest()
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
