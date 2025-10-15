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


// formatting contact hours value to 2 decimal places for use in textfield
let hoursFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    return formatter
}()

// creating a formatter for currency values to be used in another textfield
let currencyFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    
    return formatter
}()

// For formatting numbers to 2 decimal places
var twoDigitDecimalFormatter: NumberFormatter {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    return formatter
}


// Formatting a decimal number as a whole number
var wholeNumFormatter: NumberFormatter {
    let formatter = NumberFormatter()
    formatter.numberStyle = .none
    return formatter
}
