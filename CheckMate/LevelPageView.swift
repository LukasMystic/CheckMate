//
//  LevelPageVIew.swift
//  CheckMate
//
//  Created by Stanley Pratama Teguh on 04/05/26.
//

import SwiftUI

struct LevelPageView: View {
    @AppStorage("highestUnlockedLevel") var highestUnlockedLevel: Int = 1
    
    let totalLevels = 5
    
    var body: some View {
        NavigationStack {
            List(1...totalLevels, id: \.self) { levelId in
                if levelId <= highestUnlockedLevel {
                    NavigationLink(destination: ContentView(levelId: levelId)) {
                        HStack {
                            Image(systemName: "puzzlepiece.fill")
                                .foregroundColor(.blue)
                            
                            Text("Level \(levelId)")
                                .font(.headline)
                        }
                        .padding(.vertical, 8)
                    }
                } else {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                        
                        Text("Level \(levelId)")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Select Level")
        }
    }
}

#Preview {
    LevelPageView()
}
