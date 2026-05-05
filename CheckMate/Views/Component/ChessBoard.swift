//
//  ChessBoard.swift
//  CheckMate
//
//  Created by Vannya Ade Gunawan on 04/05/26.
//

import SwiftUI

struct ChessBoard: View {
    let whiteSquare = Color.white
    let blackSquare = Color("AccentColor")
    let boardSize: CGFloat = 344
    let spacing: CGFloat = 5
    let mistakeSquare = Color("MistakeColor")

    //nanti hubungin sama code kalian buat mistake condition ya
    @State var mistake: Bool = true
    @State var rowActive: Int = 1
    @State var columnActive: Int = 2
    
    let pieces: [[String?]] = [
        [nil, nil, "Piece=Rook, Side=Black", "Piece=King, Side=Black"],
        [nil, nil, "Piece=Pawn, Side=Black", "Piece=Pawn, Side=Black"],
        [nil, nil, nil, nil],
        [nil, nil, "Piece=Knight, Side=White", "Piece=King, Side=White"]
    ]
    
    var body: some View {
        let squareSize = (boardSize - spacing * 3) / 4
        
        VStack(spacing: spacing) {
            ForEach(0..<4, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<4, id: \.self) { column in
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 11)
                                .fill((row + column) % 2 == 0 ? whiteSquare : blackSquare)
                            
                            if mistake {
                                if rowActive == row && columnActive == column {
                                        RoundedRectangle(cornerRadius: 11)
                                            .fill(Color.mistake)
                                }
                            }
                            
                            if let pieceName = pieces[row][column] {
                                Image(pieceName)
                                    .resizable()
                                    .scaledToFit()
                                    .padding(10)
                            }
                            
                            if mistake {
                                if rowActive == row && columnActive == column {
                                        Image(systemName:"x.circle.fill")
                                        .foregroundStyle (.black, Color.mistake)
                                        .offset(x: 20, y: 20)

                                }
                            }
                                                                                
                        }
                        .frame(width: squareSize, height: squareSize)
                    }
                }
            }
        }
        .frame(width: boardSize, height: boardSize)
        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    ChessBoard()
}
