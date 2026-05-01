//
//  ContentView.swift
//  CheckMate
//
//  Created by Alessandro Moreno Lawadinata on 27/04/26.
//

import SwiftUI
import ChessboardKit
import ChessKit

struct ContentView: View {
    @State var chessboardModel: ChessboardModel
    @State var fenHistory: [String]
    
    // for puzzle
    @State var currentLevel: PuzzleLevel
    @State var currentNoce: PuzzleNode
    @State var feedbacktext: String = "Find the best move for white"
    @State var moveEvaluation: MoveEvaluation? = nil
    @State var currentCPUReplyLAN: [String] = []
    
    
    init() {
        
        let level: PuzzleLevel
        do{
            level = try PuzzleLevel.load(fromBundle: "Level1")
        }
        catch{
            fatalError("Could not load Level1.json: \(error)")
        }
        
        
        Board.columns = level.columns
        Board.rows = level.rows
        
        _currentLevel = State(initialValue: level)
        _currentNoce = State(initialValue: level.rootNode)
        
        _feedbacktext = State(initialValue: level.objective)
        
        
        _chessboardModel = State(
            initialValue: ChessboardModel(fen: level.initialFEN, rows: level.rows, columns: level.columns)
        )
        _fenHistory = State(initialValue: [level.initialFEN])
    }
    
    var body: some View {
        VStack{
            
            if let eval = moveEvaluation{
                Text(eval.rawValue)
                    .font(.title2).bold()
                    .foregroundColor(eval == .brilliant || eval == .best ? .green : .red)
                
            }
            Text(feedbacktext).padding()
            
            
            //            Button("Undo Move"){
            //                undo()
            //            }
            
                .padding(.bottom)
            
            Chessboard(chessboardModel: chessboardModel)
                .onMove { move, isLegal, from, to, lan, promotionPiece in
                    print("Move: Fen: \(chessboardModel.fen) - Lan: \(lan)")
                    
                    if !isLegal {
                        print("Illegal Move: \(lan)")
                        return
                    }
                    
                    chessboardModel.game.make(move: move)
                    chessboardModel.setFen(FenSerialization.default.serialize(position: chessboardModel.game.position), lan: lan)
                    
                    let newFen = FenSerialization.default.serialize(position: chessboardModel.game.position)
                    chessboardModel.setFen(newFen, lan: lan)
                    
                    // append to the state
                    fenHistory.append(newFen)
                    
                    evaluateMove(lan: lan)
                }
                .overlay{
                    
                    
                    if moveEvaluation == .blunder || moveEvaluation == .mistake{
                        // arrow drawing eg
                        
                        
                        ForEach(currentCPUReplyLAN, id: \.self) {
                            arrowLAN in
                            ArrowOverlay (lan: arrowLAN,
                                          columns: chessboardModel.columns,
                                          rows: chessboardModel.rows,
                                          shouldFlip: chessboardModel.shouldFlipBoard,
                            )
                            .allowsHitTesting(false)
                        }
                        

                        
                        // automatic undo when tap the board
                        Color.white.opacity(0.001)
                            .onTapGesture {
                                undo()
                            }
                    }
                }
            
                .frame(width: 400, height: 400)
        }
    }
    
    
    private func evaluateMove(lan: String){
        currentCPUReplyLAN = []
        if let outcome = currentNoce.expectedMoves[lan]{
            moveEvaluation = outcome.evaluation
            feedbacktext = outcome.feedback
            
            if outcome.evaluation == .brilliant || outcome.evaluation == .best {
                if let cpuLANString = outcome.cpuReplyLAN {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6)
                    {
                        // make cpu move from JSON
                        let cpuLAN = cpuLANString.components(separatedBy: ",").first ?? cpuLANString
                        
                        let cpuMove = Move(string: cpuLAN)
                        chessboardModel.game.make(move: cpuMove)
                        let nextFEN = FenSerialization.default.serialize(position: chessboardModel.game.position)
                        chessboardModel.setFen(nextFEN, lan: cpuLAN)
                        fenHistory.append(nextFEN)
                        
                        if let next = outcome.nextNode {
                            currentNoce = next
                        }
                        moveEvaluation = nil
                        feedbacktext = "Find the next best move"
                    }
                }
                
            }
            else {
                if let replyString = outcome.cpuReplyLAN {
                    currentCPUReplyLAN = replyString.replacingOccurrences(of: " ", with: "").components(separatedBy: ",")
                }
                feedbacktext += "\nUndo and try again."
            }
            
        }
        else {
            moveEvaluation = .mistake
            feedbacktext = "That's not the best move. Try again"
            
        }
    }
    
    private func undo() {
        guard let startFEN = fenHistory.first else {return}
        
        let playerColor = FenSerialization.default.deserialize(fen: startFEN).state.turn
        
        let currentFEN = chessboardModel.turn
        
        // if it's from player then undo 1 move, if it's from engine then undo 2
        let moves = (currentFEN == playerColor) ? 2 : 1
        guard fenHistory.count > moves else {return} // just in case
        
        fenHistory.removeLast(moves)
        
        if let previousFEN = fenHistory.last {
            chessboardModel.setFen(previousFEN)
        }
        moveEvaluation =  nil
        currentCPUReplyLAN = []
        feedbacktext = currentLevel.objective
        
    }
}



