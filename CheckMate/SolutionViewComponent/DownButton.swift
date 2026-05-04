//
//  DownButton.swift
//  CheckMate
//
//  Created by Vannya Ade Gunawan on 04/05/26.
//

import SwiftUI

struct DownButton: View {
    
    @State var conditionGame = "Win"
    @State var lastPage = true
    
    var body: some View {
        
        HStack {
            Button {
                print("Prev Button Tapped")
            } label: {
                Image(systemName: "chevron.backward")
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .frame(width: 59, height: 59)
            .glassEffect()
            .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 4)

            Spacer()
            
            if(lastPage == false){
                Button {
                    print("Next Button Tapped")
                } label: {
                    Image(systemName: "chevron.forward")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .frame(width: 59, height: 59)
                .glassEffect()
                .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 4)
            } else if lastPage && conditionGame == "Win" {
                Button {
                    print("Next Level Button Tapped")
                } label: {
                    Image(systemName: "arrow.forward")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .frame(width: 59, height: 59)
                .background(Circle().fill(Color.accentColor))
                .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 4)
            } else {
                Button {
                    print("retry Button Tapped")
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .frame(width: 59, height: 59)
                .background(Circle().fill(Color.accentColor))
                .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 4)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    DownButton(conditionGame: "Win", lastPage: true)
}
