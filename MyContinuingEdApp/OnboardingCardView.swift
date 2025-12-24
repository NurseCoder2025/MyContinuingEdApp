//
//  OnboardingCardView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 12/22/25.
//

import SwiftUI

struct OnboardingCardView: View {
    // MARK: - PROPERTIES
    let onBoardingStep: TutorialStep
    
    
    // MARK: - BODY
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                // Card Title (heading)
                Text(onBoardingStep.headline)
                    .font(.largeTitle)
                    .foregroundStyle(.yellow)
                    
                    
                // Image (if available)
                if let cardImage = onBoardingStep.imageName {
                   Image(cardImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                }//: IF LET
                
                Text(onBoardingStep.description)
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding()
                    .multilineTextAlignment(.leading)
                
            }//: VSTACK
            
        }//: ZSTACK
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
        .background(
            LinearGradient(
                gradient: Gradient(
                    colors: onBoardingStep.gradientColors),
                startPoint: .top,
                endPoint: .bottom
            )//: GRADIENT
        )//: BACKGROUND
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 20)
        
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    OnboardingCardView(onBoardingStep: newUserTutorial[0])
}
