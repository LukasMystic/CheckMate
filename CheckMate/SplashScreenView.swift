//
//  SplashScreenView.swift
//  CheckMate
//
//  Created by Gisella Jayata on 04/05/26.
//

import SwiftUI

struct SplashScreenView: View {
    
    @State var bgColor = Color("AccentColor")
    
    @State var ballYOffset: CGFloat = -500
    
    @State var ballXOffset: CGFloat = 0
    
    @State var logoOpacity: Double = 0
    
    var body: some View {
        
        ZStack {
            bgColor
                .ignoresSafeArea()
            
            Image("Chess Splash")
            
            Circle()
                .fill(Color("AccentColor"))
                .frame(width: 90, height: 90)
                .offset(x: ballXOffset, y: ballYOffset)
            
            Image("Check Mate Splash")
                .opacity(logoOpacity)

            
        }
        .onAppear {
            withAnimation(.smooth(duration: 1.0).delay(1.0)) {
                bgColor = .white
            }
            
            withAnimation(.interpolatingSpring(stiffness: 50, damping: 10).delay(1.5)) {
                ballYOffset = 0
            }
            
            withAnimation(.smooth().delay(3.0)
        ){
                ballXOffset = -84
            }
            
            withAnimation(.easeInOut(duration: 1.0).delay(3.2)){
                logoOpacity = 1.0
            }
        }
    }
}


#Preview {
    SplashScreenView()
}
