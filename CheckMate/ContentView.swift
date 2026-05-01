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
            
            
            Button("Undo Move"){
                undo()
            }
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
                
                .frame(width: 400, height: 400)
        }
        }
    
    
    private func evaluateMove(lan: String){
        if let outcome = currentNoce.expectedMoves[lan]{
            moveEvaluation = outcome.evaluation
            feedbacktext = outcome.feedback
            
            if outcome.evaluation == .brilliant || outcome.evaluation == .best {
                if let cpuLAN = outcome.cpuReplyLAN {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6)
                    {
                        // make cpu move from JSON
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
        feedbacktext = currentLevel.objective
        
    }
}



#Preview {
    ContentView()
}
