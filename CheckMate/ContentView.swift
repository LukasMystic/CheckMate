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
    
    init() {

        Board.columns = 4
        Board.rows = 4
      
        let puzzleFEN = "KBrk/N1pp/qb2/1QR1 w - - 0 1"
        
        _chessboardModel = State(
            initialValue: ChessboardModel(fen: puzzleFEN, rows: 4, columns: 4)
        )
        _fenHistory = State(initialValue: [puzzleFEN])
    }
    
    var body: some View {
        VStack{
            Button("Undo Move"){
                undo()
            }
            .padding()
            
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
                }
                
                .frame(width: 400, height: 400)
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
        
        
    }
}



#Preview {
    ContentView()
}
