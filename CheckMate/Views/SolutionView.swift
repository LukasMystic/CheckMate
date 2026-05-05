//
//  SolutionView.swift
//  CheckMate
//
//  Created by Gisella Jayata on 04/05/26.
//

import SwiftUI

struct SolutionView: View {
    let backgroundGradient = Color("BackgroundColor")

    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack {
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
                }
                .padding(.bottom, 30)
                
                ZStack () {
                    ChessBoard()
                        .padding(.bottom, 20)
                    
                    ArrowAnalisis()
                        .rotationEffect(.degrees(335))
                        .offset(x: -15, y: 30)
                }
                
                VStack () {
                    HStack () {
                        Text("First Step:")
                            .font(.subheadline).bold()
                            .foregroundColor(.black)
                        Spacer()
                    }
                    HStack () {
                        Text("Analysis of the first step")
                            .font(.subheadline)
                            .foregroundColor(.black)
                        Spacer()
                    }
                }
                .padding(.leading, 24)
                .padding(.trailing, 14)
                .padding(.top, 15)
                .padding(.bottom, 16)
                .frame(maxWidth: 345)
                .background(RoundedRectangle(cornerRadius: 13)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 4)
                ).padding(.bottom, 50)
                
                DownButton()
            }
            .padding(16)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    SolutionView()
}
