//
//  GamesPage.swift
//  Check Mate
//
//  Created by Vannya Ade Gunawan on 04/05/26.
//

import SwiftUI

struct GameView: View {
    @State private var scale = 0.5
    let backgroundGradient = Color("BackgroundColor")
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack {
                
                //title bar
                ZStack {
                    VStack(spacing: 0) {
                        Text("Level 1")
                            .font(.custom("Inter18pt-Regular", size: 20))
                            .foregroundStyle(Color("FontColor"))
                        Text("Objective")
                            .font(.custom("Inter28pt-Bold", size: 28))
                            .foregroundStyle(Color("FontColor"))
                    }
                    
                    HStack {
                        Button {
                            print("Map Button Tapped")
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
                
                //livefeedbackarea
                ZStack {
                    Text("Life Feedback and everything else that you talk you know")
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
                    
                    FaceView(face: .best)
                        .frame(width: 100, height: 100)
                        .offset(x: -130)
                }
                .padding(.bottom, 10)
                
                //chessboard
                ZStack {
                    ChessBoard()
                }
                .padding(.bottom, 15)
                
                //undo and solution
                VStack {
                    SolutionButton()
                        .animation(.easeIn(duration: 0.3).repeatCount(1, autoreverses: true), value: scale)
                                    .onAppear {
                                        scale = 1
                                    }

                }
                .padding(.bottom, 20)
                
                VStack {
                    Button {
                        print("Undo Button Tapped")
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.title)
                            .foregroundColor(.black)
                    }
                    .frame(width: 59, height: 59)
                    .glassEffect()
                }
                .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 4)
            }
            .padding(16)
        }
        .ignoresSafeArea()
        .overlay {
            if Level1.status == true {
                ZStack {
                    Color.background.opacity(0.72)
                        .ignoresSafeArea()
                    WinPopUpView()
                        .scaleEffect(scale)
                        .animation(.easeIn(duration: 0.3).repeatCount(1, autoreverses: true), value: scale)
                                    .onAppear {
                                        scale = 1
                                    }
                }
            }
        }
    }
}

#Preview {
    GameView()
}

