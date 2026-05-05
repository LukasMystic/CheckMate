//
//  SoundButton.swift
//  CheckMate
//
//  Created by Vannya Ade Gunawan on 04/05/26.
//

import SwiftUI

struct SoundButton: View {
    @State private var isMuted = false
    
    var body: some View {
        Button {
            isMuted.toggle()
        } label: {
            Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .font(.title)
                .foregroundColor(.black)
                .contentTransition(.symbolEffect(.replace))
        }
        .frame(width: 59, height: 59)
        .glassEffect()
        .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 4)
    }
}

#Preview {
    SoundButton()
}
