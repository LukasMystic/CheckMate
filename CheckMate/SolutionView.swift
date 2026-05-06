//
//  SolutionView.swift
//  CheckMate
//
//  Created by Gisella Jayata on 04/05/26.
//

import ChessKit
import ChessboardKit
import SwiftUI

struct SolutionView: View {
    let backgroundGradient = Color("BackgroundColor")
    
    // placeholder for text
    var stepTitle: String = "First Step:"
    var stepFeedback: String = "Analysis of the first step"
    
    var isAnalysisComplete: Bool = false
    var hasGivenUp: Bool = false
    
    //button
    var onMapTapped: () -> Void = {}
    var onNextTapped: () -> Void = {}
    var onPrevTapped: () -> Void = {}
    
    var chessboardModel: ChessboardModel
    var currentArrows: [String] = []
    
    var body: some View {
        
        ZStack {
            backgroundGradient
            
            VStack {
                // Top Bar
                HStack {
                    Button {
                        onMapTapped()
                    } label: {
                        Image(systemName: "map")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 59, height: 59)
                    .glassEffect()
                    .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 4)
                    
                    Spacer()
                }
                .padding(.bottom, 30)
                
                ZStack {
                    Chessboard(chessboardModel: chessboardModel)
                        .disabled(true)
                        .overlay {
                            ForEach(currentArrows, id: \.self) { arrowLAN in
                                ArrowOverlay(lan: arrowLAN.trimmingCharacters(in: .whitespaces),
                                             columns: chessboardModel.columns,
                                             rows: chessboardModel.rows,
                                             shouldFlip: chessboardModel.shouldFlipBoard)
                                .allowsHitTesting(false)
                                .transition(.opacity)
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: currentArrows)
                        .frame(width: 344, height: 344)
                        .padding(.bottom, 20)
                }

                VStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(stepTitle)
                            .font(.subheadline).bold()
                            .foregroundColor(.black)
                        
                        Text(stepFeedback)
                            .font(.subheadline)
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: 345, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 13)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                    )
                    .animation(.easeInOut(duration: 0.25), value: stepFeedback)
                    
                    Spacer(minLength: 0)
                }
                .frame(height: 100)
                .padding(.bottom, 30)
                .padding(.leading, 24)
                .padding(.trailing, 14)
                .padding(.top, 15)
                .padding(.bottom, 16)
                .frame(maxWidth: 345, minHeight: 110)
                
                .padding(.bottom, 50)
                .animation(.easeInOut(duration: 0.25), value: stepFeedback)
                .animation(.easeInOut(duration: 0.25), value: stepTitle)
                // left and rightarrow
                HStack(spacing: 20) {
                    Button(action: onPrevTapped) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .frame(width: 59, height: 59)
                            .glassEffect()
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onNextTapped) {
                        if isAnalysisComplete {
                            Text(hasGivenUp ? "Retry" : "Next Level")
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .frame(width: 120, height: 59)
                                .glassEffect()
                        } else {
                            Image(systemName: "arrow.right")
                                .font(.title2)
                                .frame(width: 59, height: 59)
                                .glassEffect()
                        }
                    }
                    .buttonStyle(.plain)
                }
                .animation(.spring(), value: isAnalysisComplete)
            }
            .padding(16)
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden()
        
    }
}

#Preview {
    // placeholder
    SolutionView(
        stepTitle: "Black's Response:",
        stepFeedback: "The opponent's forced response.",
        chessboardModel: ChessboardModel(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", rows: 8, columns: 8)
    )
}
