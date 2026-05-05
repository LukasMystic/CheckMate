//
//  ArrowAnalisis 2.swift
//  CheckMate
//
//  Created by Vannya Ade Gunawan on 04/05/26.
//


import SwiftUI
struct ArrowAnalisis: View {
    let arrowHead = Triangle(
        vertex1: CGPoint(x: 0, y: 15),
        vertex2: CGPoint(x: 11.02, y: 15),
        vertex3: CGPoint(x: 5.51, y: 0)
    )

    var body: some View {
        VStack(spacing: -1) {
            arrowHead
                .fill(.arrow).opacity(0.5)
                .frame(width: 11.02, height: 15)
            
            Rectangle()
                .frame(width: 5, height: 149)
                .foregroundColor(.arrow).opacity(0.5)
        }
    }
}

#Preview {
    ArrowAnalisis()
}
