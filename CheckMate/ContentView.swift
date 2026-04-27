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
    @State var chessboardModel = ChessboardModel (fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
    
    var body: some View {
        Chessboard(chessboardModel: chessboardModel)
            .onMove { move, isLegal, from, to, lan, promotionPiece in
                print ("Move: Fen: \(chessboardModel.fen) - Lan: \(lan)")
                
                if !isLegal {
                    print("Illegal Move: \(lan)")
                    return
                }
                chessboardModel.game.make(move: move)
                chessboardModel.setFen(FenSerialization.default.serialize(position: chessboardModel.game.position), lan: lan)
            }
            .frame(width: 400, height: 400)
    }
    
}



#Preview {
    ContentView()
}
