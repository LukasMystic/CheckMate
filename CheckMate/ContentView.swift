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
    
    @AppStorage("highestUnlockedLevel") var highestUnlockedLevel: Int = 1
    
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
    
    
    
    init(levelId: Int = 1) {
        
        let level: PuzzleLevel
        let levelName = "Level\(levelId)"
        do{
            level = try PuzzleLevel.load(fromBundle: levelName)
        }
        catch{
            fatalError("Could not load Level1.json: \(error)")
        }
        
        
        Board.columns = level.columns
        Board.rows = level.rows
        
        _currentLevelId = State(initialValue: levelId)
        
        _currentLevel = State(initialValue: level)
        _currentNode = State(initialValue: level.rootNode)
        
        _feedbacktext = State(initialValue: level.objective)
        
        
        _chessboardModel = State(
            initialValue: ChessboardModel(fen: level.initialFEN, rows: level.rows, columns: level.columns)
        )
        _fenHistory = State(initialValue: [level.initialFEN])
    }
    
    var body: some View {
        ZStack {
            // MAIN CONTENT
            VStack{
                Text(moveEvaluation?.rawValue ?? " ")
                    .font(.title2).bold()
                    .foregroundColor((moveEvaluation == .brilliant || moveEvaluation == .best) ? .green : .red)
                    .opacity(moveEvaluation == nil ? 0 : 1)
                    .padding(.top)
                
                Text(feedbacktext)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .frame(height: 60)
                
                HStack {
                    if currentMode == .playing && mistakeCount >= 5{
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
                    // puzzle complete condition moved to Modal
                    else if currentMode == .analysis {
                        HStack(spacing:20){
                            Button("Restart"){
                                startAnalysis()
                            }
                            if analysisIndex > 0 {
                                Button("Previous Move"){
                                    previousAnalysisStep()
                                }
                            }
                        }
                        
                        Spacer()
                        
                        if analysisIndex >= analysisSteps.count{
                            if hasGivenUp {
                                Button ("Retry Level"){
                                    retryLevel()
                                }
                                .foregroundStyle(.orange)
                            } else {
                                Button("Next Level")
                                {
                                    loadLevel(currentLevelId + 1)
                                }
                            }
                        } else {
                            Button ("Next Move"){
                                nextAnalysisStep()
                            }
                        }
                    }
                }
                .frame(height: 50)
                .padding(.horizontal, 40)
                .padding(.bottom)
                
                Chessboard(chessboardModel: chessboardModel)
                    .onMove { move, isLegal, from, to, lan, promotionPiece in
                        if currentMode != .playing { return }
                        if !isLegal { return }
                        
                        chessboardModel.game.make(move: move)
                        let newFen = FenSerialization.default.serialize(position: chessboardModel.game.position)
                        
                        chessboardModel.setFen(newFen, lan: lan)
                        fenHistory.append(newFen)
                        
                        evaluateMove(lan: lan)
                    }
                    .disabled(currentMode != .playing)
                    // drawing arrow
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
            
            // card modal design
            if currentMode == .puzzleComplete {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                // Card View
                VStack(spacing: 20) {
                    Image(systemName: hasGivenUp ? "flag.fill" : "trophy.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(hasGivenUp ? .gray : .yellow)
                        .padding(.top, 10)
                    
                    Text(hasGivenUp ? "Level Solved" : "Puzzle Completed!")
                        .font(.title)
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)
                    
                    Text(feedbacktext.replacingOccurrences(of: "\nPuzzle Completed!", with: ""))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    HStack(spacing: 15) {
                        Button(action: {
                            startAnalysis()
                        }) {
                            Text("Analysis")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        
                        if hasGivenUp {
                            Button(action: {
                                retryLevel()
                            }) {
                                Text("Retry")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.orange)
                                    .cornerRadius(12)
                            }
                        } else {
                            Button(action: {
                                loadLevel(currentLevelId + 1)
                            }) {
                                Text("Next Level")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(25)
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(25)
                .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 10)
                .padding(.horizontal, 35)
                .transition(.scale(scale: 0.8).combined(with: .opacity)) // transition animation
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: currentMode)
    }
    
    private func evaluateMove(lan: String){
        currentArrows = []
        let targetSquare = String(lan.suffix(2)) // extract destination square
        if let outcome = currentNode.expectedMoves[lan]{
            moveEvaluation = outcome.evaluation
            feedbacktext = outcome.feedback
            
            if outcome.evaluation == .brilliant || outcome.evaluation == .best {
                chessboardModel.clearEvaluation()
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
                            currentNode = next
                            feedbacktext = "Find the next best move"
                        }
                        else {
                            // Puzzle Finished!
                            currentMode = .puzzleComplete
                            feedbacktext = "Puzzle Completed!"
                            if currentLevelId >= highestUnlockedLevel {
                                highestUnlockedLevel = currentLevelId + 1
                            }
                        }
                        moveEvaluation = nil
                        
                        
                    }
                    
                }
                else {
                    currentMode = .puzzleComplete
                    feedbacktext = outcome.feedback + "\nPuzzle Completed!"
                    if currentLevelId >= highestUnlockedLevel {
                        highestUnlockedLevel = currentLevelId + 1
                    }
                }
                
            }
            else {
                mistakeCount += 1
                if outcome.evaluation == .blunder {
                    chessboardModel.setEvaluation(.blunder, for: targetSquare)
                } else {
                    chessboardModel.setEvaluation(.mistake, for: targetSquare)
                }
                
                if let replyString = outcome.cpuReplyLAN{
                    currentArrows = replyString.components(separatedBy: ",")
                }
                feedbacktext += "\nTap on the board to undo"
            }
            
        }
        else {
            mistakeCount += 1
            moveEvaluation = .mistake
            chessboardModel.setEvaluation(.mistake, for: targetSquare)
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
        currentArrows = []
        feedbacktext = currentLevel.objective
        chessboardModel.clearEvaluation()
        
    }
    
    private func loadLevel(_ id: Int){
        let levelName = "Level\(id)"
        do {
            let nextLevel = try PuzzleLevel.load(fromBundle: levelName)
            
            // adjust board
            Board.columns = nextLevel.columns
            Board.rows = nextLevel.rows
            
            // update state
            currentLevelId = id
            currentLevel = nextLevel
            feedbacktext = currentLevel.objective
            currentNode = nextLevel.rootNode
            
            chessboardModel = ChessboardModel(fen: nextLevel.initialFEN, rows: nextLevel.rows, columns: nextLevel.columns)
            fenHistory = [nextLevel.initialFEN]
            
            // reset everything :)
            moveEvaluation = nil
            currentArrows = []
            mistakeCount = 0
            hasGivenUp = false
            currentMode = .playing
            
            
            
        } catch {
            feedbacktext = "Congratulations! You've found a bug!"
        }
    }
    
    // retry level
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
    
    // post analysis
    
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
            feedbacktext += "Analysis Complete"
        }
    }
    
    // undo button for analysis
    private func previousAnalysisStep() {
        guard analysisIndex > 0 else { return }
        
        analysisIndex -= 1
        
        // reset board
        chessboardModel.game = Game(position: FenSerialization.default.deserialize(fen: currentLevel.initialFEN))
        chessboardModel.setFen(currentLevel.initialFEN)
        
        if analysisIndex == 0{
            moveEvaluation = nil
            feedbacktext = "Analysis Mode: Tap 'Next move' "
            currentArrows = []
            
        } else {
            // reapply moves
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
            
            let distance = hypot(endPoint.x - startPoint.x, endPoint.y - startPoint.y)
            let midX = (startPoint.x + endPoint.x) / 2
            let midY = (startPoint.y + endPoint.y) / 2
            
            let angle = atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
            
            Image("ArrowAnalysis")
                .resizable()
                .frame(width: sqWidth * 0.4, height: distance)
                .rotationEffect(.radians(Double(angle) + .pi / 2))
                .position(x: midX, y: midY)
                .opacity(0.8)
        }
    }
    
    /// Converts a square coordinate like "b2" into a graphical CGPoint
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
