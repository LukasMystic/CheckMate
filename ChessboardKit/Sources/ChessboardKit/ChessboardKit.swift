//
// ChessboardKit is a SwiftUI library for rendering chessboards and pieces.
//
// See the GitHub repo for documentation:
// https://github.com/rohanrhu/ChessboardKit
//
// Copyright (C) 2025, Oğuzhan Eroğlu (https://meowingcat.io)
// Licensed under the MIT License.
// You may obtain a copy of the License at: https://opensource.org/licenses/MIT
// See the LICENSE file for more information.
//

import SwiftUI

import ChessKit

public let EMPTY_FEN = "8/8/8/8/8/8/8/8 w - - 0 1"
public let INITIAL_FEN = "rnbqkb1r/pppppppp/8/8/8/8/PPPPPPPP/RNBQKB1R w KQkq - 0 1"

public struct BoardSquare: Identifiable, Hashable {
    public var row: Int
    public var column: Int
    
    public var id: String {
        "\(row),\(column)"
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(row)
        hasher.combine(column)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.row == rhs.row && lhs.column == rhs.column
    }
    
    public static func != (lhs: Self, rhs: Self) -> Bool {
        lhs.row != rhs.row || lhs.column != rhs.column
    }
}

@Observable
public class ChessboardModel {
    
    
    public var rows: Int
    public var columns: Int
    
    public var fen: String {
        get { FenSerialization.default.serialize(position: game.position) }
        set { game = Game(position: FenSerialization.default.deserialize(fen: newValue)) }
    }
    public var size: CGFloat = 0
    
    public var colorScheme: ChessboardColorScheme = .light
    
    public var perspective: PieceColor
    public var turn: PieceColor { game.position.state.turn }
    public var validateMoves: Bool = false
    public var allowOpponentMove = false
    
    public var inWaiting = false
    
    public var selectedSquare: BoardSquare?
    public var hintedSquares: Set<BoardSquare> = []
    
    public var highlightLegalMoves: Bool = true
    public var legalMoveSquares: Set<BoardSquare> = []
    
    public var showPromotionPicker = false
    
    public var game: Game
    
    public var currentMove: Move? = nil
    public var prevMove: Move? = nil
    
    public var promotionPiece: Piece?
    public var promotionSourceSquare: String?
    public var promotionTargetSquare: String?
    public var promotionLan: String?
    
    public var shouldFlipBoard: Bool { perspective == .black }
    
    public var movingPiece: (piece: Piece, from: BoardSquare, to: BoardSquare)?
    
    public init(fen: String = EMPTY_FEN,
                perspective: PieceColor = .white,
                colorScheme: ChessboardColorScheme = .light,
                allowOpponentMove: Bool = false,
                highlightLegalMoves: Bool = true,
                rows: Int = 8,       // default 8
                columns: Int = 8)    // default 8
    {
        self.rows = rows
        self.columns = columns
        self.game = Game(position: FenSerialization.default.deserialize(fen: fen))
        self.perspective = perspective
        self.colorScheme = colorScheme
        self.allowOpponentMove = allowOpponentMove
        self.highlightLegalMoves = highlightLegalMoves
    }
    
    public var onMove: (Move, Bool, String, String, String, PieceKind? ) -> Void = { _, _, _, _, _, _ in }
    
    public var dropTarget: (row: Int, column: Int)?
    
    public func setFen(_ fen: String, lan: String? = nil) {
        prevMove = currentMove
        currentMove = lan == nil ? nil : Move(string: lan!)
        
        if currentMove != nil {
            let pieces = game.position.board.enumeratedPieces()
            let squareAndPiece = pieces.first { $0.0 == currentMove?.from }
            
            if let square = squareAndPiece?.0,
               let piece = squareAndPiece?.1
            {
                let from = BoardSquare(row: square.rank, column: square.file)
                let to = BoardSquare(row: currentMove!.to.rank, column: currentMove!.to.file)
                
                movingPiece = (piece: piece, from: from, to: to)
            }
        }
        
        self.fen = fen
    }
    
    public func deselect() {
        selectedSquare = nil
        legalMoveSquares.removeAll()
    }
    
