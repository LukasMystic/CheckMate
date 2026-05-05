//
//  HapticServices.swift
//  CheckMate
//
//  Created by Vannya Ade Gunawan on 05/05/26.
//

import UIKit

class HapticServices {
    
    //when the piece move
    func pieceMoveHaptics() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    //when check mate happen
    func CheckMateHaptics() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }

    //when winpopuphappen
    func WinPopUpHaptics() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
}

