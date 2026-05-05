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

struct LevelView: View {
    var body: some View {
        ZStack {
            // background
            Image("Background Level")
                .ignoresSafeArea()
            
            // levels path
            ZStack {
                VStack(spacing: 30) {
                    LevelPath(levelNumber: 5, state: .locked, isLast: true)
                    LevelPath(levelNumber: 4, state: .locked, isLast: false)
                    LevelPath(levelNumber: 3, state: .current, isLast: false)
                    LevelPath(levelNumber: 2, state: .passed, isLast: false)
                    LevelPath(levelNumber: 1, state: .current, isLast: false)
                }
                .padding(.horizontal, 110)
                .padding(.bottom, 90)
                
                VStack(spacing: 30) {
                    LevelRow(levelNumber: 5, state: .locked, isLast: true)
                    LevelRow(levelNumber: 4, state: .locked, isLast: false)
                    LevelRow(levelNumber: 3, state: .current, isLast: false)
                    LevelRow(levelNumber: 2, state: .passed, isLast: false)
                    LevelRow(levelNumber: 1, state: .passed, isLast: false)
                }
                .padding(.horizontal, 110)
                .padding(.bottom, 90)
            }
            
            VStack {
                ZStack {
                    Image("Level Button 2")
                        .overlay {
                            Text("LEVEL 3")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    Image("Level Character")
                        .offset(y: -55)
                }
                .padding(.top, 100)
                .padding(.leading, 230)
                .shadow(radius: 3)
                
                Spacer()
                
                Button {
                    print("Continue Button Tapped")
                } label: {
                    Image(systemName: "restart")
                        .scaleEffect(x: -1, y: 1)
                        .foregroundColor(.white)
                    Text("Continue Last Level")
                        .font(.custom("Inter18pt-SemiBold", size: 19))
                        .foregroundStyle(Color(.white))
                }
                .frame(width: 330, height: 51)
                .background(RoundedRectangle(cornerRadius: 200)
                .foregroundColor(Color.accent)
                .shadow(color:Color.shadow, radius: 0, x: 0, y: 5))
                .padding(.bottom, 50)
                
            }
        }
    }
}

#Preview {
    LevelView()
}
