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
    @Environment(\.dismiss) var dismiss
    
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
    
    @State private var popupScale: CGFloat = 0.5
    let backgroundGradient = Color("BackgroundColor")
    let initialLevelId: Int
    
    @State private var needsResetOnAppear = false
    
    init(levelId: Int = 1) {
        self.initialLevelId = levelId
        let level: PuzzleLevel
        let levelName = "Level\(levelId)"
        do {
            level = try PuzzleLevel.load(fromBundle: levelName)
        } catch {
            print("Could not load \(levelName).json. Falling back to Level 1.")
            level = try! PuzzleLevel.load(fromBundle: "Level1")
        }
        
        Board.columns = level.columns
        Board.rows = level.rows
        
        _currentLevelId = State(initialValue: levelId)
        _currentLevel = State(initialValue: level)
        _currentNode = State(initialValue: level.rootNode)
        
        // placeholder
        _feedbacktext = State(initialValue: "Your turn!")
        
        _chessboardModel = State(
            initialValue: ChessboardModel(fen: level.initialFEN, rows: level.rows, columns: level.columns)
        )
        _fenHistory = State(initialValue: [level.initialFEN])
    }
    
    var body: some View {
        ZStack {
            if currentMode != .analysis {
                ZStack {
                    backgroundGradient
                    
                    VStack {
                        // title bar
                        ZStack {
                            VStack(spacing: 0) {
                                Text("Level \(currentLevelId)")
                                    .font(.custom("Inter18pt-Regular", size: 20))
                                    .foregroundStyle(Color("FontColor"))
                                
                                Text(currentLevel.objective)
                                    .font(.custom("Inter28pt-Bold", size: 28))
                                    .foregroundStyle(Color("FontColor"))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 90)
                            .multilineTextAlignment(.center)
                            HStack {
                                Button {
                                    needsResetOnAppear = true
                                    dismiss() // map button
                                } label: {
                                    Image(systemName: "map")
                                        .font(.title2)
                                }
                                .buttonStyle(.plain)
                                .frame(width: 59, height: 59)
                                .glassEffect()
                                .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 4)
                                
                                Spacer()
                                
                                SoundButton()
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 40)
                        
                        // livefeedbackarea
                        ZStack {
                            Text(feedbacktext)
                                .font(.subheadline)
                                .padding(.vertical, 10)
                                .padding(.trailing, 10)
                                .padding(.leading, 50)
                                .frame(maxWidth: 300)
                                .background(
                                    RoundedRectangle(cornerRadius: 13)
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 4)
                                )
                                .offset(x: 20)
                            
                            FaceView(face: mapEvaluationToFaceState(evaluation: moveEvaluation))
                                .frame(width: 100, height: 100)
                                .offset(x: -130)
                        }
                        .padding(.bottom, 10)
                        
                        // chessboard
                        ZStack {
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
                                .frame(width: 350, height: 350)
                                .id(currentLevelId)
                        }
                        .padding(.bottom, 15)
                        
                        // undo and solution buttons
                        HStack(spacing: 20) {
                            Button {
                                undo()
                            } label: {
                                Image(systemName: "arrow.uturn.backward")
                                    .font(.title)
                                    .foregroundColor(.black)
                            }
                            .frame(width: 59, height: 59)
                            .glassEffect()
                            .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 4)
                            
                            Button {
                                hasGivenUp = true
                                startAnalysis()
                            } label: {
                                SolutionButton()
                                    .animation(.easeIn(duration: 0.3).repeatCount(1, autoreverses: true), value: popupScale)
                            }
                            .disabled(mistakeCount < 5)
                            .opacity(mistakeCount < 5 ? 0.5 : 1.0)
                        }
                        .padding(.bottom, 20)
                        .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 4)
                    }
                    .padding(16)
                }
                .ignoresSafeArea()
                .navigationBarBackButtonHidden()
                
            } else {
                SolutionView(
                    stepTitle: getEvaluationTitle(evaluation: moveEvaluation, index: analysisIndex),
                    stepFeedback: feedbacktext,
                    isAnalysisComplete: analysisIndex >= analysisSteps.count,
                    hasGivenUp: hasGivenUp,
                    onMapTapped: {
                        needsResetOnAppear = true
                        dismiss()
                    },
                    onNextTapped: { nextAnalysisStep() },
                    onPrevTapped: { previousAnalysisStep() },
                    chessboardModel: chessboardModel,
                    currentArrows: currentArrows
                )
                .transition(.opacity)
            }
        }
        // winning card overlay
        .overlay (alignment: .center) {
            if currentMode == .puzzleComplete {
                ZStack {
                    Color.black.opacity(0.72)
                        .ignoresSafeArea()
                    
                    // Insert your custom popup here!
                    WinPopUpView(
                        onSolutionTapped: {
                            startAnalysis()
                        },
                        onNextLevelTapped: {
                            if hasGivenUp {
                                retryLevel()
                            } else {
                                if currentLevelId >= 5 {
                                    needsResetOnAppear = true
                                    dismiss()
                                } else {
                                    if currentLevelId >= 5 {
                                        needsResetOnAppear = true
                                        dismiss()
                                    } else {
                                        needsResetOnAppear = true
                                        loadLevel(currentLevelId + 1)
                                    }
                                }
                            }
                        },
                        hasGivenUp: hasGivenUp
                    )
                    .scaleEffect(popupScale)
                    .animation(.easeIn(duration: 0.3), value: popupScale)
                    .onAppear {
                        popupScale = 1
                    }
                }
            }
        }
        
        .onAppear {
            retryLevel()
        }
    }
    
    private func mapEvaluationToFaceState(evaluation: MoveEvaluation?) -> FaceState {
        switch evaluation {
        case .brilliant: return .brilliant
        case .best: return .best
        case .mistake, .blunder: return .blunder
        default: return .best
        }
    }
    
    private func getEvaluationTitle(evaluation: MoveEvaluation?, index: Int) -> String {
        if index == 0 { return "Starting Position:" }
        guard let evaluation = evaluation else { return "Opponent's Move:" }
        
        switch evaluation {
        case .brilliant: return "Brilliant:"
        case .best: return "Best Move:"
        case .mistake: return "Mistake:"
        case .blunder: return "Blunder:"
        default: return "Move:"
        }
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
                        } else {
                            // Puzzle Finished!
                            currentMode = .puzzleComplete
                            feedbacktext = "Puzzle Completed!"
                            if currentLevelId >= highestUnlockedLevel {
                                
                                highestUnlockedLevel = min(currentLevelId + 1, 5)
                            }
                        }
                        moveEvaluation = nil
                    }
                    
                } else {
                    currentMode = .puzzleComplete
                    feedbacktext = outcome.feedback + "\nPuzzle Completed!"
                    if currentLevelId >= highestUnlockedLevel {
                        highestUnlockedLevel = currentLevelId + 1
                    }
                }
                
            } else {
                mistakeCount += 1
                triggerErrorHaptic()
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
            
        } else {
            mistakeCount += 1
            triggerErrorHaptic()
            moveEvaluation = .mistake
            chessboardModel.setEvaluation(.mistake, for: targetSquare)
            feedbacktext = "That's not the best move. Try again"
        }
    }
    
    private func undo() {
        guard let startFEN = fenHistory.first else {return}
        let playerColor = FenSerialization.default.deserialize(fen: startFEN).state.turn
        let currentFEN = chessboardModel.turn
        let moves = (currentFEN == playerColor) ? 2 : 1
        guard fenHistory.count > moves else {return} // just in case
        
        fenHistory.removeLast(moves)
        
        if let previousFEN = fenHistory.last {
            chessboardModel.setFen(previousFEN)
        }
        moveEvaluation =  nil
        currentArrows = []
        feedbacktext = "Your turn!"
        chessboardModel.clearEvaluation()
    }
    
    private func loadLevel(_ id: Int){
        let levelName = "Level\(id)"
        do {
            let nextLevel = try PuzzleLevel.load(fromBundle: levelName)
            Board.columns = nextLevel.columns
            Board.rows = nextLevel.rows
            currentLevelId = id
            currentLevel = nextLevel
            feedbacktext = "Your turn!"
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
        
        chessboardModel.clearEvaluation()
        fenHistory = [currentLevel.initialFEN]
        currentNode = currentLevel.rootNode
        
        moveEvaluation = nil
        currentArrows = []
        feedbacktext = "Your turn!"
        
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
        chessboardModel.clearEvaluation()
        moveEvaluation = nil
        feedbacktext = "Analysis Mode: Step through the solution."
        currentArrows = []
    }
    
    private func nextAnalysisStep() {
        guard analysisIndex < analysisSteps.count else {
            if hasGivenUp {
                retryLevel()
            } else {
                if currentLevelId >= 5 {
                    needsResetOnAppear = true
                    dismiss()
                } else {
                    needsResetOnAppear = true
                    loadLevel(currentLevelId + 1)
                }
            }
            return
        }
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
        
        if analysisIndex == 0{
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
    private func triggerErrorHaptic() {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
}

#Preview {
    ContentView()
}

// MARK: - Arrow Drawing Views

