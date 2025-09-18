//
//  License-CoreDataHelper.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 8/28/25.
//

import Foundation

extension Credential {
    // Adding properties to better handle Core Data optionals
    var credentialCreNumber: String {
        get {credentialNumber ?? ""}
        set {credentialNumber = newValue}
    }
    
    var credentialName: String {
        get {name ?? ""}
        set {name = newValue}
    }
    
    var credentialCreType: String {
        get {credentialType ?? ""}
        set {credentialType = newValue}
    }
    
    var credentialCreID: UUID {
        credentialID ?? UUID()
    }
    
    var credentialRestrictions: String {
        get {restrictions ?? ""}
        set {restrictions = newValue}
    }
    
    
    // MARK: - Sample License
    static var example: Credential {
        let controller = DataController(inMemory: true)
        let viewContext = controller.container.viewContext
        
        let license = Credential(context: viewContext)
        license.name = "Nursing"
        license.credentialType = "License"
        license.issueDate = Date.now
        license.credentialNumber = "RN0003425"
        
        license.renewalPeriodLength = 24  // time in months
        license.isActive = true
        license.isRestricted = false
        
        return license
    }
    
}//: EXTENSION


// MARK: - Making License conform to Comparable for sorting purposes
extension Credential: Comparable {
    /// This custom comparable function will sort all license objects by the license name
    /// - Parameters:
    ///   - lhs: License object to be compared with another
    ///   - rhs: License object to be compared
    /// - Returns: True if the name of the first (LHS) license object comes before the second, but if they happen to be the
    ///           same then the UUID string will be used to compare and sort licenses.
    public static func <(lhs: Credential, rhs: Credential) -> Bool {
        let left = lhs.credentialName.localizedLowercase
        let right = rhs.credentialName.localizedLowercase
        
        if left == right {
            return lhs.credentialCreID.uuidString < rhs.credentialCreID.uuidString
        } else {
            return left < right
        }
        
    }
}//: EXTENSION


// MARK: - Adding all credential types
extension Credential {
    
    static var allTypes: [String] {
        // Defining credential types in a set array
        ["License", "Certification", "Endorsement", "Membership", "Other"]
    }
}//: EXTENSION

// MARK: - One To Many Relationship Object Arrays
extension Credential {
    // All SpecialCategory objects
    var assignedSpecialCeCategories: [SpecialCategory] {
        let foundCategories = specialCats?.allObjects as? [SpecialCategory] ?? []
        return foundCategories
    }
    
    // All DisciplinaryActionItem objects
    var allDisciplinaryActions: [DisciplinaryActionItem] {
        let actionsTaken = disciplinaryActions?.allObjects as? [DisciplinaryActionItem] ?? []
        return actionsTaken
    }
    
    // All CeActivity objects
    var allCredentialCEs: [CeActivity] {
        let cesForCredential = activities?.allObjects as? [CeActivity] ?? []
        return cesForCredential.sorted {$0.ceTitle < $1.ceTitle}
    }
    
    // All RenewalPeriod objects
    var allRenewals: [RenewalPeriod] {
        let credRenewals = renewals?.allObjects as? [RenewalPeriod] ?? []
        return credRenewals.sorted {$0.renewalPeriodStart < $1.renewalPeriodStart}
    }
    
    
}
