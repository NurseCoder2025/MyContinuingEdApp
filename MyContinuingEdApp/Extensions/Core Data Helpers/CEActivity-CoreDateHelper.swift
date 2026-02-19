//
//  CEActivity-CoreDateHelper.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/16/25.
//

import CoreData
import Foundation

extension CeActivity {
    // Extending CEActivity to handle Core Data optionals easier
    // MARK: - UI HELPERS
    var ceTitle: String {
        get { activityTitle ?? "" }
        set { activityTitle = newValue}
    }
    
    var ceDescription: String {
        get { activityDescription ?? "" }
        set { activityDescription = newValue }
    }
    
    
    var ceActivityFormat: String {
        get { activityFormat ?? "" }
        set { activityFormat = newValue }
    }
    
    /// Computed CoreData helper for CeActivity's itemsToBring string property. If the property is nil,
    /// will return an empty string value. Will set the property value to whatever new String value the
    /// user assigns to it in the UI.
    var ceItemsToBring: String {
        get {itemsToBring ?? ""}
        set {itemsToBring = newValue}
    }// ceItemsToBring
    
    
    // Removing this part of the helper as activities that aren't completed
    // shouldn't have a date value at all (should be nil)
    //    var ceActivityCompletedDate: Date {
    //        get {dateCompleted ?? .futureCompletion }
    //        set {dateCompleted = newValue}
    //    }
    
    //
    var ceActivityExpirationDate: Date {
        let calendar = Calendar.current
        let futureExpDate = calendar.startOfDay(for: .futureExpiration)
        let dateToUse = (expirationDate == nil ? futureExpDate : calendar.startOfDay(for: expirationDate!))
        return dateToUse
    }
    
    var ceActivityModifiedDate: Date {
        modifiedDate ?? .now
    }
    
    var ceActivityAddedDate: Date {
        activityAddedDate ?? .now
    }
    
    /// Computed CoreData helper property for CeActivity's dateCompleted property.  If the property is
    /// nil then the getter will return the futureCompletion contsant for the Date struct.
    var ceActivityCompletedDate: Date {
        dateCompleted ?? .futureCompletion
    }
    
    /// Computed CoreData helper property for CeActivity's startTime property.  If the property happens to
    /// be nil, then ceStartTime will return the futureCompletion static property for Date.
    var ceStartTime: Date {
        get {startTime ?? Date.futureCompletion}
        set {startTime = newValue}
    }//: ceStartTime
    
    /// Computed CoreData helper property for CeActivity's endTime property.  If the property happens to
    /// be nil, then ceEndTime will return the futureCompletion static property for Date.
    var ceEndTime: Date {
        get {endTime ?? Date.futureCompletion}
        set {endTime = newValue}
    }//: ceEndTime
    
    /// Computed CoreData helper property for CeActivity's infoWebsiteURL property, returning an
    /// empty string if the field is nil.
    var ceInfoWebsiteURL: String {
        get {
            infoWebsiteURL ?? ""
        }
        set {
            infoWebsiteURL = newValue
        }
    }//: ceInfoWebsiteURL
    
    /// Computed CoreData helper property for CeActivity's registrationURL property, returning an empty
    /// string value if field is nil.
    var ceRegistrationURL: String {
        get {
            registrationURL ?? ""
        }
        set {
            registrationURL = newValue
        }
    }//: ceRegistrationURL
    
    /// Computed CoreData helper property for CeActivity's registeredOn Date property, returning the current
    /// Date if field is nil.
    var ceRegisteredOn: Date {
        get {
            registeredOn ?? Date.now
        }
        
        set {
            registeredOn = newValue
        }
        
    }//: ceRegisteredOn
    
    /// Computed CoreData helper property for CeActivity's registrationDeadline property which both gets and
    /// sets the value.  With the getter, if the actual property value is nil then the Date static constant
    /// registrationDeadlineDate is returned, which is 30 days from the current date and time.
    var ceRegistrationDeadline: Date {
        get { registrationDeadline ?? Date.registrationDeadlineDate }
        set { registrationDeadline = newValue }
    }//: ceRegistrationDeadline
    