    public func updateLegalMoveHighlights(for square: BoardSquare) {
        guard highlightLegalMoves else {
            legalMoveSquares.removeAll()
            return
        }
        legalMoveSquares.removeAll()
        let index = square.row + square.column * self.rows
        guard game.position.board[index] != nil else { return }
        
        for move in game.legalMoves {
            if move.from.rank == square.row && move.from.file == square.column {
                let targetSquare = BoardSquare(row: move.to.rank, column: move.to.file)
                legalMoveSquares.insert(targetSquare)
            }
        }
    }
    
    public func clearLegalMoveHighlights() {
        legalMoveSquares.removeAll()
    }
    
    public func hint(_ square: BoardSquare) {
        hintedSquares.insert(square)
    }
    
    public func hint(_ square: String) {
        if square.count != 2 {
            return
        }
        
        let fileChar = square.first!
        let rankChar = square.last!
        
        let file = "abcdefgh".firstIndex(of: fileChar)?.utf16Offset(in: "abcdefgh")
        let rank = Int(String(rankChar))
        
        guard let file = file, let rank = rank else {
            return
        }
        
        let row = rank - 1
        let column = file
        
        hint(BoardSquare(row: row, column: column))
    }
    
    public func hint(row: Int, column: Int) {
        hint(BoardSquare(row: row, column: column))
    }
    
    public func hint(_ squares: [BoardSquare]) {
        for square in squares {
            hint(square)
        }
    }
    
    public func hint(_ squares: [String]) {
        for square in squares {
            hint(square)
        }
    }
    
    public func clearHint() {
        hintedSquares.removeAll()
    }
    
    @MainActor
    public func hint(_ square: String, for seconds: Double) {
        withAnimation {
            hint(square)
        }
        
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            
            withAnimation {
                self.clearHint()
            }
        }
    }
    
    @MainActor
    public func hint(_ squares: [String], for seconds: Double) {
        withAnimation {
            hint(squares)
        }
        
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            
            withAnimation {
                self.clearHint()
            }
        }
    }
    
    @MainActor
    public func hint(_ squares: [BoardSquare], for seconds: Double) {
        withAnimation {
            hint(squares)
        }
        
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            
            withAnimation {
                self.clearHint()
            }
        }
    }
    
    @MainActor
    public func hint(_ square: BoardSquare, for seconds: Double) {
        withAnimation {
            hint(square)
        }
        
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            
            withAnimation {
                self.clearHint()
            }
        }
    }
    
    public func presentPromotionPicker(piece: Piece, sourceSquare: String, targetSquare: String, lan: String) {
        promotionPiece = piece
        promotionSourceSquare = sourceSquare
        promotionTargetSquare = targetSquare
        promotionLan = lan
        
        withAnimation(.bouncy) {
            showPromotionPicker = true
        }
    }
    
    public func absentePromotionPicker() {
        promotionPiece = nil
        promotionSourceSquare = nil
        promotionTargetSquare = nil
        promotionLan = nil
        
        withAnimation(.bouncy) {
            showPromotionPicker = false
        }
    }
    
    public func togglePromotionPicker() {
        withAnimation(.bouncy) {
            showPromotionPicker.toggle()
        }
    }
    
    public func isPromotable(piece: Piece, lan: String) -> Bool {
        guard piece.kind == .pawn else { return false }
        guard lan.count >= 4 else { return false }
        
        let toSquare = lan.suffix(2)
        let rowChar = toSquare.last!
        
        guard let row = Int(String(rowChar)) else { return false }
        
        return row == (piece.color == .white ? self.rows : 1)
    }
    
    public func beginWaiting() {
        withAnimation(.bouncy) {
            inWaiting = true
        }
    }
    
    public func endWaiting() {
        withAnimation(.bouncy) {
            inWaiting = false
        }
    }
}

private struct MovingPieceView: View {
    var animation: Namespace.ID
    
    @Environment(ChessboardModel.self) var chessboardModel
    
    @State var position: CGPoint = .zero
    
