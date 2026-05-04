//
//  ContentView.swift
//  CheckMate
//
//  Created by Alessandro Moreno Lawadinata on 27/04/26.
//

import SwiftUI
import ChessboardKit
import ChessKit

enum PuzzleMode {
    case playing
    case analysis
    case puzzleComplete
}

struct AnalysisStep {
    let moveLAN: String
    let evaluation: MoveEvaluation?
    let feedback: String
    let isPlayerMove: Bool
}

struct ContentView: View {
    @State var chessboardModel: ChessboardModel
    @State var fenHistory: [String]
    
    // for puzzle
    @State var currentLevel: PuzzleLevel
    @State var currentNode: PuzzleNode
    @State var feedbacktext: String = "Find the best move for white"
    @State var moveEvaluation: MoveEvaluation? = nil
    
    // for tracker & analysis
    @State var currentMode: PuzzleMode = .playing
    @State var analysisSteps: [AnalysisStep] = []
    @State var analysisIndex: Int = 0
    
    // for arrows
    @State var currentArrows: [String] = []
    @State var mistakeCount: Int = 0
    @State var hasGivenUp: Bool = false
    
    @State var currentLevelId: Int = 1
    
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
        _currentNode = State(initialValue: level.rootNode)
        
        _feedbacktext = State(initialValue: level.objective)
        
