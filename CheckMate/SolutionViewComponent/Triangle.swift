//
//  Triangle.swift
//  CheckMate
//
//  Created by Vannya Ade Gunawan on 04/05/26.
//

import SwiftUI

struct Triangle: Shape {
    var vertex1: CGPoint
    var vertex2: CGPoint
    var vertex3: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: vertex1)
        path.addLine(to: vertex2)
        path.addLine(to: vertex3)
        path.closeSubpath()
        return path
    }
}
