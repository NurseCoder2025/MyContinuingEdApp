//
//  StartButtonView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 12/29/25.
//

import SwiftUI

struct StartButtonView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    
    // MARK: - BODY
    var body: some View {
        Button {
            dataController.showOnboardingScreen.toggle()
        } label: {
            HStack {
                Text("Get Started!")
                Image(systemName: "arrow.right.circle.fill")
                    .imageScale(.large)
            }//: HSTACK
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .background(alignment: .leading) {
                Capsule()
                    .strokeBorder(Color.yellow, lineWidth: 1.5)
            }
        }//: BUTTON
        .tint(Color.yellow)
        
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    StartButtonView()
        .environmentObject(DataController.preview)
}
