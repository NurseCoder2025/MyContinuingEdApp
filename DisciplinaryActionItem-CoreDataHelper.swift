//
//  DisciplinaryActionItem-CoreDataHelper.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/13/25.
//

import Foundation

// Purpose: Make the handling of Core Data optionals easier in the UI

extension DisciplinaryActionItem {
    
    var daiActionName: String {
        get {actionName ?? ""}
        set {actionName = newValue}
    }
    
    var daiActionDescription: String {
        get {actionDescription ?? ""}
        set {actionDescription = newValue}
    }
    
    var daiActionType: String {
        get {actionType ?? "" }
        set {actionType = newValue}
    }
    
    var daiResolutionActions: String {
        get {resolutionActions ?? ""}
        set {resolutionActions = newValue}
    }
    
    var daiActionStartDate: Date {
        return actionStartDate ?? Date.now
    }
    
    var daiActionEndDate: Date {
        return actionEndDate ?? Date.now
    }
    
    var daiAppealedActionDate: Date {
        return appealDate ?? Date.now
    }
    
    var daiAppealNotes: String {
        get {appealNotes ?? ""}
        set {appealNotes = newValue}
    }
    
    var daiCEDeadlineDate: Date {
        return ceDeadline ?? Date.now
    }
    
    var daiFinesDueDate: Date {
        return fineDeadline ?? Date.now
    }
       
    var daiCommunityServiceDeadline: Date {
        return commServiceDeadline ?? Date.now
    }
}

// Setting the actionsTaken and actionsTakenRaw property so I can save an array of
// DisciplineAction enum values as a single Data? property in Core Data.
extension DisciplinaryActionItem {
    var actionsTaken: [DisciplineAction] {
        get {
            guard let data = actionsTakenRaw as? Data else { return [] }
            
            return (try? JSONDecoder().decode([DisciplineAction].self, from: data)) ?? []
        }
        
        set {
            actionsTakenRaw = try? JSONEncoder().encode(newValue) as NSObject
        }
    }
}


// Creating an example item for development purposes
extension DisciplinaryActionItem {
    static var example: DisciplinaryActionItem {
        let container = DataController(inMemory: true)
        let viewContext = container.container.viewContext
        
        let sampleAction = DisciplinaryActionItem(context: viewContext)
        sampleAction.actionName = "Med Error Complaint"
        sampleAction.actionDescription = "Instead of giving the patient 0.5mL of atenolol you gave 1.5mL of cortisol."
        let sampleType: DisciplineType = .reprimand
        sampleAction.actionType = sampleType.rawValue
        
        let actionOne: DisciplineAction = .continuingEd
        let actionTwo: DisciplineAction = .fines
        // Creating array of actions for assigning to the actionsTakenRaw property
        let actionsArray: [DisciplineAction] = [actionOne, actionTwo]
        
        sampleAction.actionsTakenRaw = try? JSONEncoder().encode(actionsArray) as NSObject
        
        sampleAction.disciplinaryCEHours = 5.0
        sampleAction.ceDeadline = Date.now.addingTimeInterval(60*60*24*90)
        sampleAction.fineAmount = 150.00
        sampleAction.fineDeadline = Date.now.addingTimeInterval(60*60*24*30)
        
        return sampleAction
    }
}
