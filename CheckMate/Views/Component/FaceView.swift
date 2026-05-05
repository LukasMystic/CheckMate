//
//  FaceView.swift
//  CheckMate
//
//  Created by Vannya Ade Gunawan on 04/05/26.
//

import SwiftUI

enum FaceState {
    case best
    case blunder
    case brilliant
    case mistake

    var imageName: String {
        switch self {
        case .best: return "bestFace"
        case .blunder: return "blunderFace"
        case .brilliant: return "brilliantFace"
        case .mistake: return "mistakeFace"
        }
    }
}

struct FaceView: View {
    let face: FaceState

    var body: some View {
        Image(face.imageName)
            .resizable()
            .scaledToFit()
            .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 4)    }
}