        _chessboardModel = State(
            initialValue: ChessboardModel(fen: level.initialFEN, rows: level.rows, columns: level.columns)
        )
        _fenHistory = State(initialValue: [level.initialFEN])
    }
    
    var body: some View {
        VStack {
            
            if let eval = moveEvaluation {
                Text(eval.rawValue)
                    .font(.title2).bold()
                    .foregroundColor(eval == .brilliant || eval == .best ? .green : .red)
            }
            Text(feedbacktext).padding()
            
            HStack {
                if currentMode == .playing && mistakeCount >= 5 {
                    Button (action: {
                        hasGivenUp = true
                        startAnalysis()
                    }) {
                        Text("Give up / Solution")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                }
                else if currentMode == .puzzleComplete {
                    Button ("Start Analysis") {
                        startAnalysis()
                    }
                    Spacer()
                    
                    if hasGivenUp {
                        Button("Retry Level") {
                            retryLevel()
                        }
                        .foregroundStyle(.orange)
                    } else {
                        if currentLevelId < 5 {
                            Button("Next Level") {
                                loadLevel(currentLevelId + 1)
                            }
                        } else {
                            Text("🎉 You beat all puzzles!")
                                .foregroundColor(.green)
                                .bold()
                        }
                    }
                }
                else if currentMode == .analysis {
                    HStack(spacing:20) {
                        Button("Restart") {
                            startAnalysis()
                        }
                        if analysisIndex > 0 {
                            Button("Previous Move") {
                                previousAnalysisStep()
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if analysisIndex >= analysisSteps.count {
                        if hasGivenUp {
                            Button ("Retry Level") {
                                retryLevel()
                            }
                            .foregroundStyle(.orange)
                        } else {
                            if currentLevelId < 5 {
                                Button("Next Level") {
                                    loadLevel(currentLevelId + 1)
                                }
                            } else {
                                Text("🎉 You beat all puzzles!")
                                    .foregroundColor(.green)
                                    .bold()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom)
            
            Chessboard(chessboardModel: chessboardModel)
                .onMove { move, isLegal, from, to, lan, promotionPiece in
                    if currentMode != .playing {
                        return
                    }
                    if !isLegal { return }
                    
                    chessboardModel.game.make(move: move)
                    let newFen = FenSerialization.default.serialize(position: chessboardModel.game.position)
                    
                    chessboardModel.setFen(newFen, lan: lan)
                    fenHistory.append(newFen)
                    
                    evaluateMove(lan: lan)
                }
                .overlay {
                    if (currentMode == .playing && (moveEvaluation == .blunder || moveEvaluation == .mistake)) || currentMode == .analysis {
                        ForEach(currentArrows, id: \.self) { arrowLAN in
                            ArrowOverlay(lan: arrowLAN.trimmingCharacters(in: .whitespaces), columns: chessboardModel.columns, rows: chessboardModel.rows, shouldFlip: chessboardModel.shouldFlipBoard)
                                .allowsHitTesting(false)
                        }
                        
                        if currentMode == .playing {
                            Color.white.opacity(0.001)
                                .onTapGesture {
                                    undo()
                                }
                        }
                    }
                }
                .frame(width: 400, height: 400)
                .id(currentLevelId)
            
        }
    }
    
    private func evaluateMove(lan: String){
        currentArrows = []
        if let outcome = currentNode.expectedMoves[lan] {
            moveEvaluation = outcome.evaluation
            feedbacktext = outcome.feedback
            
            if outcome.evaluation == .brilliant || outcome.evaluation == .best {
                if let cpuLANString = outcome.cpuReplyLAN {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        // make cpu move from JSON
                        let cpuLAN = cpuLANString.components(separatedBy: ",").first ?? cpuLANString
                        
                        let cpuMove = Move(string: cpuLAN)
                        chessboardModel.game.make(move: cpuMove)
                        let nextFEN = FenSerialization.default.serialize(position: chessboardModel.game.position)
                        chessboardModel.setFen(nextFEN, lan: cpuLAN)
                        fenHistory.append(nextFEN)
                        
                        if let next = outcome.nextNode {
                            currentNode = next
                            feedbacktext = "Find the next best move"
                        }
                        else {
                            // Puzzle Finished!
                            currentMode = .puzzleComplete
                            feedbacktext = "Puzzle Completed!"
                        }
                        moveEvaluation = nil
                    }
                }
                else {
                    currentMode = .puzzleComplete
                    feedbacktext = outcome.feedback + "\nPuzzle Completed!"
                }
            }
            else {
                mistakeCount += 1
                if let replyString = outcome.cpuReplyLAN{
                    currentArrows = replyString.components(separatedBy: ",")
                }
                feedbacktext += "\nTap on the board to undo"
            }
        }
        else {
            mistakeCount += 1
            moveEvaluation = .mistake
            feedbacktext = "That's not the best move. Try again"
        }
    }

    private func undo() {
        guard let startFEN = fenHistory.first else {return}
        
        let playerColor = FenSerialization.default.deserialize(fen: startFEN).state.turn
        let currentFEN = chessboardModel.turn
        
        let moves = (currentFEN == playerColor) ? 2 : 1
        guard fenHistory.count > moves else {return}
        
        fenHistory.removeLast(moves)
        
        if let previousFEN = fenHistory.last {
            chessboardModel.setFen(previousFEN)
        }
        moveEvaluation =  nil
        currentArrows = []
        feedbacktext = currentLevel.objective
    }
    
    private func loadLevel(_ id: Int){
        let levelName = "Level\(id)"
        do {
            let nextLevel = try PuzzleLevel.load(fromBundle: levelName)
            
            Board.columns = nextLevel.columns
            Board.rows = nextLevel.rows
            
            currentLevelId = id
            currentLevel = nextLevel
            feedbacktext = currentLevel.objective
            currentNode = nextLevel.rootNode
            
            chessboardModel = ChessboardModel(fen: nextLevel.initialFEN, rows: nextLevel.rows, columns: nextLevel.columns)
            fenHistory = [nextLevel.initialFEN]
            
            moveEvaluation = nil
            currentArrows = []
            mistakeCount = 0
            hasGivenUp = false
            currentMode = .playing
            
        } catch {
            feedbacktext = "Congratulations! You've found a bug!"
        }
    }
    
    private func retryLevel() {
        chessboardModel.game = Game(position: FenSerialization.default.deserialize(fen: currentLevel.initialFEN))
        chessboardModel.setFen(currentLevel.initialFEN)
        
        fenHistory = [currentLevel.initialFEN]
        currentNode = currentLevel.rootNode
        
        moveEvaluation = nil
        currentArrows = []
        feedbacktext = currentLevel.objective
        
        mistakeCount = 0
        hasGivenUp = false
        currentMode = .playing
    }
    
    private func extractGoldenPath(from node: PuzzleNode) -> [AnalysisStep] {
        var steps: [AnalysisStep] = []
        
        if let correctMove = node.expectedMoves.first(where: {
            $1.evaluation == .brilliant || $1.evaluation == .best
        }) {
            steps.append(AnalysisStep(moveLAN: correctMove.key, evaluation: correctMove.value.evaluation, feedback: correctMove.value.feedback, isPlayerMove: true))
            
            if let cpuLAN = correctMove.value.cpuReplyLAN {
                let firstCPULAN = cpuLAN.components(separatedBy: ",").first ?? cpuLAN
                steps.append(AnalysisStep(moveLAN: firstCPULAN, evaluation: nil, feedback: "The opponent's forced response.", isPlayerMove: false))
            }
            if let nextNode = correctMove.value.nextNode {
                steps.append(contentsOf: extractGoldenPath(from: nextNode))
            }
        }
        
        return steps
    }
    
    private func startAnalysis() {
        currentMode = .analysis
        analysisSteps = extractGoldenPath(from: currentLevel.rootNode)
        analysisIndex = 0
        
        chessboardModel.setFen(currentLevel.initialFEN)
        moveEvaluation = nil
        feedbacktext = "Analysis Mode: Step through the solution."
        currentArrows = []
    }
    
    private func nextAnalysisStep() {
        guard analysisIndex < analysisSteps.count else { return }
        let step = analysisSteps[analysisIndex]
        let move = Move(string: step.moveLAN)
        chessboardModel.game.make(move: move)
        let newFen = FenSerialization.default.serialize(position: chessboardModel.game.position)
        chessboardModel.setFen(newFen, lan: step.moveLAN)
        
        currentArrows = [step.moveLAN]
        moveEvaluation = step.evaluation
        feedbacktext = step.feedback
        analysisIndex += 1
        
        if analysisIndex >= analysisSteps.count {
            feedbacktext += "\nAnalysis Complete"
        }
    }
    
    private func previousAnalysisStep() {
        guard analysisIndex > 0 else { return }
        
        analysisIndex -= 1
        
        chessboardModel.game = Game(position: FenSerialization.default.deserialize(fen: currentLevel.initialFEN))
        chessboardModel.setFen(currentLevel.initialFEN)
        
        if analysisIndex == 0 {
            moveEvaluation = nil
            feedbacktext = "Analysis Mode: Tap 'Next move' "
            currentArrows = []
        } else {
            for i in 0..<analysisIndex {
                let step = analysisSteps[i]
                chessboardModel.game.make(move: Move(string: step.moveLAN))
                let newFen = FenSerialization.default.serialize(position: chessboardModel.game.position)
                chessboardModel.setFen(newFen, lan: step.moveLAN)
            }
            let currentStep = analysisSteps[analysisIndex - 1]
            currentArrows = [currentStep.moveLAN]
            moveEvaluation = currentStep.evaluation
            feedbacktext = currentStep.feedback
        }
    }
}

#Preview {
    ContentView()
}

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
    
    func point(for square: String, sqWidth: CGFloat, sqHeight: CGFloat) -> CGPoint {
        guard square.count >= 2 else { return .zero }
        
        let fileChar = square.first!
        let rankChar = square.last!
        
        let file = Int(fileChar.asciiValue! - Character("a").asciiValue!)
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
