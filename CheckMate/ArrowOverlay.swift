//
//  ArrowOverlay.swift
//  CheckMate
//
//  Created by Stanley Pratama Teguh on 06/05/26.
//


import SwiftUI
import ChessboardKit
import ChessKit

struct ArrowOverlay: View {
    let lan: String
    let columns: Int
    let rows: Int
    let shouldFlip: Bool
    
    var body: some View {
        GeometryReader { geo in
            let sqWidth = geo.size.width / CGFloat(columns)
            let sqHeight = geo.size.height / CGFloat(rows)
            let startSquare = String(lan.prefix(2))
            let endSquare = String(lan.suffix(2).prefix(2))
            
            let startPoint = point(for: startSquare, sqWidth: sqWidth, sqHeight: sqHeight)
            let endPoint = point(for: endSquare, sqWidth: sqWidth, sqHeight: sqHeight)
            
            let distance = hypot(endPoint.x - startPoint.x, endPoint.y - startPoint.y)
            let midX = (startPoint.x + endPoint.x) / 2
            let midY = (startPoint.y + endPoint.y) / 2
            
            let angle = atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
            
            Image("ArrowAnalysis")
                .resizable()
                .frame(width: sqWidth * 0.4, height: distance)
                .rotationEffect(.radians(Double(angle) + .pi / 2))
                .position(x: midX, y: midY)
                .opacity(0.8)
        }
    }
    
    func point(for square: String, sqWidth: CGFloat, sqHeight: CGFloat) -> CGPoint {
        guard square.count >= 2 else { return .zero }
        let fileChar = square.first!
        let rankChar = square.last!
        let file = Int(fileChar.asciiValue! - Character("a").asciiValue!)
        let rank = Int(String(rankChar))! - 1
        let col = shouldFlip ? (columns - 1) - file : file
        let row = shouldFlip ? rank : (rows - 1) - rank
        
        return CGPoint(x: (CGFloat(col) + 0.5) * sqWidth, y: (CGFloat(row) + 0.5) * sqHeight)
    }
}