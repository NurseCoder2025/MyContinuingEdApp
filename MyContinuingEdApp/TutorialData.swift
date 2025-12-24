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
         
         Save and export CE certificates for completed activities, journal on your learning, track CE progress for each renewal period, record interesting activities for completion later, and more! 
         """,
        imageName: nil,
        gradientColors: [firstGradient, secondGradient]
    ),
    TutorialStep(
        stepNumber: 2,
        headline: "Getting Started",
        description: """
            It's easy to start using CE Cache:
            
            Begin by entering your credential's information:
                > On the CE Home screen, tap on the button to add a credential
                > Enter as much information as you can and save
            """,
        imageName: nil,
        gradientColors: [firstGradient, secondGradient]
    ),
    TutorialStep(
        stepNumber: 3,
        headline: "Add a Renewal Period",
        description: """
            After a credential has been added you will see it listed below the tags section.  Tap on the plus "+" button to the right of the credential name to add a renewal period. 
            
                Just add the starting and ending dates of the current renewal period you're in right now and the app will create the name for you. 
            
                As you complete CE activities the app will automatically assign them to the correct renewal period for you. A badge will appear next to each renewal period in the sidebar indicating how many activities have been completed for that period.
            """,
        imageName: nil,
        gradientColors: [firstGradient, secondGradient]
    ),
    TutorialStep(
        stepNumber: 4,
        headline: "Add CE Actvities",
        description: """
            Now you're ready to add CE activities to the app!  Just tap on any of the smart filters, tags, or renewal periods to be taken to the CE Activities screen.  Tap on the new activity icon in the upper right to add your first CE.
            
            With the tags feature, you can create custom tags to organize CE activities in any way you choose, so get creative and create a few.
            
            Don't limit yourself to only adding completed CEs.  Whenever you come across a CE opportunity that you'd like to complete at a future date, go ahead and enter it in the app. If the activity has an expiration date then the app can remind you of that so you don't forget.
            """,
        imageName: nil,
        gradientColors: [firstGradient, secondGradient]
    ),
    TutorialStep(
        stepNumber: 5,
        headline: "Next Steps...",
        description: """
            As a free user, you can add one credential, one renewal period for that credential, create 3 custom tags, and add 3 CE activities.
            
            To get the most from this app, consider becoming a CE Cache Pro subscriber which will unlock advanced app features like renewal progress status bars, credential-specific CE requirement tracking, licensing board action tracking, and more.  Plus, you will get access to more subscriber-only features in the future. 
            
            You also have the choice to unlock a limited set of features with a one-time in app purchase (Basic Unlock).  
            """,
        imageName: nil,
        gradientColors: [firstGradient, secondGradient]
    )
]