    var body: some View {
        Group {
            if let movingPiece = chessboardModel.movingPiece {
                
                let sqWidth = chessboardModel.size / CGFloat(chessboardModel.columns)
                let sqHeight = chessboardModel.size / CGFloat(chessboardModel.rows)
                
                ChessPieceView(animation: animation,
                               piece: movingPiece.piece,
                               square: BoardSquare(row: movingPiece.from.row, column: movingPiece.from.column),
                               isMovingPiece: true)
                .position(position)
                .onAppear {
                    position = CGPoint(
                        x: (sqWidth / 2) + sqWidth * CGFloat(chessboardModel.shouldFlipBoard ? (chessboardModel.columns - 1) - movingPiece.from.column : movingPiece.from.column),
                        y: (sqHeight / 2) + sqHeight * CGFloat(chessboardModel.shouldFlipBoard ? movingPiece.from.row : (chessboardModel.rows - 1) - movingPiece.from.row)
                    )
                    
                    withAnimation(.easeInOut(duration: 0.5)) {
                        position = CGPoint(
                            x: (sqWidth / 2) + sqWidth * CGFloat(chessboardModel.shouldFlipBoard ? (chessboardModel.columns - 1) - movingPiece.to.column : movingPiece.to.column),
                            y: (sqHeight / 2) + sqHeight * CGFloat(chessboardModel.shouldFlipBoard ? movingPiece.to.row : (chessboardModel.rows - 1) - movingPiece.to.row)
                        )
                    } completion: {
                        chessboardModel.movingPiece = nil
                    }
                }
            }
        }
    }
}

public struct Chessboard: View {
    public var chessboardModel: ChessboardModel
    
    @Namespace private var animation
    
