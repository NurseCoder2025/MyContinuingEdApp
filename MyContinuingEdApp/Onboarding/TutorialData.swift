//
//  TutorialData.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 12/22/25.
//

import Foundation
import SwiftUI

let firstGradient: Color = Color.gray
let secondGradient: Color = Color.black

// MARK: - NEW USER TUTORIAL
let newUserTutorial: [TutorialStep] = [
    TutorialStep(
        stepNumber: 1,
        headline: "Welcome to CE Cache!",
        description: """
         You worked hard to earn your credential(s), so stay on top of your continuing education (CE) requirements with this handy app. 
         
         •  Save and export CE certificates 
         •  Journal on your learning
         •  Track CE progress
         •  Save activities for later completion
         •  And more!
         """,
        imageName: "WelcomeImage_Firefly",
        gradientColors: [firstGradient, secondGradient]
    ),
    TutorialStep(
        stepNumber: 2,
        headline: "Add Credential",
        description: """
            Begin by entering information for your credential such as license number, issue date, etc.
            """,
        imageName: "Add_Credential_screenshot",
        gradientColors: [firstGradient, secondGradient]
    ),
    TutorialStep(
        stepNumber: 3,
        headline: "Add a Renewal Period",
        description: """
            Tap on the "Add Renewal Period" or plus "+" button to the right of the credential name to add a renewal period. 
            
            This will store all activities completed between the period's starting and ending dates for the given credential.
            """,
        imageName: "Add_RenewalPeriod_screenshot",
        gradientColors: [firstGradient, secondGradient]
    ),
    TutorialStep(
        stepNumber: 4,
        headline: "Add CE Actvities",
        description: """
            Tap on any of the smart filters, tags, or renewal periods to be taken to the CE Activities screen.  
            
            From there, tap on the new activity icon in the upper right to add your first activity.
            
            
            
            Note: Activities will automatically be assigned to the correct renewal period once they are marked as completed.
            """,
        imageName: "Add_CeActivity_screenshot",
        gradientColors: [firstGradient, secondGradient]
    ),
    TutorialStep(
        stepNumber: 5,
        headline: "How to Get the Most Out of This App...",
        description: """
            • Add CE activities to complete later
            • Create custom tags to organize activities
            • Journal on what you learn
            • Regularly check on your progress
            • Subscribe to CE Cache Pro!
            """,
        imageName: nil,
        gradientColors: [firstGradient, secondGradient]
    )
]
