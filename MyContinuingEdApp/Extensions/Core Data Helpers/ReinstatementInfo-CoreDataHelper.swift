//
//  ReinstatementInfo-CoreDataHelper.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/7/26.
//

import CoreData
import Foundation


extension ReinstatementInfo {
    
    // MARK: - UI Properties
    // For the date computed properties, using the probationaryEndDate
    // static property in the Date extension because it creates a date
    // that is 90 days from the current date, and that is a reasonable
    // default value for the properties until the user specifies something
    // else.
    var riDeadline: Date {
        get {reinstatementDeadline ?? Date.probationaryEndDate}
        set {reinstatementDeadline = newValue}
    }//: riDeadline
    
    var riInterviewScheduled: Date {
        get {interviewScheduled ?? Date.probationaryEndDate }
        set {interviewScheduled = newValue}
    }//: riInterviewScheduled
    
    var riCEsCompletedDate: Date {
        get {cesCompletedOn ?? Date.now }
        set {cesCompletedOn = newValue }
    }//: riCEsCompletedDate
    
    var riBcCompletedDate: Date {
        get {bcCompletedOn ?? Date.now }
        set {bcCompletedOn = newValue }
    }//: riBcCompletedDate
    
    var riAdditionalTestDate: Date {
        get {additionalTestDate ?? Date.probationaryEndDate}
        set {additionalTestDate = newValue}
    }//: riAddTestDate
    
    var riDocumentationNeeded: String {
        get {documentationNeeded ?? ""}
        set {documentationNeeded = newValue}
    }//: riDocumentationNeeded
    
    var riAdditionalTestResults: String {
        get {additionalTestResults ?? ""}
        set {additionalTestResults = newValue}
    }//: riAdditionalTestResults
    
    var riAdditionalTestNotes: String {
        get {additionalTestNotes ?? ""}
        set {additionalTestNotes = newValue}
    }//: riAdditionalTestNotes
    
    // MARK: - Relationship Properties
    var requiredSpecialCatHours: [ReinstatementSpecialCat] {
        let result = rscItems?.allObjects as? [ReinstatementSpecialCat] ?? []
        return result.sorted()
    }//: requiredSpecialCatHours
    
    /// Computed property for accessing the Credential that has lapsed and needs to be renewed by the user.
    /// ** Optional Data Type **
    ///
    /// The app is structured so that reinstatement of a credential is handled within the context of a RenewalPeriod,
    /// as that is how licensing boards typically handle credential reinstatements.  So, if a Credential expires and is
    /// not renewed by the user, then later if they wish to reinstate it they must meet any preleminary requirements
    /// for reinstatement by the issuing body in addition to current renewal requirements. Given that all RenewalPeriods
    /// should have a Credential assigned to them, the result of this computed property should not be nil. However,
    /// because these relationships are CoreData optionals, making the data type optional as well.
    var lapsedCredential: Credential? {
        if let probRenewal = self.renewal, let probCred = probRenewal.credential {
            return probCred
        } else {
            return nil
        }
    }//: lapsedCredential
    
    // MARK: - EXAMPLE
    static var example: ReinstatementInfo {
        let controller = DataController(inMemory: true)
        let context = controller.container.viewContext
        
        let newRecord = ReinstatementInfo(context: context)
        newRecord.reinstatementID = UUID()
        newRecord.reinstatementDeadline = Date.probationaryEndDate
        newRecord.interviewScheduled = Date.probationaryEndDate
        newRecord.cesCompletedOn = nil
        newRecord.bcCompletedOn = nil
        newRecord.additionalTestDate = Date.probationaryEndDate
        newRecord.documentationNeeded = """
            1. Application
            2. Photo ID copy
            3. CE certificates
            4. Background check form
            """
        newRecord.interviewYN = true
        newRecord.additionalTestingYN = true
        newRecord.additionalTestNotes = "Need to make sure that I register with TestingPros Center in order to re-take the licensing exam."
        newRecord.totalExtraCEs = 25.0
        newRecord.reinstatementFee = 100.0
        
        return newRecord
    }
    
}//: EXTENSION