    public init(chessboardModel: ChessboardModel) {
        self.chessboardModel = chessboardModel
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundView
                squaresView
                labelsView
                piecesView
                legalMoveHighlightsView
                
                MovingPieceView(animation: animation)
                
                if chessboardModel.showPromotionPicker {
                    promotionPickerView
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
                
                if chessboardModel.inWaiting {
                    inWaitingView
                }
            }
            .environment(chessboardModel)
            .frame(width: chessboardSize(from: geometry.size),
                   height: chessboardSize(from: geometry.size))
            .onAppear {
                updateChessboardSize(geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                updateChessboardSize(newSize)
            }
            .task {
                updateChessboardSize(geometry.size)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private func chessboardSize(from geometrySize: CGSize) -> CGFloat {
        return min(geometrySize.width, geometrySize.height)
    }
    
    private func updateChessboardSize(_ geometrySize: CGSize) {
        let newSize = chessboardSize(from: geometrySize)
        chessboardModel.size = newSize
    }
    
    var inWaitingView: some View {
        ZStack {
            Color.clear.contentShape(Rectangle())
                .ignoresSafeArea()
        }
    }
    
    var promotionPickerView: some View {
        ZStack {
            
            let sqWidth = chessboardModel.size / CGFloat(chessboardModel.columns)
            let sqHeight = chessboardModel.size / CGFloat(chessboardModel.rows)
            
            let buttonSize = min(sqWidth, sqHeight) * 0.85
            let pickerSpacing = buttonSize * 0.15
            let pickerPadding = buttonSize * 0.25
            
            Color.white.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: pickerPadding) {
                Text("Promote Pawn")
                    .font(.system(size: buttonSize * 0.3, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                
                HStack(spacing: pickerSpacing) {
                    ForEach(["q", "r", "b", "n"], id: \.self) { (piece: String) in
                        Button {
                            handlePromotion(to: piece)
                        } label: {
                            ZStack {
                                let imageName = "\(chessboardModel.perspective == PieceColor.white ? "w" : "b")\(piece.uppercased())"
                                
                                // Piece Icon
                                AsyncImage(url: Bundle.module.url(forResource: imageName, withExtension: "png")) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: buttonSize * 0.8, height: buttonSize * 0.8)
                                    } else {
                                        ProgressView()
                                    }
                                }
                            }
                            .frame(width: buttonSize, height: buttonSize)
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(buttonSize * 0.2)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(pickerPadding)
            .background(.ultraThinMaterial)
            .cornerRadius(buttonSize * 0.4)
            .overlay(
                RoundedRectangle(cornerRadius: buttonSize * 0.4)
                    .stroke(.white.opacity(0.5), lineWidth: 1)
            )
            .shadow(radius: 20)
        }
    }
    
    private func handlePromotion(to piece: String) {
        guard let sourceSquare = chessboardModel.promotionSourceSquare,
              let targetSquare = chessboardModel.promotionTargetSquare,
              let lan = chessboardModel.promotionLan
        else {
            chessboardModel.absentePromotionPicker()
            return
        }
        
        let promotedLan = lan + piece.uppercased()
        let promotedMove = Move(string: promotedLan)
        let isLegal = chessboardModel.game.legalMoves.contains(promotedMove)
        
        chessboardModel.onMove(promotedMove, isLegal, sourceSquare, targetSquare, promotedLan, PieceKind(rawValue: piece))
        chessboardModel.absentePromotionPicker()
    }
    
    var backgroundView: some View {
        Color.clear
    }
    
    var labelsView: some View {
        ZStack {
            ForEach(0..<chessboardModel.rows, id: \.self) { row in
                rowLabelView(row: row)
            }
            ForEach(0..<chessboardModel.columns, id: \.self) { column in
                columnLabelView(column: column)
            }
        }
    }
    
    func rowLabelView(row: Int) -> some View {
        let displayRow = chessboardModel.shouldFlipBoard ? (chessboardModel.rows - 1 - row) : row
        let labelSize = chessboardModel.size / 32
        let sqWidth = chessboardModel.size / CGFloat(chessboardModel.columns)
        let sqHeight = chessboardModel.size / CGFloat(chessboardModel.rows)
        let padding = min(sqWidth, sqHeight) * 0.05
        
        return Text("\(displayRow + 1)")
            .font(.system(size: labelSize, weight: .bold))
            .foregroundColor(chessboardModel.colorScheme.label)
            .position(
                x: padding + (labelSize / 2) + 4,
                y: chessboardModel.size - (CGFloat(row) * sqHeight) - sqHeight + padding + (labelSize / 2) + 4
            )
    }
    
    func columnLabelView(column: Int) -> some View {
        let displayColumn = chessboardModel.shouldFlipBoard ? (chessboardModel.columns - 1 - column) : column
        let labelSize = chessboardModel.size / 32
        let sqWidth = chessboardModel.size / CGFloat(chessboardModel.columns)
        let sqHeight = chessboardModel.size / CGFloat(chessboardModel.rows)
        let padding = min(sqWidth, sqHeight) * 0.05
        let letters = Array("abcdefghijklmnopqrstuvwxyz")
        
        return Text(String(letters[displayColumn]))
            .font(.system(size: labelSize, weight: .bold))
            .foregroundColor(chessboardModel.colorScheme.label)
            .position(
                x: (CGFloat(column) * sqWidth) + sqWidth - padding - (labelSize / 2) - 4,
                y: chessboardModel.size - padding - (labelSize / 2) - 4
            )
    }
    
    var squaresView: some View {
        ZStack {
            let totalSquares = chessboardModel.rows * chessboardModel.columns
            let sqWidth = chessboardModel.size / CGFloat(chessboardModel.columns)
            let sqHeight = chessboardModel.size / CGFloat(chessboardModel.rows)
            
            ForEach(0..<totalSquares, id: \.self) { index in
                let row = index % chessboardModel.rows
                let column = index / chessboardModel.rows
                let piece = chessboardModel.game.position.board[index]
                
                ChessSquareView(piece: piece, row: row, column: column)
                    .position(
                        x: (sqWidth / 2) + sqWidth * CGFloat(chessboardModel.shouldFlipBoard ? (chessboardModel.columns - 1) - column : column),
                        
                        y: (sqHeight / 2) + sqHeight * CGFloat(chessboardModel.shouldFlipBoard ? row : (chessboardModel.rows - 1) - row)
                    )
            }
        }
    }
    
    var piecesView: some View {
        ZStack {
            let totalSquares = chessboardModel.rows * chessboardModel.columns
            let sqWidth = chessboardModel.size / CGFloat(chessboardModel.columns)
            let sqHeight = chessboardModel.size / CGFloat(chessboardModel.rows)
            
            ForEach(0..<totalSquares, id: \.self) { index in
                let row = index % chessboardModel.rows
                let column = index / chessboardModel.rows
                let piece = chessboardModel.game.position.board[index]
                
                let isMoving = chessboardModel.movingPiece?.from == BoardSquare(row: row, column: column) ||
                chessboardModel.movingPiece?.to == BoardSquare(row: row, column: column)
                
                ChessPieceView(animation: animation,
                               piece: piece,
                               square: BoardSquare(row: row, column: column))
                .opacity(isMoving ? 0.0 : 1.0)
                .animation(nil, value: isMoving)
                .position(
                    x: (sqWidth / 2) + sqWidth * CGFloat(chessboardModel.shouldFlipBoard ? (chessboardModel.columns - 1) - column : column),
                    y: (sqHeight / 2) + sqHeight * CGFloat(chessboardModel.shouldFlipBoard ? row : (chessboardModel.rows - 1) - row)
                )
            }
        }
    }
    
    var legalMoveHighlightsView: some View {
        ZStack {
            let sqWidth = chessboardModel.size / CGFloat(chessboardModel.columns)
            let sqHeight = chessboardModel.size / CGFloat(chessboardModel.rows)
            let highlightSize = min(sqWidth, sqHeight) / 3
            
            ForEach(Array(chessboardModel.legalMoveSquares), id: \.id) { square in
                Circle()
                    .fill(chessboardModel.colorScheme.legalMove)
                    .frame(width: highlightSize, height: highlightSize)
                    .position(
                        x: (sqWidth / 2) + sqWidth * CGFloat(chessboardModel.shouldFlipBoard ? (chessboardModel.columns - 1) - square.column : square.column),
                        y: (sqHeight / 2) + sqHeight * CGFloat(chessboardModel.shouldFlipBoard ? square.row : (chessboardModel.rows - 1) - square.row)
                    )
            }
        }
        .allowsHitTesting(false)
    }
    public func onMove(_ callback: @escaping (Move, Bool, String, String, String, PieceKind?) -> Void) -> Chessboard {
        chessboardModel.onMove = callback
        return self
    }
}

private struct ChessSquareView: View {
    @Environment(ChessboardModel.self) var chessboardModel
    
    var piece: Piece?
    var row: Int
    var column: Int
    
    @State var offset: CGSize = .zero
    @State var isDragging: Bool = false
    
    var zIndex: Double { isDragging ? 1: 0 }
    
    var isSelected: Bool {
        if let selectedSquare = chessboardModel.selectedSquare {
            return selectedSquare.row == row && selectedSquare.column == column
        }
        return false
    }
    
    var isHinted: Bool {
        chessboardModel.hintedSquares.contains { $0.row == row && $0.column == column }
    }
    
    var sqWidth: CGFloat { chessboardModel.size / CGFloat(chessboardModel.columns) }
    var sqHeight: CGFloat { chessboardModel.size / CGFloat(chessboardModel.rows) }
    
    var x: CGFloat {
        (sqWidth / 2) + sqWidth * CGFloat(chessboardModel.shouldFlipBoard ? (chessboardModel.columns - 1) - column : column)
    }
    
    var y: CGFloat {
        (sqHeight / 2) + sqHeight * CGFloat(chessboardModel.shouldFlipBoard ? row : (chessboardModel.rows - 1) - row)
    }
    
    var isLightSquare: Bool {
        return (row + column) % 2 != 0
    }
    
    var body: some View {
        ZStack {
            let imageName = isLightSquare ? "whiteBoard" : "blackBoard"
            AsyncImage(url: Bundle.module.url(forResource: imageName, withExtension: "png")){ phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                    
                } else {
                    if isLightSquare {
                        chessboardModel.colorScheme.light
                    }
                    else{
                        chessboardModel.colorScheme.dark
                    }
                }
                
            }
            .padding(min(sqWidth, sqHeight) * 0.05) // 5% multiplier padding
            Color.clear.contentShape(Rectangle())
        }
        
        .font(.system(size: min (sqWidth, sqHeight) * 0.75))
        .frame(width: sqWidth, height: sqHeight)
        .modifier {
            if let dropTarget = chessboardModel.dropTarget, !isDragging && dropTarget.row == row && dropTarget.column == column {
                $0.overlay{
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(chessboardModel.colorScheme.selected, lineWidth: 3.5)
                }
                
            }
            else if isSelected {
                $0.overlay{
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(chessboardModel.colorScheme.selected, lineWidth: 3.5)
                }
            }
            else if isHinted {
                $0.overlay{
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(chessboardModel.colorScheme.selected, lineWidth: 3.5)
                }
            }
            else {
                $0
            }
        }
        .padding(min(sqWidth, sqHeight) * 0.05) //adjust padding
        .frame(width: sqWidth, height: sqHeight)
    }
}
private struct ChessPieceView: View {
    @Environment(ChessboardModel.self) var chessboardModel
    
    var animation: Namespace.ID
    
    var piece: Piece?
    var square: BoardSquare
    var isMovingPiece = false
    
    @State var offset: CGSize = .zero
    @State var isDragging = false
    
    var zIndex: Double { isDragging ? 1: 0 }
    
    var isSelected: Bool {
        if let selectedSquare = chessboardModel.selectedSquare {
            return selectedSquare.row == square.row && selectedSquare.column == square.column
        }
        return false
    }
    
    var isHinted: Bool {
        chessboardModel.hintedSquares.contains { $0.row == square.row && $0.column == square.column }
    }
    
    var sqWidth: CGFloat { chessboardModel.size / CGFloat(chessboardModel.columns) }
    var sqHeight: CGFloat { chessboardModel.size / CGFloat(chessboardModel.rows) }
    
    var x: CGFloat {
        (sqWidth / 2) + sqWidth * CGFloat(chessboardModel.shouldFlipBoard ? (chessboardModel.columns - 1) - square.column : square.column)
    }
    
    var y: CGFloat {
        (sqHeight / 2) + sqHeight * CGFloat(chessboardModel.shouldFlipBoard ? square.row : (chessboardModel.rows - 1) - square.row)
    }
    
    var isMoving: Bool {
        piece == chessboardModel.movingPiece?.piece && square == chessboardModel.movingPiece?.from
    }
    
    var body: some View {
        ZStack {
            if let piece {
                let imageName = "\(piece.color == PieceColor.white ? "w" : "b")\(String(describing: piece).uppercased())"
                
                AsyncImage(url: Bundle.module.url(forResource: imageName, withExtension: "png")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(0.85)
                            .contentShape(Rectangle())
                    } else if phase.error != nil {
                        Text("\(piece)")
                            .foregroundStyle(piece.color == PieceColor.white ? Color.white : Color.black)
                            .font(.system(size: 18))
                            .scaledToFit()
                            .scaleEffect(0.85)
                            .contentShape(Rectangle())
                    } else {
                        ProgressView()
                            .scaleEffect(0.85)
                    }
                }
            } else {
                Color.clear.contentShape(Rectangle())
            }
        }
        .zIndex(zIndex)
        .padding(min(sqWidth, sqHeight) * 0.05) // adjust padding
        .font(.system(size: min(sqWidth, sqHeight) * 0.75))
        .frame(width: sqWidth, height: sqHeight)
        .offset(offset)
        .onTapGesture(perform: onTapGesture)
        .gesture(dragGesture)
    }
    
    func onTapGesture() {
        if chessboardModel.movingPiece != nil {
            return
        }
        
        if let piece, piece.color != chessboardModel.turn && chessboardModel.selectedSquare == nil {
            return
        }
        
        if isSelected {
            chessboardModel.selectedSquare = nil
            chessboardModel.clearLegalMoveHighlights()
        } else if piece != nil && chessboardModel.selectedSquare == nil {
            chessboardModel.selectedSquare = isSelected ? nil: BoardSquare(row: square.row, column: square.column)
            if chessboardModel.selectedSquare != nil {
                chessboardModel.updateLegalMoveHighlights(for: BoardSquare(row: square.row, column: square.column))
            }
        } else if let selectedSquare = chessboardModel.selectedSquare {
            let sourceRow = selectedSquare.row
            let sourceColumn = selectedSquare.column
            
            let sourceSquare = "\(Character(UnicodeScalar(sourceColumn + 97)!))\(sourceRow + 1)"
            let targetSquare = "\(Character(UnicodeScalar(square.column + 97)!))\(square.row + 1)"
            
            let lan = "\(sourceSquare)\(targetSquare)"
            let move = Move(string: lan)
            let isLegal = chessboardModel.game.legalMoves.contains(move)
            
            chessboardModel.deselect()
            chessboardModel.clearLegalMoveHighlights()
            
            // DYNAMIC UPDATE HERE: Swapped 8 for chessboardModel.rows
            guard let selectedPiece = chessboardModel.game.position.board[selectedSquare.row + selectedSquare.column * chessboardModel.rows]
            else { return }
            
            let isPromotable = chessboardModel.isPromotable(piece: selectedPiece, lan: lan)
            
            if !isPromotable {
                if !chessboardModel.validateMoves || isLegal {
                    chessboardModel.onMove(move, isLegal, sourceSquare, targetSquare, lan, nil)
                }
            } else if ((["q", "r", "b", "n"].map { lan + $0.uppercased() }).contains { promotedLan in
                return chessboardModel.game.legalMoves.contains(Move(string: promotedLan))
            }) {
                chessboardModel.presentPromotionPicker(piece: selectedPiece,
                                                       sourceSquare: sourceSquare,
                                                       targetSquare: targetSquare,
                                                       lan: lan)
            } else if !chessboardModel.validateMoves || isLegal {
                chessboardModel.onMove(move, isLegal, sourceSquare, targetSquare, lan, nil)
            }
        }
    }
    
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if chessboardModel.movingPiece != nil {
                    return
                }
                
                if chessboardModel.selectedSquare != nil {
                    chessboardModel.deselect()
                }
                
                if let piece, piece.color != chessboardModel.turn,
                   !chessboardModel.allowOpponentMove && piece.color != chessboardModel.perspective
                {
                    chessboardModel.selectedSquare = nil
                    isDragging = false
                    chessboardModel.clearLegalMoveHighlights()
                    return
                }
                
                chessboardModel.selectedSquare = nil
                
                if !isDragging {
                    chessboardModel.updateLegalMoveHighlights(for: BoardSquare(row: square.row, column: square.column))
                }
                
                isDragging = true
                let columnOffset = Int(round(value.translation.width / sqWidth))
                let rowOffset = Int(round(value.translation.height / sqHeight))
                
                let targetColumn = chessboardModel.shouldFlipBoard ? square.column - columnOffset : square.column + columnOffset
                let targetRow = chessboardModel.shouldFlipBoard ? square.row + rowOffset : square.row - rowOffset
                
                chessboardModel.dropTarget = (targetRow, targetColumn)
                offset = value.translation
            }
            .onEnded { value in
                chessboardModel.selectedSquare = nil
                chessboardModel.dropTarget = nil
                isDragging = false
                chessboardModel.clearLegalMoveHighlights()
                
                if let piece, piece.color != chessboardModel.turn,
                   !chessboardModel.allowOpponentMove && piece.color != chessboardModel.perspective {
                    withAnimation {
                        offset = .zero
                    }
                    return
                }
                
                let columnOffset = Int(round(value.translation.width / sqWidth))
                let rowOffset = Int(round(value.translation.height / sqHeight))
                
                let targetColumn = chessboardModel.shouldFlipBoard ? square.column - columnOffset : square.column + columnOffset
                let targetRow = chessboardModel.shouldFlipBoard ? square.row + rowOffset : square.row - rowOffset
                
                let sourceSquare = "\(Character(UnicodeScalar(square.column + 97)!))\(square.row + 1)"
                let targetSquare = "\(Character(UnicodeScalar(targetColumn + 97)!))\(targetRow + 1)"
                
                let lan = "\(sourceSquare)\(targetSquare)"
                let move = Move(string: lan)
                let isLegal = chessboardModel.game.legalMoves.contains(move)
                
                withAnimation {
                    offset = .zero
                }
                
                guard let selectedPiece = chessboardModel.game.position.board[square.row + square.column * chessboardModel.rows]
                else { return }
                
                let isPromotable = chessboardModel.isPromotable(piece: selectedPiece, lan: lan)
                
                if !isPromotable {
                    if !chessboardModel.validateMoves || isLegal {
                        chessboardModel.onMove(move, isLegal, sourceSquare, targetSquare, lan, nil)
                    }
                } else if ((["q", "r", "b", "n"].map { lan + $0.uppercased() }).contains { promotedLan in
                    return chessboardModel.game.legalMoves.contains(Move(string: promotedLan))
                }) {
                    chessboardModel.presentPromotionPicker(piece: selectedPiece,
                                                           sourceSquare: sourceSquare,
                                                           targetSquare: targetSquare,
                                                           lan: lan)
                } else if !chessboardModel.validateMoves || chessboardModel.game.legalMoves.contains(move) {
                    chessboardModel.onMove(move, isLegal, sourceSquare, targetSquare, lan, nil)
                }
            }
    }
}

public extension View {
    func modifier<ModifiedContent: View>(@ViewBuilder content: (_ content: Self) -> ModifiedContent) -> ModifiedContent {
        content(self)
    }
}
