//
//  CheckMateApp.swift
//  CheckMate
//
//  Created by Alessandro Moreno Lawadinata on 27/04/26.
//

import SwiftUI

@main
struct CheckMateApp: App {
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .onAppear {
                            // 4.5 second of animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                                // swap view
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    showSplash = false
                                }
                            }
                        }
                } else {
                    LevelPageView()
                        .transition(.opacity) 
                }
            }
            .preferredColorScheme(.light)
        }
    }
}
