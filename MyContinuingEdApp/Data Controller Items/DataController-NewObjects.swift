//
//  DataController-NewObjects.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/30/25.
//

// Purpose: Due to the large size of the DataController class, separating out all functions
// related to the creation of new objects for improved code readability

import CoreData
import Foundation


extension DataController {
    // MARK: - Creating NEW objects
    /// createActivity() makes a new instance of a CeActivity object with certain default values
    /// put into place for the activity title, description, expiration date, and such...
    func createTag() throws {
        if purchaseStatus == PurchaseStatus.free.id {
            let tagFetch = Tag.fetchRequest()
            let tagCount = (try? container.viewContext.count(for: tagFetch)) ?? 0
            if tagCount < 3 {
                let newTag = Tag(context: container.viewContext)
                newTag.tagID = UUID()
                newTag.tagName = "New Tag"
                
                save()
            } else {
                throw UpgradeNeeded.maxTagsReached
            }
        } else {
            let newTag = Tag(context: container.viewContext)
            newTag.tagID = UUID()
            newTag.tagName = "New Tag"
            
            save()
        }
    }
    
    // Alternative createTag function for specifying the name
    func createTagWithName(_ name: String) throws {
        if purchaseStatus == PurchaseStatus.free.id {
            let tagFetch = Tag.fetchRequest()
            let tagCount = (try? container.viewContext.count(for: tagFetch)) ?? 0
            if tagCount < 3 {
                let newTag = Tag(context: container.viewContext)
                newTag.tagID = UUID()
                newTag.tagName = name
                
                save()
            } else {
                throw UpgradeNeeded.maxTagsReached
            }
        } else {
            
            let newTag = Tag(context: container.viewContext)
            newTag.tagID = UUID()
            newTag.tagName = name
            
            save()
        }
    }
    
    /// Method for creating a new CeActivity object and saving it to the view context.  This particular method will
    /// be used when the user's device iOS is 17 or later due to Spotlight integration requirements.
    func createActivity() throws {
        
        if purchaseStatus == PurchaseStatus.free.id {
            let activityFetch = CeActivity.fetchRequest()
            let activityCount = (try? container.viewContext.count(for: activityFetch)) ?? 0
            if activityCount >= 3 {
                throw UpgradeNeeded.maxCeActivitiesReached
            }
        }
        
        // creating new object in memory
        let newActivity = CeActivity(context: container.viewContext)
        
        // setting up initial values
        newActivity.activityID = UUID()
        newActivity.ceTitle = "New CE Activity"
        newActivity.activityAddedDate = Date.now
        newActivity.ceAwarded = 1.0
        newActivity.ceDescription = "An exciting learning opportunity!"
        newActivity.activityFormat = "Virtual"
       // TODO: Add CE Designation default
        newActivity.cost = 0.0
        newActivity.specialCat = nil
        
        // if user creates a new activity while a specific tag has been selected
        // assign that tag to the new activity
        if let tag = selectedFilter?.tag {
            newActivity.addToTags(tag)
        }
        
        // If only one Credential object exists, then automatically assign the
        // activity to that credential
        let credentialFetch = Credential.fetchRequest()
        let credentials = (try? container.viewContext.fetch(credentialFetch)) ?? []
        if credentials.count == 1 {
            newActivity.addToCredentials(credentials.first!)
        }
        
        // if the user creates a new activity while a specific renewal period has been
        // selected then the corresponding Credential object will automatically
        // be assigned to the new activity as well as the Renewal Period
        if let renewal = selectedFilter?.renewalPeriod, let credential = renewal.credential {
            newActivity.addToCredentials(credential)
            newActivity.renewal = renewal
            newActivity.hoursOrUnits = credential.measurementDefault
        }
        
        save()
        
        selectedActivity = newActivity
    }
    
