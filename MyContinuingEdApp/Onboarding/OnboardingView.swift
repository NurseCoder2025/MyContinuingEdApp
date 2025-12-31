//
//  OnboardingView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 12/22/25.
//

import SwiftUI

struct OnboardingView: View {
    // MARK: - PROPERTIES
    let welcomeCards: [TutorialStep] =  newUserTutorial
    
    // MARK: - BODY
    var body: some View {
        TabView {
            ForEach(welcomeCards) { card in
              OnboardingCardView(onBoardingStep: card)
            }//: LOOP
        }//: TAB VIEW
        .tabViewStyle(PageTabViewStyle())
        .padding(.vertical, 20)
        
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    OnboardingView()
}
