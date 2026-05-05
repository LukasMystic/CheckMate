//
//  WinPopUpView.swift
//  CheckMate
//
//  Created by Vannya Ade Gunawan on 04/05/26.
//

import SwiftUI

struct WinPopUpView: View {
    var onSolutionTapped: () -> Void
    var onNextLevelTapped: () -> Void
    var hasGivenUp: Bool = false // change next button

    var body: some View {
        ZStack () {
            RoundedRectangle(cornerRadius: 13)
                .foregroundColor(.white)
                .frame(width: 304, height: 204)
                .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.arrow, lineWidth: 2)
                    )
            
            VStack (spacing: 10) {
                Image("Winning Face")
                    .frame(width: 267, height: 143)
                
                Text(hasGivenUp ? "LEVEL FAILED" : "YOU WIN")
                    .font(.custom("Inter28pt-Bold", size: 44)).bold()
                    .foregroundStyle(Color.arrow)
                
                HStack (spacing: 20) {
                    Button {
                        onSolutionTapped()
                    } label: {
                        Text("Solution")
                            .font(.custom("Inter18pt-SemiBold", size: 19))
                            .foregroundStyle(Color(.white))
                    }
                    .frame(width: 128, height: 51)
                    .background(RoundedRectangle(cornerRadius: 200)
                    .foregroundColor(Color.accent)
                    .shadow(color:Color.shadow, radius: 0, x: 0, y: 5))

                    Button {
                        onNextLevelTapped()
                    } label: {
                        // dynamic icon
                        Image(systemName: hasGivenUp ? "arrow.clockwise" : "arrow.forward")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 59, height: 59)
                    .glassEffect()
                    .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 4)
                }
            }
            .padding(.bottom, 130)
            
            HStack() {
                Image("WinningPiece")
                Spacer()
                Image("WinningPiece")
                    .scaleEffect(x: -1, y: 1)
            }
            .padding(.top, 140)
            .allowsHitTesting(false)
        }
        .padding(16)
    }
}

#Preview {
    WinPopUpView(onSolutionTapped: {}, onNextLevelTapped: {})
}