    /// Method for creating a new CeActivity, saving it to the view context, and returning it as an object
    /// that can be passed into a manual Spotlight index adding function.  This particular method will only
    /// be called on devices running iOS 16 or earlier.
    /// - Returns: new CeActivity object with default values entered for key properties
    func createNewCeActivityIOs16() throws -> CeActivity {
        
        if purchaseStatus == PurchaseStatus.free.id {
            let activityFetch = CeActivity.fetchRequest()
            let activityCount = (try? container.viewContext.count(for: activityFetch)) ?? 0
            if activityCount >= 3 {
                throw UpgradeNeeded.maxCeActivitiesReached
            }
        }
        
        let newActivity = CeActivity(context: container.viewContext)
        
        newActivity.activityID = UUID()
        newActivity.ceTitle = "New CE Activity"
        newActivity.activityAddedDate = Date.now
        newActivity.ceAwarded = 1.0
        newActivity.ceDescription = "An exciting learning opportunity!"
        newActivity.activityFormat = "Virtual"
        newActivity.cost = 0.0
        newActivity.specialCat = nil
        
        // if user creates a new activity while a specific tag has been selected
        // assign that tag to the new activity
        if let tag = selectedFilter?.tag {
            newActivity.addToTags(tag)
        }
        
        // If only one Credential object exists, then automatically assign the
        // activity to that credential
        let credentialFetch = Credential.fetchRequest()
        let credentials = (try? container.viewContext.fetch(credentialFetch)) ?? []
        if credentials.count == 1 {
            newActivity.addToCredentials(credentials.first!)
        }
        
        // if the user creates a new activity while a specific renewal period has been
        // selected then the corresponding Credential object will automatically
        // be assigned to the new activity as well as the Renewal Period
        if let renewal = selectedFilter?.renewalPeriod, let credential = renewal.credential {
            newActivity.addToCredentials(credential)
            newActivity.renewal = renewal
            newActivity.hoursOrUnits = credential.measurementDefault
        }
        
        save()
        selectedActivity = newActivity
        return newActivity
    }
    
    /// Method for creating, saving, and returning a new SpecialCategory object with general default properties
    /// - Returns: SpecialCategory object
    func createNewSpecialCategory() -> SpecialCategory {
        let context = container.viewContext
        let newSpecialCategory = SpecialCategory(context: context)
        newSpecialCategory.specialCatID = UUID()
        newSpecialCategory.name = "New Special Category"
        newSpecialCategory.abbreviation = "NSC"
        newSpecialCategory.catDescription = "A new special category for things like ethics or other area that your credential's governing body may require for each renewal period."
        newSpecialCategory.requiredHours = 1.0
        
        return newSpecialCategory
        
    }//: SpecialCategory
    
    /// Creating a new renewal period for which CEs need to be earned
    func createRenewalPeriod() -> RenewalPeriod {
        let newRenewalPeriod = RenewalPeriod(context: container.viewContext)
        newRenewalPeriod.periodID = UUID()
        
        // setting up renewal period initial values
        newRenewalPeriod.periodStart = Date.now
        newRenewalPeriod.periodEnd = Date.now.addingTimeInterval(86400 * 730)
        
        save()
        return newRenewalPeriod
    }
    
    /// Creating a new reflection for a given activity. Only two default values are made:
    /// 1. The reflection date and
    /// 2. The UUID value for the id property
    func createNewActivityReflection() -> ActivityReflection {
        let newReflection = ActivityReflection(context: container.viewContext)
        
        newReflection.reflectionID = UUID()
        newReflection.dateAdded = Date.now
        
        save()
        return newReflection
    }
    
    /// Function to create a new credential object with a default name value.
    /// - Returns: Credential object with default name value
    func createNewCredential() -> Credential {
        let newCredential = Credential(context: container.viewContext)
        
        newCredential.credentialID = UUID()
        newCredential.name = "New Credential"
        newCredential.isActive = true
        // Setting the default credential type to an empty string upon creation
        // so that the user will be prompted to select a type in the picker control
        newCredential.credentialType = ""
        
        save()
        return newCredential
    }
    
