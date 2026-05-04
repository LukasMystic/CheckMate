//
//  LevelView.swift
//  CheckMate
//
//  Created by Gisella Jayata on 04/05/26.
//

import SwiftUI

struct LevelView: View {
    var body: some View {
        ZStack{
            Image("Background Level")
                .background()
                .ignoresSafeArea()
            
            VStack{
                Image("Level Indicator")
                
                Spacer()
                
                Button{
                
                }label: {
                    Image("Level Button")
                }
            }
        }
    }
}

#Preview {
    LevelView()
}
