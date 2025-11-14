//
//  CEsEarned.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/13/25.
//


import Foundation


struct CeEarned: Identifiable {
    let id = UUID()
    
    var amount: Double
    var earnedDate: Date
    
    var dateLabel: String {
        let formatter: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "MMM yy"
            return df
        }()
        return formatter.string(from: earnedDate)
    }//: dateLabel
}//: CEsEarned



struct CeCost: Identifiable {
    let id = UUID()
    
    var spentDate: Date
    var cost: Double
    
    var dateLabel: String {
        let formatter: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "MM/yyyy"
            return df
        }()
        return formatter.string(from: spentDate)
    }//: dateLabel
    
}