#Preview {
    ContentView()
}

// arrow design (sadly hardcoded first)

// MARK: - Arrow Drawing Views

struct ArrowOverlay: View {
    let lan: String
    let columns: Int
    let rows: Int
    let shouldFlip: Bool
    
    var body: some View {
        GeometryReader { geo in
            let sqWidth = geo.size.width / CGFloat(columns)
            let sqHeight = geo.size.height / CGFloat(rows)
            let startSquare = String(lan.prefix(2))
            let endSquare = String(lan.suffix(2).prefix(2))
            
            let startPoint = point(for: startSquare, sqWidth: sqWidth, sqHeight: sqHeight)
            let endPoint = point(for: endSquare, sqWidth: sqWidth, sqHeight: sqHeight)
            Path { path in
                path.move(to: startPoint)
                path.addLine(to: endPoint)
            }
            .stroke(Color.red.opacity(0.7), lineWidth: sqWidth * 0.15)
            
            ArrowHead(start: startPoint, end: endPoint, width: sqWidth * 0.35)
                .fill(Color.red.opacity(0.7))
        }
    }
    
    /// Converts a square coordinate like "b2" into a graphical CGPoint
    func point(for square: String, sqWidth: CGFloat, sqHeight: CGFloat) -> CGPoint {
        guard square.count >= 2 else { return .zero }
        
        let fileChar = square.first!
        let rankChar = square.last!
        
        // Convert 'a' -> 0, 'b' -> 1
        let file = Int(fileChar.asciiValue! - Character("a").asciiValue!)
        // Convert '1' -> 0, '2' -> 1
        let rank = Int(String(rankChar))! - 1
        
        let col = shouldFlip ? (columns - 1) - file : file
        let row = shouldFlip ? rank : (rows - 1) - rank
        
        return CGPoint(x: (CGFloat(col) + 0.5) * sqWidth,
                       y: (CGFloat(row) + 0.5) * sqHeight)
    }
}

struct ArrowHead: Shape {
    let start: CGPoint
    let end: CGPoint
    let width: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let angle = atan2(end.y - start.y, end.x - start.x)
        let length = width
        
        let tip = end
        
        let left = CGPoint(
            x: end.x - length * cos(angle - .pi / 6),
            y: end.y - length * sin(angle - .pi / 6)
        )
        
        let right = CGPoint(
            x: end.x - length * cos(angle + .pi / 6),
            y: end.y - length * sin(angle + .pi / 6)
        )
        
        path.move(to: tip)
        path.addLine(to: left)
        path.addLine(to: right)
        path.closeSubpath()
        return path
    }
}