    // MARK: - Tag-related properties
    var activityTags: [Tag] {
        let result = tags?.allObjects as? [Tag] ?? []
        return result.sorted()
    }
    
    var allActivityTagString: String {
        // making sure there are tags in the tag property
        guard let tags else { return "No tags"}
        
        if tags.count == 0 {
            return "No tags"
        } else {
            return activityTags.map(\.tagTagName).formatted()
        }
        
    }
    
    // MARK: - Example Activity
    static var example: CeActivity {
        let controller = DataController(inMemory: true)
        let viewContext = controller.container.viewContext
        
        let activity = CeActivity(context: viewContext)
        activity.activityTitle = "Example CE Activity"
        
        // MARK: CE Designation
        let sampleDesignation = CeDesignation(context: viewContext)
        sampleDesignation.designationName = "Nursing Continuing Education"
        sampleDesignation.designationAbbreviation = "Nursing CE"
        sampleDesignation.designationAKA = "Continuing Nursing Education (CNE)"
        activity.designation = sampleDesignation
        
        activity.activityFormat = "Webinar"
        activity.ceAwarded = 1.0
        activity.cost = 50.00
        activity.activityDescription = "A sample activity that enhanced your professional growth"
        activity.activityCompleted = true
        activity.expirationDate = Date.now.addingTimeInterval(86400 * 30)
        activity.evalRating = 3
        
        return activity
    }
    
}

// MARK: - Conforming CeActivity to Comparable
extension CeActivity: Comparable {
    public static func <(lhs: CeActivity, rhs: CeActivity) -> Bool {
        let left = lhs.ceTitle.localizedLowercase
        let right = rhs.ceTitle.localizedLowercase
        
        if left == right {
            return lhs.ceDescription < rhs.ceDescription
        } else {
            return left < right
        }
    }
}


// MARK: - OTHER COMPUTED PROPERTIES
extension CeActivity {
    
    // computed property to determine if the given activity will be
    // expiring soon or not
    
    // Updated 8/12/25 to reflect the fact I removed the expirationDate
    // getter and setter from the helper file in order to keep nil values
    // nil (and not replaced with an arbitrary fill-in value).
    
    /// Computed property that returns an ExpirationType enum value that reflects whether the CeActivity it is being
    /// called upon has expired, will be expiring soon, or is still valid.  If the user has marked the activity as being
    /// completed then that enum value will be returned.
    ///
    /// The expiring soon status is based on the expiration date 30 days or less away from the current date.
    var expirationStatus: ExpirationType {
        if let expiration = expirationDate {
            let monthOut: Double = 86400 * 30

            // When running a unit test on this computed property the test
            // failed on the first run when trying to assign the final day
            // value to an activity where the expiration date was set to
            // Date.now.  Using the startOfDay method to set both the
            // activity expiration date and current date to the same day at
            // midnight so comparisons can be made between them.
            let calendar = Calendar.current
            let expirationDate = calendar.startOfDay(for: expiration)
            let currentDate = calendar.startOfDay(for: Date.now)

            if activityCompleted {
                return .finishedActivity
            } else if expirationDate < currentDate {
                return .expired
            } else if expirationDate == currentDate {
                return .finalDay
            } else if expirationDate <= calendar.startOfDay(for: Date.now.addingTimeInterval(monthOut)) {
                return .expiringSoon
            } else {
                return .stillValid
            }

        } //: IF LET

        // If there is NO expiration date for an activity, return either
        // that it has been completed or it is still valid
        if activityCompleted {
            return .finishedActivity
        } else if self.isLiveActivity {
            return .liveActivity
        } else {
            return .stillValid
        }

    }//: expirationStatus
    