    /// Function to create a new Issuer object and save it to persistent storage
    /// - Returns: Issuer object with a UUID and name property set to "New Issuer", along
    ///   with a default country of the United States and state (Alabama)
    func createNewIssuer() -> Issuer {
        let context = container.viewContext
        let newIssuer = Issuer(context: context)
        newIssuer.issuerID = UUID()
        newIssuer.issuerName = "New Issuer"
        
        // Set default country to United States
        let countryRequest: NSFetchRequest<Country> = Country.fetchRequest()
        countryRequest.predicate = NSPredicate(format: "alpha3 == %@", "USA")
        
        let defaultCountry = (try? context.fetch(countryRequest).first) ?? nil
        newIssuer.country = defaultCountry
        
        save()
        return newIssuer
    }
    
    /// Function to create a new DisciplinaryActionItem object to be associated with a given Credential. Object creation will take place
    ///  in the DisciplinaryActionListSheet or from the NoDAI view when the appropriate button is tapped.
    /// - Returns: DisciplinaryActionItem object with a default name of "New Action", auto-generated UUID, and default setting of
    ///  temporary action (temporaryOnly)
    func createNewDAI(for credential: Credential) -> DisciplinaryActionItem {
        let context = container.viewContext
        let newDAI = DisciplinaryActionItem(context: context)
        newDAI.disciplineID = UUID()
        newDAI.actionName = "New Action"
        newDAI.temporaryOnly = true
        newDAI.credential = credential
        
        save()
        return newDAI
    }
    
    /// Method for creating a new ReinstatementInfo object with values assigned to two properties: reinstatementID and renewal (with the
    /// renewal argument value).
    /// - Parameter renewal: RenewalPeriod for which credential reinstatement is needed
    /// - Returns: ReinstatementInfo object
    func createNewReinstatementInfo(renewal: RenewalPeriod) -> ReinstatementInfo {
        let context = container.viewContext
        
        let newRInfo = ReinstatementInfo(context: context)
        newRInfo.reinstatementID = UUID()
        newRInfo.renewal = renewal
        
        save()
        return newRInfo
    }//: createNewReinstatementInfo
    
    /// Method for creating a new ReinstatementSpecialCat object with values assigned to both relationship properties (reinstatement & specialCat)
    /// as well as the id property (rscID).
    /// - Parameters:
    ///   - reinstatement: ReinstatementInfo object for which this object is to be assigned to
    ///   - specialCat: SpecialCategory for which extra CEs must be earned for
    /// - Returns: ReinstatementSpecialCat object
    ///
    /// The only property that needs to be modified after creating this object is the cesRequired one, which the user can input the exact number
    /// of CEs that are required for this category in order to reinstate their credential.
    ///
    /// Whenever a credential lapses and must be renewed, part of the process may involve extra CE requirements set by the credential's
    /// governing body.  In addition to requiring a certain number of CE hours overall (on any topic related to the credential), the governing body
    /// may also specify that the credential holder get so many CEs in specific areas such as ethics, law, or other area applicable to the
    /// credential.  Such requirements are likely already part of the regular renewal process, so if the user is a paid user of the app and added
    /// SpecialCategory objects to a Credential, then they can be assigned to the ReinstatementSpecCat along with however many CEs the
    /// licensing board requires.
    func createNewReinstatementSpecCat(reinstatement: ReinstatementInfo, specialCat: SpecialCategory) -> ReinstatementSpecialCat {
        let context = container.viewContext
        
        let newRSpecCat = ReinstatementSpecialCat(context: context)
        newRSpecCat.rscID = UUID()
        newRSpecCat.reinstatement = reinstatement
        newRSpecCat.specialCat = specialCat
        
        save()
        return newRSpecCat
    }//: createNewReinstatementSpecCat()
    
    
}//: DataController
