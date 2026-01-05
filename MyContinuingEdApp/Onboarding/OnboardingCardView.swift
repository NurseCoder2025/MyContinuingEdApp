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
                if onBoardingStep.stepNumber > 1 && onBoardingStep.stepNumber < 5 {
                    Text("Step \(onBoardingStep.stepNumber - 1): ")
                        .font(.largeTitle)
                        .foregroundStyle(.yellow)
                        .padding(.horizontal, 10)
                }
                
                Text(onBoardingStep.headline)
                    .font(.largeTitle)
                    .foregroundStyle(.yellow)
                    .padding(.horizontal, 10)
                    
                // Image (if available)
                if let cardImage = onBoardingStep.imageName {
                   Image(cardImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 600)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 10)
                        )
                        .padding(.horizontal, 20)
                       
                }//: IF LET
                
                Text(onBoardingStep.description)
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding()
                    .multilineTextAlignment(.leading)
                
                // Button (last card only)
                if onBoardingStep.stepNumber == 5 {
                    StartButtonView()
                }
                
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
