//
//  Extensions-Styles.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/15/25.
//

// Purpose: To contain extensions for ShapeStyle and other related UI elements for creating reusable,
// custom components

import SwiftUI

// Make the translucentGreyGradient ONLY available when ShapeStyle is a linear gradient
extension ShapeStyle where Self == LinearGradient {
    static var translucentGreyGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(.systemGray5).opacity(0.3),
                Color(.systemGray3).opacity(0.8)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}//: SHAPESTYLE EXT (Linear Gradient)
