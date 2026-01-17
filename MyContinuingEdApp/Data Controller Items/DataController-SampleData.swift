//
//  DataController-SampleData.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/30/25.
//

// Purpose: Due to the large amount of code used in creating sample data for app development
// & testing, separating this functionality out of the main DataController class file and into
// an extension for improved code readability.

import CoreData
import Foundation


extension DataController {
    // MARK: - SAMPLE DATA for Simulation
    
    
    /// Method that creates a set of sample data for use in testing the app in the iOS and other device simulators.
    ///
    /// Specifically, the sample data includes:
    /// - 1 renewal period
    /// - 1 sample country
    /// - 1 sample state
    /// - 1 sample Issuer
    /// - 1 sample credential
    /// - 5 sample tags
    /// - 50 sample CeActivities, 10 assigned to each tag
    /// Each sample CeActivity may or may not be marked as completed (random assignment).  For those that are marked
    /// completed, a sample ActivityReflection object is created and assigned to it with generic values for the string properties.
    func createSampleData() {
        let viewContext = container.viewContext
        
        // Creating calendar components for the sample renewal period
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let janFirst = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1))
        
        
        // Creating renewal period for sample data
        let sampleRenewalPeriod = RenewalPeriod(context: viewContext)
        let sampleStartDate = janFirst ?? Date.now
        sampleRenewalPeriod.periodStart = sampleStartDate
        sampleRenewalPeriod.periodEnd = sampleStartDate.addingTimeInterval(86400 * 730)
        
        // Creating sample Country for Issuer object
        let sampleCountry = Country(context: viewContext)
        sampleCountry.name = CountryJSON.defaultCountry.name
        sampleCountry.alpha2 = CountryJSON.defaultCountry.alpha2
        sampleCountry.alpha3 = CountryJSON.defaultCountry.alpha3
        
        // Creating sample State for Issuer object
        let sampleState = USState(context: viewContext)
        sampleState.stateName = USStateJSON.example.stateName
        sampleState.abbreviation = USStateJSON.example.abbreviation
        
        // Creating Issuer object for the sample Credential
        let sampleIssuer = Issuer(context: viewContext)
        sampleIssuer.issuerName = "Ohio Board of Nursing"
        sampleIssuer.country = sampleCountry
        sampleIssuer.state = sampleState
        
        // Creating Credential object for all sample credentials
        let sampleCredential = Credential(context: viewContext)
        sampleCredential.name = "Ohio RN License"
        sampleCredential.credentialType = "license"
        sampleCredential.isActive = true
        sampleCredential.issueDate = Date.renewalStartDate
        sampleCredential.renewalPeriodLength = 24
        sampleCredential.renewalCEsRequired =  36
        sampleCredential.measurementDefault = 1
        sampleCredential.credentialNumber = "RN123456"
        sampleCredential.issuer = sampleIssuer
        
        // Assigning sample renewal period to the sample credential
        sampleCredential.addToRenewals(sampleRenewalPeriod)
        
        // Creating 5 sample tags, and 10 activities per tag
        for i in 1...5 {
            let tag = Tag(context: viewContext)
            
            tag.tagID = UUID()
            tag.tagName = "Tag #\(i)"
            
            // Activities for each tag
            for j in 1...10 {
                let randomFutureExpirationDate: Double = 86400 * Double(Int.random(in: 1...730))
                let randomPastDate: Double = -(86400 * Double.random(in: 7...180))
                let activity = CeActivity(context: viewContext)
                
                activity.activityID = UUID()
                activity.activityAddedDate = Date.now.addingTimeInterval(randomPastDate)
                activity.activityTitle = "Activity # \(j)-\(i)"
                activity.activityDescription = "A fun and educational CE activity!"
                activity.ceAwarded = Double.random(in: 0.5...4)
                if activity.ceAwarded < 2 {
                    activity.hoursOrUnits = Int16.random(in: 1...2)
                } else {
                    activity.hoursOrUnits = 1
                }
                activity.evalRating = Int16.random(in: 0...4)
                
                // MARK: Credential assignment
                activity.credentials = [sampleCredential]
                
                // MARK: CE Designation
                let designationRequest: NSFetchRequest<CeDesignation> = CeDesignation.fetchRequest()
                let allDesignations = (
                    try? viewContext.fetch(designationRequest)
                ) ?? []
                
                if allDesignations.isNotEmpty {
                    let designationCount = allDesignations.count
                    let randomIndex = Int.random(in: 0..<designationCount)
                    
                    activity.designation = allDesignations[randomIndex]
                }
                
                
                // MARK: Sample Activity Type
                let typeRequest = ActivityType.fetchRequest()
                let allTypes = (try? container.viewContext.fetch(typeRequest)) ?? []
                
                if allTypes.isNotEmpty {
                    let typecount = allTypes.count
                    let randomIndex = Int.random(in: 0..<typecount)
                    
                    activity.type = allTypes[randomIndex]
                }
                              
                // MARK: Sample Activity Format
                if activity.isLiveActivity {
                    let allFormats: [ActivityFormat] = ActivityFormat.allFormats
                    let randomFormat = allFormats.randomElement()
                    activity.activityFormat = randomFormat?.formatName
                }//: IF (isLiveActivity)
                
                // MARK: Sample Activity Expiration
                if !activity.isLiveActivity {
                    activity.activityExpires = Bool.random()
                    if activity.activityExpires {
                        activity.expirationDate = Date.now.addingTimeInterval(randomFutureExpirationDate)
                    } else {
                        activity.expirationDate = nil
                    }
                }//: IF NOT
                
                // MARK: sample activity completion
                activity.activityCompleted = Bool.random()
                if activity.activityCompleted {
                    activity.dateCompleted = Date.now.addingTimeInterval(randomPastDate)
                } else {
                    activity.dateCompleted = nil
                }
                
                activity.currentStatus = activity.expirationStatusString
                activity.cost = Double.random(in: 0...450)
                tag.addToActivities(activity)
                
                // Adding sample activity reflections IF activity has been
                // completed
                if activity.activityCompleted {
                    let reflection = ActivityReflection(context: viewContext)
                    reflection.reflectionID = UUID()
                    reflection.generalReflection = """
                    Wow, this CE course was so helpful and interesting.  Hope to take more like this one!
                    """
                    reflection.reflectionThreeMainPoints = """
                        1. Study hard
                        2. Get lots of sleep
                        3. Eat healthy
                        """
                    reflection.reflectionSurprises = """
                        No real surprises here today...
                        """
                    activity.reflection = reflection
                }
                
            } //: J LOOP
            
        } //: I LOOP
        
        try? viewContext.save()
        
        // assigning each activity to the sample renewal period
        assignActivitiesToRenewalPeriods()
        
    } //: createSampelData()
    
    // MARK: - TESTING SAMPLE DATA
    
    /// Method for creating a sample CeActivity object for testing purposes.  Most properties are
    /// assigned a reasonable default value, except for the name property.
    /// - Parameters:
    ///   - name: String representing the name of the activity - must pass in
    ///   - onDate: Date when activity starts (default: Date.futureCompletion)
    ///   - format: String value representing whether activity was done in-person or virtually (
    ///   default: "In Person")
    ///   - type: OPTIONAL ActivityType object assigned, indicating the type of activity (default: nil)
    ///   - price: Double representing the cost of the activity (default: 25.00)
    ///   - cesEarned: Double representing the amount of CEs awarded upon completion (default:
    ///   1.0)
    ///   - cesUnit: Int16 representing whether the CEs were awarded in hours (1) or units (2) (
    ///   default: 1)
    ///   - ceDesignation: OPTIONAL CeDesignation object representing the field the CEs are
    ///   designated for, such as CME or CLE (default: nil)
    ///   - specialCat: OPTIONAL SpecialCat object representing a credential-specific CE
    ///   category that the activity counts towards (default: nil)
    ///   - forCred: OPTIONAL Credential object representing a credential that the activity was
    ///   completed for (default: nil)
    ///   - registrationYN: Bool for whether registration is required for the activity or not (default:
    ///   false)
    ///   - startReminderYN: Bool for whether the user wishes to be reminded of the activity's
    ///   start time via notifications (default: false)
    ///   - endTime: Date indicating when the activity ends (default: 1 hour after the onDate default)
    ///   - expiresYN: Bool indicating whether the activity expires or not (default: false)
    ///   - expiresOn: OPTIONAL Date indicating on what day the activity expires (default: nil)
    ///   - expirationReminder: Bool indicating if the user is to be notified of the activity
    ///   expiring or not (default: false)
    ///   - completedYN: Bool indicating if the activity has been completed by the user (default:
    ///   false)
    ///   - completedOnDate: OPTIONAL Date for when the activity was completed by the
    ///   user (default: nil)
    /// - Returns: CeActivity object with properties corresponding to all argument values
    func createSampleCeActivity(
        name: String,
        onDate: Date? = Date.futureCompletion,
        format: String = "In Person",
        type: ActivityType? = nil,
        price: Double = 25.00,
        cesEarned: Double = 1.0,
        cesUnit: Int16 = 1,
        ceDesignation: CeDesignation? = nil,
        specialCat: SpecialCategory? = nil,
        forCred: Credential? = nil,
        registrationYN: Bool = false,
        startReminderYN: Bool = true,
        endTime: Date? = Date.futureCompletion.addingTimeInterval(3600),
        expiresYN: Bool = false,
        expiresOn: Date? = nil,
        expirationReminder: Bool = false,
        completedYN: Bool = false,
        completedOnDate: Date? = nil
    ) -> CeActivity {
        let context = container.viewContext
        let newActivity = CeActivity(context: context)
        newActivity.activityTitle = name
        if let startingDate = onDate {
            newActivity.startTime = startingDate
        }
        newActivity.activityFormat = format
        if let assignedType = type {
            newActivity.type = assignedType
        }
        newActivity.cost = price
        newActivity.ceAwarded = cesEarned
        newActivity.hoursOrUnits = cesUnit
        if let assignedDesignation = ceDesignation {
            newActivity.designation = assignedDesignation
        }
        if let assignedSpecialCat = specialCat {
            newActivity.specialCat = assignedSpecialCat
        }
        if let assignedCred = forCred {
            newActivity.addToCredentials(assignedCred)
        }
        newActivity.registrationRequiredYN = registrationYN
        newActivity.startReminderYN = startReminderYN
        if let activityEndsOn = endTime {
            newActivity.endTime = activityEndsOn
        }
        newActivity.activityExpires = expiresYN
        if let activityExpirationDate = expiresOn {
            newActivity.expirationDate = activityExpirationDate
        }
        newActivity.expirationReminderYN = expirationReminder
        newActivity.activityCompleted = completedYN
        if let completedActivityDate = completedOnDate {
            newActivity.dateCompleted = completedActivityDate
        }
        
        save()
        return newActivity
        
    }//: createSampleCeActivity()
    
    /// Method that creates a sample Credential object for use within testing contexts as the object is saved
    /// to the view context.
    /// - Parameters:
    ///   - ceType: Int16 value corresponding to whether the Credential measures CEs in hours (1) or
    ///   units (2); default value is 1
    ///   - cesRequired: Double representing the number of CEs required for each renewal (
    ///   default is 25)
    ///   - isActive: Bool indicating whether the credential is active or not (default is true)
    ///   - cesPerUnit: Double representing the conversion ratio of clock hours to units (default is 10)
    ///   - credType: String value representing the type of Credential (default is "license")
    /// - Returns:
    ///     - newly created Credential object
    ///
    ///   A unique name is generated for the credential object by combining the word Sample with the
    ///   uppercased credType string value along with the number of cesRequired at the end. All
    ///   parameters have a default value, so different sample credentials can be customized by changing
    ///   the defaults as needed. Method saves the object into the container's viewContext property.
    func createSampleCredential(
        ceType: Int16 = 1,
        cesRequired: Double = 25,
        isActive: Bool = true,
        cesPerUnit: Double = 10,
        credType: String = "license"
    ) -> Credential {
        let context = container.viewContext
        
        let newCredential = Credential(context: context)
        newCredential.credentialID = UUID()
        newCredential.credentialName = "Sample \(credType.uppercased()) \(cesRequired)"
        newCredential.credentialType = credType
        newCredential.isActive = isActive
        newCredential.defaultCesPerUnit = cesPerUnit
        newCredential.renewalCEsRequired = cesRequired
        newCredential.measurementDefault = ceType
        
        save()
        return newCredential
    }//: createSampleCredential
    
    /// Method that creates a sample RenewalPeriod object for use within testing contexts. Depending on
    /// whether the reinstateYN argument is true or false, a ReinstatementInfo sample object may also be
    /// created and assigned to the RenewalPeriod object.
    /// - Parameters:
    ///   - start: Starting date for the renewal period (default: renewalStartDate static (Date) property)
    ///   - end: Ending date for the renewal period (default: renewalEndDate static (Date) property)
    ///   - periodBegins: Day on which application for renewal begins for the next period (default:
    ///   renewalBeginsOnDate static Date property)
    ///   - lateFeeStart: Date on which the late fee begins to be assessed (default:
    ///   renewalLateFeeStartDate static Date property)
    ///   - lateFeeAmount: Amount charged for renewing after the late fee date (default: 100.00)
    ///   - reinstateYN: Bool indicating whether the credential has lapsed and needs to be reinstated
    ///   (default: false)
    ///   - hasLateFee: Bool indicating whether a late fee is assessed for renewing after a specific day
    ///   (default: true)
    ///   - completedYN: Bool indicating whether the credential holder has renewed or not (default: false)
    ///   - completedOn: Date on which the credential holder renewed for the next period (default:
    ///   renewalCompletedOnDate static Date property)
    ///   - credential: Optional Credential object which the renewal period is to be assigned to (default:
    ///   nil)
    /// - Returns: Created RenewalPeriod object with properties set according to the value of each
    /// argument
    ///
    /// If the reinstateYN argument is set to true, then a new ReinstatementInfo object is created and assigned
    /// to the RenewalPeriod object (via the renewal period's reinstatement relationship property).  Default
    /// values assigned to this object include:
    ///   - Total Extra CEs Required: 25.0
    ///   - Reinstatement fee: 100.00
    ///   - Reinstatement deadline: 90 days from the current date and time
    ///   - Background check required?: True
    ///   - Interview required?: True
    ///   - Interview scheduled date: 30 days from the current date and time
    ///   - Exam required? : False
    ///   These values can be changed after the creation of the RenewalPeriod by accessing its reinstatement
    ///   property.  No ReinstatementSpecialCats are created and assigned to the object in this method, so
    ///   if this is desired for testing purposes then this must be done separately.
    func createSampleRenewalPeriod(
        start: Date = .renewalStartDate,
        end: Date = .renewalEndDate,
        periodBegins: Date = .renewalBeginsOnDate,
        lateFeeStart: Date = .renewalLateFeeStartDate,
        lateFeeAmount: Double = 50,
        reinstateYN: Bool = false,
        hasLateFee: Bool = true,
        completedYN: Bool = false,
        completedOn: Date = .renewalCompletedOnDate,
        credential: Credential? = nil) -> RenewalPeriod {
            
        let context = container.viewContext
            
        let newRenewal = RenewalPeriod(context: context)
            newRenewal.periodID = UUID()
            newRenewal.periodStart = start
            newRenewal.periodEnd = end
            newRenewal.periodBeginsOn = periodBegins
            newRenewal.renewalHasLateFeeYN = hasLateFee
            newRenewal.lateFeeStartDate = lateFeeStart
            newRenewal.lateFeeAmount = lateFeeAmount
            newRenewal.reinstateCredential = reinstateYN
            newRenewal.renewalCompletedYN = completedYN
            newRenewal.renewalCompletedDate = completedOn
            
            if let cred = credential {
                newRenewal.credential = cred
            }//: IF LET
            
            if reinstateYN {
                let newReinstate = ReinstatementInfo(context: context)
                newReinstate.reinstatementID = UUID()
                newReinstate.totalExtraCEs = 25.0
                newReinstate.reinstatementFee = 100.00
                newReinstate.reinstatementDeadline = Date.now.addingTimeInterval(86400 * 90)
                newReinstate.backgroundCheckYN = true
                newReinstate.interviewYN = true
                newReinstate.interviewScheduled = Date.now.addingTimeInterval(86400 * 30)
                newReinstate.additionalTestingYN = false
                
                newRenewal.reinstatement = newReinstate
            }//: IF reinstateYN
            
            save()
            return newRenewal
    }//: createSampleRenewalPeriod
    
    /// Method for creating a sample Issuer for use within testing contexts.
    /// - Parameters:
    ///   - name: String value for whatever name the Issuer is to be called (default: "Medical Board")
    ///   - abbrev: String value for abbreviating the name (default: "MB")
    ///   - credIssued: Optional Credential property if a Credential is to be assigned to the Issuer
    /// - Returns: Issuer object with properties matching the passed in arguments
    func createSampleIssuer(
        name: String = "Medical Board",
        abbrev: String = "MB",
        credIssued: Credential? = nil
    ) -> Issuer {
        let context = container.viewContext
        
        let newIssuer = Issuer(context: context)
        newIssuer.issuerID = UUID()
        newIssuer.issuerName = name
        newIssuer.abbreviation = abbrev
        
        if let cred = credIssued {
            newIssuer.addToCredential(cred)
        }//: IF LET
        
        save()
        return newIssuer
        
    }//: createSampleIssuer()
    
    /// Method for creating a sample Special Category object for use within testing contexts.
    /// - Parameters:
    ///   - name: String value representing the name of the category (default: "Medical Ethics")
    ///   - abbrev: String value representing the abbreviated name (default: "Med Ethics")
    ///   - description: String value describing the natue of the category (default: "
    /// CEs covering issues of ethical importance")
    ///   - requiredHours: Double value representing the number of CEs required for the category (default:
    ///   2.5)
    ///   - assignedToCred: Optional Credential object to which the special category is assigned to (
    ///   default: nil)
    /// - Returns: SpecialCategory object with properties set to the value of the arguements.
    func createSampleSpecialCat(
        name: String = "Medical Ethics",
        abbrev: String = "Med Ethics",
        description: String = "CEs covering issues of ethical importance",
        requiredHours: Double = 2.5,
        assignedToCred: Credential? = nil,
    ) -> SpecialCategory {
        let context = container.viewContext
        
        let sampleSpecialCat = SpecialCategory(context: context)
        sampleSpecialCat.specialCatID = UUID()
        sampleSpecialCat.name = name
        sampleSpecialCat.abbreviation = abbrev
        sampleSpecialCat.catDescription = description
        sampleSpecialCat.requiredHours = requiredHours
        
        if let cred = assignedToCred {
            sampleSpecialCat.credential = cred
        }//: IF LET
        
        save()
        return sampleSpecialCat
    }//: createSampleSpecialCat()
    
    /// Method for creating a sample ReinstatementSpecialCat object for testing purposes.
    /// - Parameters:
    ///   - specialCat: SpecialCategory object for which CEs are required (must be passed in)
    ///   - requiredCes: Double indicating the required number of CEs (default: 1.5)
    ///   - reinstatement: ReinstatementInfo object to which this requirement affects (pass-in)
    /// - Returns: ReinstatementSpecialCat object with properties and relationships assigned to
    /// the values of each arguement.
    ///
    /// Unlike the other createSample functions, for this one both objects are NOT optional and must be
    /// first created and then passed-in to the function as arguments.
    func createSampleRSCItem(
        specialCat: SpecialCategory,
        requiredCes: Double = 1.5,
        for reinstatement: ReinstatementInfo
    ) -> ReinstatementSpecialCat {
        let context = container.viewContext
        
        let newRSCItem = ReinstatementSpecialCat(context: context)
        newRSCItem.rscID = UUID()
        newRSCItem.specialCat = specialCat
        newRSCItem.cesRequired = requiredCes
        newRSCItem.reinstatement = reinstatement
        
        save()
        return newRSCItem
    }//: createSampleRSCItem()
    
    /// Method for creating a sample DisciplinaryActionItem object for testing purposes.
    /// - Parameters:
    ///   - name: String value representing the name for the action (default: "Test Warning")
    ///   - actionTakenOn: Date value for when the action was taken (default: current date)
    ///   - type: DisciplineType enum whose String raw value is actually assigned to the object
    ///   (default: "warning")
    ///   - actionsTaken: Array of DisciplineAction enum values representing the actions taken
    ///   against the credential (default: .fines, .continuingEd)
    ///   - temporaryYN: Bool representing whether the action is temporary or permanent (default:
    ///   true)
    ///   - fineAssessed: Double representing the fine amount levied against the credential holder
    ///   (default: 100.00)
    ///   - fineDeadline: Date representing the day on which the fine must be paid (default:
    ///   .probationaryEndDate static Date constant)
    ///   - finePaid: OPTIONAL Date on which the fine was paid (default: nil)
    ///   - commServiceHours: Double representing the number of hours of community service that
    ///   is being required (default: 0.0)
    ///   - commServiceDue: OPTIONAL Date on which the community service hours must be
    ///   completed (default: nil)
    ///   - extraCeHours: Double representing the number of extra CEs the credential holder must
    ///   obtain in order to keep their credential (default: 15.0)
    ///   - ceDueOn: Date on which the extra CE is due (default: .probationaryEndDate static Date constant)
    ///   - appealYN: Bool indicating if the disciplinary action(s) have been appealed or not (default: false)
    ///   - appealDate: OPTIONAL Date on which the appeal was made (default: nil)
    ///   - credDisciplined: Credential object which is being disciplined (must be passed-in)
    /// - Returns: DisciplinaryActionItem with properties set to the values of all arguments
    ///
    /// All arguments except for the credDisciplined one have default values which can be modified if so
    /// desired during testing.
    func createSampleDAiItem(
        name: String = "Test Warning",
        actionTakenOn: Date = Date.now,
        type: DisciplineType = .warning,
        actionsTaken: [DisciplineAction] = [.fines, .continuingEd],
        temporaryYN: Bool = true,
        fineAssessed: Double = 100.00,
        fineDeadline: Date = Date.probationaryEndDate,
        finePaid: Date? = nil,
        commServiceHours: Double = 0.0,
        commServiceDue: Date? = nil,
        extraCeHours: Double = 15.0,
        ceDueOn: Date = Date.probationaryEndDate,
        appealYN: Bool = false,
        appealDate: Date? = nil,
        credDisciplined: Credential
    ) -> DisciplinaryActionItem {
        let context = container.viewContext
        
        let newDAI = DisciplinaryActionItem(context: context)
        newDAI.disciplineID = UUID()
        newDAI.actionName = name
        newDAI.actionStartDate = actionTakenOn
        newDAI.actionType = type.rawValue
        newDAI.actionsTaken = actionsTaken
        newDAI.temporaryOnly = temporaryYN
        newDAI.fineAmount = fineAssessed
        newDAI.fineDeadline = fineDeadline
        newDAI.finePaidOn = finePaid
        newDAI.commServiceHours = commServiceHours
        newDAI.commServiceDeadline = commServiceDue
        newDAI.disciplinaryCEHours = extraCeHours
        newDAI.ceDeadline = ceDueOn
        newDAI.appealedActionYN = appealYN
        newDAI.appealDate = appealDate
        newDAI.credential = credDisciplined
        
        save()
        return newDAI
    }//: createSampleDAiItem()
    
    
    
}//: DataController
