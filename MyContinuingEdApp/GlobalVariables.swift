//
//  GlobalVariables.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/23/25.
//

import Foundation

// MARK: - FORMATTERS
/// Computed property to format any values where only a single decimal place is needed in a Text control.
let singleDecimalFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 1
    return formatter
}()
