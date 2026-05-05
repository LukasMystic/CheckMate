//
//  LevelPageVIew.swift
//  CheckMate
//
//  Created by Stanley Pratama Teguh on 04/05/26.
//

import SwiftUI
enum LevelState {
    case passed, current, locked
    
    var iconImage: String {
        switch self {
        case .passed: return "Level Done"
        case .current: return "Level Current"
        case .locked: return "Level Lock"
        }
    }
    
    var lineImage: String {
        switch self {
        case .passed: return "Line Done"
        case .current: return "Line Lock"
        case .locked: return "Line Lock"
        }
    }
}

struct LevelPath: View {
    let levelNumber: Int
    let state: LevelState
    let isLast: Bool
    
    var body: some View {
        HStack {
            if levelNumber % 2 == 0 {
                Spacer()
            }
            
            if !isLast {
                Image(state.lineImage)
                    .offset(x: 45, y: -20)
                    .scaleEffect(x: levelNumber % 2 == 0 ? -1 : 1)
            }
            
            if levelNumber % 2 != 0 {
                Spacer()
            }
        }
    }
}

struct LevelRow: View {
    let levelNumber: Int
    let state: LevelState
    let isLast: Bool
    
    var body: some View {
        HStack {
            if levelNumber % 2 == 0 {
                Spacer()
            }
            
            Image(state.iconImage)
                .overlay {
                    if state != .locked && state != .current {
                        Text("\(levelNumber)")
                            .fontWeight(.bold)
                            .foregroundColor(Color("ArrowColor"))
                            .offset(y: -2)
                    }
                }
            
            if levelNumber % 2 != 0 {
                Spacer()
            }
        }
    }
}


struct LevelPageView: View {
    @AppStorage("highestUnlockedLevel") var highestUnlockedLevel: Int = 1
    
    let totalLevels = 5
    
    func stateFor(level: Int) -> LevelState {
        if level < highestUnlockedLevel {
            return .passed
        } else if level == highestUnlockedLevel {
            return .current
        } else {
            return .locked
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Fixed
                Image("Background Level")
                    .resizable()
                    .ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    ZStack {
                        VStack(spacing: 30) {
                            ForEach((1...totalLevels).reversed(), id: \.self) { levelNumber in
                                LevelPath(levelNumber: levelNumber, state: stateFor(level: levelNumber), isLast: levelNumber == self.totalLevels)
                            }
                        }
                        VStack(spacing: 30) {
                            ForEach((1...totalLevels).reversed(), id: \.self) { levelNumber in
                                if levelNumber <= highestUnlockedLevel {
                                    NavigationLink(destination: ContentView(levelId: levelNumber)) {
                                        LevelRow(
                                            levelNumber: levelNumber,
                                            state: stateFor(level: levelNumber),
                                            isLast: levelNumber == totalLevels
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                } else {
                                    LevelRow(
                                        levelNumber: levelNumber,
                                        state: stateFor(level: levelNumber),
                                        isLast: levelNumber == totalLevels
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 110)
                    .padding(.top, 180)
                    .padding(.bottom, 120)
                }
                .defaultScrollAnchor(.bottom)
                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            Image ("Level Button 2")
                                .overlay {
                                    Text ("LEVEL \(highestUnlockedLevel)")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                            Image ("Level Character")
                                .offset(y: -55)
                        }
                        .padding(.top, 60)
                        .padding(.trailing, 20)
                        .shadow(radius: 3)
                    }
                    
                    Spacer()

                    NavigationLink(destination: ContentView(levelId: highestUnlockedLevel)) {
                        HStack {
                            Image(systemName: "play.fill")
                                .foregroundColor(.white)
                            Text("Continue Last Level")
                                .font(.custom("Inter18pt-SemiBold", size: 19))
                                .foregroundStyle(Color.white)
                        }
                        .frame(width: 330, height: 51)
                        .background(
                            RoundedRectangle(cornerRadius: 200)
                                .foregroundColor(Color.accent)
                                .shadow(color: Color.black.opacity(0.2), radius: 0, x: 0, y: 5)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.bottom, 50)
                }
            }
        }
    }
}

#Preview {
    LevelPageView()
}

