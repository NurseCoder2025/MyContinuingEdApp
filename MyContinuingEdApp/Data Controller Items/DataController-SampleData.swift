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
    // MARK: - CREATE SAMPLE DATA
    
    // Creating sample data for testing and previewing
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
                activity.ceAwarded = Double.random(in: 0.5...10)
                activity.hoursOrUnits = Int16.random(in: 1...2)
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
                
                // MARK: Sample Activity Format
                let allFormats: [ActivityFormat] = ActivityFormat.allFormats
                let randomFormat = allFormats.randomElement()
                activity.activityFormat = randomFormat?.formatName
                
                // MARK: Sample Activity Type
                let typeRequest = ActivityType.fetchRequest()
                let allTypes = (try? container.viewContext.fetch(typeRequest)) ?? []
                
                if allTypes.isNotEmpty {
                    let typecount = allTypes.count
                    let randomIndex = Int.random(in: 0..<typecount)
                    
                    activity.type = allTypes[randomIndex]
                }
                              
                // MARK: Sample Activity Expiration
                activity.activityExpires = Bool.random()
                if activity.activityExpires {
                    activity.expirationDate = Date.now.addingTimeInterval(randomFutureExpirationDate)
                } else {
                    activity.expirationDate = nil
                }
                
                // MARK: sample activity completion
                activity.activityCompleted = Bool.random()
                if activity.activityCompleted {
                    activity.dateCompleted = Date.now.addingTimeInterval(randomPastDate)
                } else {
                    activity.dateCompleted = nil
                }
                
                activity.currentStatus = activity.expirationStatusString
                activity.cost = Double.random(in: 0...450)
                activity.activityFormat = "Virtual"
                activity.whatILearned = "A lot!"
                tag.addToActivity(activity)
                
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
        assignActivitiesToRenewalPeriod()
        
    } //: createSampelData()
    
}//: DataController
