//
//  CEsEarned.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/13/25.
//


import Foundation


struct CeProgress: Identifiable {
    let id = UUID()
    
    var amount: Double
    var requiredAmount: Double
    var inHoursOrUnits: Int16
    
    var earnedUnits: String {
        switch inHoursOrUnits {
        case 2:
            return "units"
        default:
            return "hours"
        }
    }
    
}//: CEsEarned


struct SpecialCatCEHours: Identifiable {
    var id: String {specialCatName}
    
    var specialCatName: String
    var amountEarned: Double
    var requiredAmount: Double
    
    var color: String
    
}