    /// Computed property that returns the result of the expirationStatus computed property back
    /// as a String, using the enum's raw value.
    var expirationStatusString: String {
        return expirationStatus.rawValue
    }//: expirationStatusString
    
    
    /// Computed property that returns True if the CeActivity that this property is called upon
    /// has a type property whose value is an ActivityType that is considered to be a "live activity".
    ///
    ///- Warning: This computed property is called often in the creation of various UI elements,
    /// including parts of ActivityRow and ActivityBasicInfo.  Can cause app to hang if the logic
    /// is revised to be processor-heavy (i.e. creating an instance of DataController).
    ///
    /// Live activities include the majority of the pre-created ActivityTypes (from the
    /// Activity Type.json file), and include: conference, course, journal club, podcast (live),
    /// simulation, webinar (live), and workshop.  Non-live activities are the article and
    /// recording types. If the type property has NOT been set by the user then this value will
    /// come back as false.
    var isLiveActivity: Bool {
        guard let selectedType = self.type else {return false}
        let nonLiveNames: Set<String> = [
            "Article",
            "Recording"
        ]
        return nonLiveNames.doesNOTContain(selectedType.activityTypeName)
    }//: isLiveActivity
    
}//: EXTENSION

// MARK: - Designation ID Computed Property
// Adding another extension to allow for CeDesignation objects to be identified by
// SwiftUI
extension CeActivity {
    var designationID: NSManagedObjectID? {
        get { designation?.objectID }
        set {
            if let newID = newValue,
               let context = self.managedObjectContext,
               let newDesignation = try? context.existingObject(with: newID) as? CeDesignation {
                self.designation = newDesignation
            }
        }
    }//: DESIGNATIONID
    
}//: EXTENSION

// MARK: - Credential Related Properties
extension CeActivity {
    
    /// Computed property to retrieve all Credential objects associated with a given CE object
    var activityCredentials: [Credential] {
        let result = credentials?.allObjects as? [Credential] ?? []
        return result.sorted()
    }//: activityCredentials
    
    var assignedRenewals: [RenewalPeriod] {
        let result = renewals?.allObjects as? [RenewalPeriod] ?? []
        return result
    }//: assignedRenewalPeriod
    
    var renewalsWithCredentials: [Credential: RenewalPeriod] {
        var result: [Credential: RenewalPeriod] = [:]
        let allRenewals = assignedRenewals
        guard allRenewals.isNotEmpty else { return [:] }
        let renewalsWithCreds = allRenewals.filter {
            $0.credential != nil
        }
        for renewal in renewalsWithCreds {
            if let assignedCred = renewal.credential {
                result[assignedCred] = renewal
            }//: IF LET
        }//: LOOP
        return result
    }//: renewalsWithCredentials
}//: EXTENSION


// MARK: - METHODS
extension CeActivity {
    
    /// Method for converting CE units earned for a given CeActivity object into clock hours for the purpose
    /// of calculating total CEs earned, CEs remaining, and displaying progress bar indicators.
    /// - Parameter credential: If needed, a Credential object can be passed in as an argument
    /// - Returns: Amount of continuing education awarded for an activity converted into clock hours
    ///
    /// This method can be used without any arguments as the credential one is optional.  However, when
    /// that argument is nil, then if an activity's ceAwarded property is in units versus hours (see hoursOrUnits
    /// property) the method will return either the clockHoursAwarded value (if greater than 0) or a calculated
    /// conversion based on the standard ratio of 10 hours per unit.  Otherwise, the conversion will be based
    /// on the ratio value set for the passed in credential.
    func getCeClockHoursEarned(for credential: Credential?) -> Double {
        let activityUnits = self.hoursOrUnits
        var clockHoursEarned: Double = 0.0
        
        // TODO: Re-evaluate logic and test this method!
        switch activityUnits {
        case 1:
            return self.ceAwarded
        default:
            if self.clockHoursAwarded > 0 {
                clockHoursEarned = self.clockHoursAwarded
            } else if let cred = credential, cred.measurementDefault == 2, cred.defaultCesPerUnit > 0 {
                // Use the Credential's CEU ratio if specified by the user
                let credHrsToUnitRatio = cred.defaultCesPerUnit
                clockHoursEarned = self.ceAwarded * credHrsToUnitRatio
            } else if let _ = credential {
                // Use the standard CEU ratio of 10 hours to 1 unit if
                // otherwise not specified
                let credHrsToUnitRatio: Double = 10.0
                clockHoursEarned = self.ceAwarded * credHrsToUnitRatio
            }
        }//: SWITCH
        return clockHoursEarned
    }//: getCeClockHoursEarned(for)
    
}//: EXTENSION
