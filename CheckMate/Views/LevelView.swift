import SwiftUI

// models
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

// button animation
struct GameButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .offset(y: configuration.isPressed ? 4 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

// components
struct LevelPath: View {
    let levelNumber: Int
    let state: LevelState
    let isLast: Bool
    
    var body: some View {
        HStack {
            if levelNumber % 2 == 0 { Spacer() }
            
            if !isLast {
                Image(state.lineImage)
                    .offset(x: 45, y: -20)
                    .scaleEffect(x: levelNumber % 2 == 0 ? -1 : 1)
            }
            
            if levelNumber % 2 != 0 { Spacer() }
        }
    }
}

struct LevelRow: View {
    let levelNumber: Int
    let state: LevelState
    
    var body: some View {
        HStack {
            if levelNumber % 2 == 0 { Spacer() }
            
            Button {
                print("Level \(levelNumber) tapped")
            } label: {
                Image(state.iconImage)
                    .overlay {
                        if state != .locked && state != .current {
                            Text("\(levelNumber)")
                                .fontWeight(.bold)
                                .foregroundColor(Color("ArrowColor"))
                                .offset(y: -2)
                        }
                    }
            }
            .buttonStyle(GameButtonStyle())
            .disabled(state == .locked)
            
            if levelNumber % 2 != 0 { Spacer() }
        }
    }
}

// main
struct LevelView: View {
    
    var body: some View {
        ZStack {

            Image("Background Level")
                .resizable()
                .ignoresSafeArea()
            
            ZStack {
                VStack(spacing: 30) {
                    LevelPath(levelNumber: 5, state: .locked, isLast: true)
                    LevelPath(levelNumber: 4, state: .locked, isLast: false)
                    LevelPath(levelNumber: 3, state: .current, isLast: false)
                    LevelPath(levelNumber: 2, state: .passed, isLast: false)
                    LevelPath(levelNumber: 1, state: .passed, isLast: false)
                }
                .padding(.horizontal, 110)
                .padding(.bottom, 90)
                
                VStack(spacing: 30) {
                    LevelRow(levelNumber: 5, state: .locked)
                    LevelRow(levelNumber: 4, state: .locked)
                    LevelRow(levelNumber: 3, state: .current)
                    LevelRow(levelNumber: 2, state: .passed)
                    LevelRow(levelNumber: 1, state: .passed)
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
                .padding(.top, 50)
                .padding(.leading, 230)
                .shadow(radius: 3)
                
                Spacer()
                
                Button {
                    print("Continue Level Button Tapped")
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "restart")
                            .scaleEffect(x: -1, y: 1)
                        Text("Continue Last Level")
                            .font(.custom("Inter18pt-SemiBold", size: 17))
                    }
                    .foregroundColor(.white)
                    .frame(width: 330, height: 51)
                    .background(
                        RoundedRectangle(cornerRadius: 200)
                            .fill(Color.accentColor)
                            .shadow(color: .black.opacity(0.3), radius: 0, x: 0, y: 5)
                    )
                }
                .buttonStyle(GameButtonStyle())
            }
        }
    }
}

#Preview {
    LevelView()
}


