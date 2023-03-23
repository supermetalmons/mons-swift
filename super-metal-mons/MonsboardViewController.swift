// Copyright © 2023 super metal mons. All rights reserved.

import UIKit
import FirebaseDatabase

class SpaceView: UIView {
    var row = 0
    var col = 0
    var isSelected = false
}

class MonsboardViewController: UIViewController {
    
    let database = Database.database().reference()
    
    @IBOutlet weak var statusLabel: UILabel!
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
        statusLabel.text = game.prettyGameStatus
        runFirebase()
    }
    
    func runFirebase() {
//        ref.child("https://console.firebase.google.com/u/1/project/mons-e34e5/database/mons-e34e5-default-rtdb/data/")
        database.child("fen").observe(.value) { [weak self] (snapshot) in
            guard let data = snapshot.value as? [String: AnyObject], let fen = data["fen"] as? String else {
                print("No fen found")
                return
            }
            self?.receivedFenFromNetwork(fen: fen)
        }
    }
    
    var lastSharedFen = ""
    
    func quitGame() {
        game = MonsGame()
        sendFen(game.fen)
        statusLabel.text = game.prettyGameStatus
        restartBoardForTest()
    }
    
    func receivedFenFromNetwork(fen: String) {
        guard lastSharedFen != fen, !fen.isEmpty else { return }
        DispatchQueue.main.async {
            self.game = MonsGame(fen: fen)!
            self.restartBoardForTest()
            self.statusLabel.text = self.game.prettyGameStatus
        }
    }
    
    func sendFen(_ fen: String) {
        guard lastSharedFen != fen else { return }
        database.child("fen").setValue(["fen": fen])
        lastSharedFen = fen
    }

    @IBAction func playButtonTapped(_ sender: Any) {
        overlayView.isHidden = true
    }
    
    @IBAction func endTurnButtonTapped(_ sender: Any) {
        game.endTurn()
        
        selectedSpace?.layer.borderWidth = 0
        selectedSpace?.isSelected = false
        selectedSpace = nil
        selectedMon = nil
        
        statusLabel.text = game.prettyGameStatus
    }
    
    @IBAction func ggButtonTapped(_ sender: Any) {
        overlayView.isHidden = false
        quitGame()
        // TODO: restart the game
    }
    
    // TODO: remove this one, this is for development only
    func restartBoardForTest() {
        monsOnBoard.forEach { $0.forEach { $0?.removeFromSuperview() } }
        monsOnBoard = Array(repeating: Array(repeating: nil, count: 11), count: 11)
        setupMonsboard()
    }
    
    private var didSetupBoard = false
    
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

        if !didSetupBoard {
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
        }
        
        // TODO: move to board class
        for (i, line) in game.board.enumerated() {
            for (j, space) in line.enumerated() {
                switch space {
                case .consumable:
                    if !didSetupBoard {
                        squares[i][j]?.backgroundColor = UIColor(hex: "#DDB6F9")
                    }
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
                        if !didSetupBoard {
                            squares[i][j]?.backgroundColor = UIColor(hex: "#9CE8FC")
                        }
                        
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
        didSetupBoard = true
    }
    
    private lazy var monsOnBoard: [[UIImageView?]] = Array(repeating: Array(repeating: nil, count: boardSize), count: boardSize)
    
    var selectedSpace: SpaceView?
    var selectedMon: UIImageView?
    
    @objc private func didTapSquare(sender: UITapGestureRecognizer) {
        guard let spaceView = sender.view as? SpaceView else { return }
        
        // move it into game logic. board only reports touches.
        guard !spaceView.isSelected else {
            spaceView.layer.borderWidth = 0
            spaceView.isSelected = false
            
            selectedSpace = nil
            selectedMon = nil
            return
        }
        
        let i = spaceView.row
        let j = spaceView.col
        
        // TODO: implement generic input processing depending on game state
        // disable moving into a mon
        // allow moving only
        
        if let mon = monsOnBoard[i][j], selectedMon == nil {
            spaceView.layer.borderWidth = 3
            spaceView.layer.borderColor = UIColor.green.cgColor
            spaceView.isSelected = true
            
            selectedSpace = spaceView
            selectedMon = mon
        } else if let selectedMon = selectedMon, let selectedSpace = selectedSpace {
            selectedMon.center = spaceView.center
            selectedSpace.layer.borderWidth =  0
            selectedSpace.isSelected = false
            self.selectedMon = nil
            self.selectedSpace = nil
            
            monsOnBoard[selectedSpace.row][selectedSpace.col] = nil
            monsOnBoard[i][j] = selectedMon
            game.move(from: (selectedSpace.row, selectedSpace.col), to: (i, j))
            
            let fen = game.fen
//            UserDefaults.standard.setValue(, forKey: "fen")
            statusLabel.text = game.prettyGameStatus
            sendFen(fen)
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
