//
//  SolutionButton.swift
//  CheckMate
//
//  Created by Vannya Ade Gunawan on 04/05/26.
//

import SwiftUI

struct SolutionButton: View {
    @State var mistakeCount: Int = 6
    
    var body: some View {
        VStack {
            if mistakeCount > 5 {
                Text("Solution")
                    .font(.subheadline)
                    .foregroundColor(.black)
            }
        }
        .frame(width: 143, height: 58)
        .glassEffect()
        .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 4)
    }
}

#Preview {
    SolutionView()
}
