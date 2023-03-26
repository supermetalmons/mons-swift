// Copyright © 2023 super metal mons. All rights reserved.

import UIKit
import FirebaseDatabase

class SpaceView: UIView {
    var row = 0
    var col = 0
}

class MonsboardViewController: UIViewController {
    
    let database = Database.database().reference()
    private var lastSharedFen = ""
    
    private lazy var monsOnBoard: [[UIImageView?]] = Array(repeating: Array(repeating: nil, count: boardSize), count: boardSize)
    
    private var didSetupBoard = false
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var boardContainerView: UIView!
    @IBOutlet weak var overlayView: UIView!
    
    private let boardSize = 11
    private lazy var squares: [[SpaceView?]] = Array(repeating: Array(repeating: nil, count: boardSize), count: boardSize)

    lazy var game: MonsGame = {
        return MonsGame() // TODO: load the last game if there is one
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMonsboard()
        statusLabel.text = game.prettyGameStatus
        runFirebase()
    }
    
    func runFirebase() {
        database.child("fen").observe(.value) { [weak self] (snapshot) in
            guard let data = snapshot.value as? [String: AnyObject], let fen = data["fen"] as? String else {
                print("No fen found")
                return
            }
            self?.receivedFenFromNetwork(fen: fen)
        }
    }
    
    func receivedFenFromNetwork(fen: String) {
        guard lastSharedFen != fen, !fen.isEmpty else { return }
        DispatchQueue.main.async {
            self.game = MonsGame(fen: fen)!
            self.restartBoardForTest()
            self.statusLabel.text = self.game.prettyGameStatus
            if let winner = self.game.winnerColor {
                self.didWin(color: winner)
            }
        }
    }
    
    func didWin(color: Color) {
        let alert = UIAlertController(title: color == .red ? "🔴" : "🔵", message: "all done", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "ok", style: .default) { [weak self] _ in
            // TODO: do not restart the game if the opponent has done so already
            // or i guess in these case there should be a new game id exchage
            self?.quitGame()
        }
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    func sendFen(_ fen: String) {
        guard lastSharedFen != fen else { return }
        database.child("fen").setValue(["fen": fen])
        lastSharedFen = fen
    }
    
    func quitGame() {
        game = MonsGame()
        sendFen(game.fen)
        statusLabel.text = game.prettyGameStatus
        restartBoardForTest()
    }

    @IBAction func playButtonTapped(_ sender: Any) {
        overlayView.isHidden = true
    }
    
    @IBAction func endTurnButtonTapped(_ sender: Any) {
        let effects = game.endTurn()
        applyEffects(effects)
    }
    
    @IBAction func ggButtonTapped(_ sender: Any) {
        overlayView.isHidden = false
        quitGame()
    }
    
    // TODO: remove this one, this is for development only
    func restartBoardForTest() {
        monsOnBoard.forEach { $0.forEach { $0?.removeFromSuperview() } }
        monsOnBoard = Array(repeating: Array(repeating: nil, count: 11), count: 11)
        setupMonsboard()
    }
    
    private var squareSize = CGFloat.zero
    
    private func setupMonsboard() {
        #if targetEnvironment(macCatalyst)
        let screenWidth: CGFloat = 800
        let screenHeight: CGFloat = 1200
        #else
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        #endif
        squareSize = screenWidth / CGFloat(boardSize)
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
        for i in game.board.indices {
            for j in game.board[i].indices {
                updateCell(i, j)
            }
        }
        didSetupBoard = true
    }
    
    private func updateCell(_ i: Int, _ j: Int) {
        
        // TODO: look at the data and do nothing when nothing changed
        
        let space = game.board[i][j]
        switch space {
        case .consumable:
            if !didSetupBoard {
                // TODO: this would brake when we start with the ongoing game
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
            
            if mon.isFainted {
                imageView.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
            }
            
            imageView.contentMode = .scaleAspectFit
            imageView.center = squares[i][j]?.center ?? CGPoint.zero
            boardContainerView.addSubview(imageView)
            
            monsOnBoard[i][j] = imageView
            
        case let .monWithMana(mon: mon, mana: mana):
            // TODO: refactor. there is the same code in mon and mana case
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
            
            switch mana {
            case let .regular(color: color):
                let manaView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize * 0.6, height: squareSize * 0.6))
                manaView.image = UIImage(named: "mana")
                
                if color == .blue {
                    manaView.layer.transform = CATransform3DMakeScale(1, -1, 1)
                }
                
                manaView.contentMode = .scaleAspectFit
                imageView.addSubview(manaView)
            case .superMana:
                let manaView = UIImageView(frame: CGRect(x: 0, y: 0, width: squareSize, height: squareSize))
                manaView.image = UIImage(named: "super-mana")
                manaView.contentMode = .scaleAspectFit
                imageView.addSubview(manaView)
                monsOnBoard[i][j] = imageView
            }
            
            monsOnBoard[i][j] = imageView
            
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
    
    @objc private func didTapSquare(sender: UITapGestureRecognizer) {
        guard let spaceView = sender.view as? SpaceView else { return }
        
        let i = spaceView.row // TODO: use location model here as well
        let j = spaceView.col
        
        let effects = game.didTapSpace((i, j))
        applyEffects(effects)
    }
    
    private func applyEffects(_ effects: [Effect]) {
        for effect in effects {
            switch effect {
            case .updateCell(let index):
                monsOnBoard[index.0][index.1]?.removeFromSuperview()
                monsOnBoard[index.0][index.1] = nil
                updateCell(index.0, index.1)
            case .setSelected(let selected, let index):
                squares[index.0][index.1]?.layer.borderColor = UIColor.green.cgColor
                squares[index.0][index.1]?.layer.borderWidth = selected ? 3 : 0
            case .updateGameStatus:
                statusLabel.text = game.prettyGameStatus
                sendFen(game.fen)
                
                if let winner = game.winnerColor {
                    didWin(color: winner)
                }
            }
        }
    }
    
}

// TODO: remove this extension. use colors assets catalog
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
