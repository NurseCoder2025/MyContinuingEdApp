//
//  DisciplinaryActionItem-CoreDataHelper.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/13/25.
//

import Foundation

// Purpose: Make the handling of Core Data optionals easier in the UI

extension DisciplinaryActionItem {
    
    var daiDisciplineID: UUID {
        disciplineID ?? UUID()
    }
    
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
        // Because the actionEndDate as well as other deadline dates will be used for comparison
        // purposes within various functions in the app (specifically, the notification-related ones)
        // it is important to set the nil collasced value to be a standard value (date with 12:00:00
        // components) so that two dates can be evenly compared by the date value alone.
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        return actionEndDate ?? now
    }
    
    var daiAppealedActionDate: Date {
        return appealDate ?? Date.now
    }
    
    var daiAppealNotes: String {
        get {appealNotes ?? ""}
        set {appealNotes = newValue}
    }
    
    var daiCEDeadlineDate: Date {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        return ceDeadline ?? now
    }
    
    var daiFinesDueDate: Date {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        return fineDeadline ?? now
    }
       
    var daiCommunityServiceDeadline: Date {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        return commServiceDeadline ?? now
    }
}

// Setting the actionsTaken and actionsTakenRaw property so I can save an array of
// DisciplineAction enum values as a single Data? property in Core Data.
extension DisciplinaryActionItem {
    
    /// Computed CoreData property helper for DisciplinaryActionItem object that returns an array of
    /// DisciplineAction (enum) objects. Use this property to both get and set values for the
    /// actionsTakenRaw property as it makes doing so a lot easier.
    ///
    /// This computed property both gets and sets the DisciplinaryActionItem's actionsTAkenRaw
    /// Transformable property.  It uses the JSON encoder and decoder to encode and decode
    /// any enum values to and from this property as a NSObject since that is how enum values
    /// must be stored as in CoreData.
    var actionsTaken: [DisciplineAction] {
        get {
            guard let data = actionsTakenRaw as? Data else { return [] }
            
            return (try? JSONDecoder().decode([DisciplineAction].self, from: data)) ?? []
        }
        
        set {
            actionsTakenRaw = try? JSONEncoder().encode(newValue) as NSObject
        }
    }//: actionsTaken
    
}//: EXTENSION


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
