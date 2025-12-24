//
//  TutorialStep.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 12/22/25.
//

import Foundation
import SwiftUI

struct TutorialStep: Identifiable {
    let id: UUID = UUID()
    let stepNumber: Int
    let headline: String
    let description: String
    let imageName: String?
    let gradientColors: [Color]
}
