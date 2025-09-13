//
//  DisciplinaryHistoryItem-CoreDataHelper.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 8/29/25.
//

import Foundation

// The purpose of this file is to make handling the DisciplinaryHistoryIem object easier with Core Data

extension DisciplinaryHistoryItem {
    // Handling Core Data optionals for Strings & Dates
    
    var dhiName: String {
        get {actionName ?? ""}
        set {actionName = newValue}
    }
    
    var dhiDescription: String {
        get {actionDescription ?? ""}
        set {actionDescription = newValue}
    }
    
    
    var dhiResoluationActions: String {
        get {resolutionActions ?? ""}
        set {resolutionActions = newValue}
    }
    
    
    var dhiDisciplinaryDate: Date {
        get {disciplinaryDate ?? Date.now}
        set {disciplinaryDate = newValue}
    }
    
    var dhiDisciplineEndDate: Date {
        get {disciplineEndDate ?? Date.now}
        set {disciplineEndDate = newValue}
    }
    
}//: EXTENSION
