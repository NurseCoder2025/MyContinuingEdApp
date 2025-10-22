//
//  CredentialTest.swift
//  MyContinuingEdAppTests
//
//  Created by Ilum on 10/21/25.
//

import CoreData
import XCTest
@testable import MyContinuingEdApp

final class CredentialTest: BaseTestCase {
    
    /// Test to confirm that deleting a Credential object does NOT delete the Issuer object associated with it, as the delete rule is set to nullify
    func testDeletingCredentialLeavesIssuer() throws {
        // Generate sample data for testing
        controller.createSampleData()
        // The createSampleData method does not create an Issuer object, so using the general
        // createNewIssuer method instead
        let sampleIssuer = controller.createNewIssuer()
        
        // Fetching the credential and assigning the sampleIssuer to it
        let credentialFetch = NSFetchRequest<Credential>(entityName: "Credential")
        let fetchedCredential: Credential = (try context.fetch(credentialFetch)).first!
        fetchedCredential.issuer = sampleIssuer
        
        // Deleting Credential object
        controller.delete(fetchedCredential)
        
        // Checking that the issuer object is still in existence
        let issuerFetch = NSFetchRequest<Issuer>(entityName: "Issuer")
        let fetchedIssuer: Issuer? = (try context.fetch(issuerFetch)).first
        XCTAssertNotNil(fetchedIssuer)
        
        controller.deleteAll()
    }//: testDeletingCredentialLeavesIssuer()
    
    
    /// Test to confirm that deleting a Credential object will in turn delete ALL related DisciplinaryActionItems connected to that object.  The
    /// Credential-DisciplinaryActionItem relationship is the only one in the data model where the deletion rule is set to "cascade".
    func testDeletingCredentialDeletesAllDAIs() throws {
        // Generating sample data
        controller.createSampleData()
        
        // Getting the sample Credential for passing into the sample DisciplinaryActionItems (DAI)
        let credentialFetch = NSFetchRequest<Credential>(entityName: "Credential")
        let fetchedCredential: Credential = (try context.fetch(credentialFetch)).first!
        
        // Creating several DisciplinaryActionItems
        var sampleDAIs: [DisciplinaryActionItem] = []
        for _ in 0..<5 {
            let sampleDAI = controller.createNewDAI(for: fetchedCredential)
            sampleDAIs.append(sampleDAI)
        }//: LOOP
        
        // Ensuring that there are 5 sample DAIs associated with the sample credential
        let sampleCredsDAIs = fetchedCredential.disciplinaryActions as? Set<DisciplinaryActionItem> ?? []
        let sampleCredsDAIsCount = sampleCredsDAIs.count
        XCTAssertEqual(sampleCredsDAIsCount, 5, "There should be 5 disciplinary action objects associated with the sample credential, but in reality there are \(sampleCredsDAIsCount).")
        
        
        // Deleting Credential object
        controller.delete(fetchedCredential)
        
        // Checking to make sure all DAIs have been deleted
        let allDAIFetch: NSFetchRequest<DisciplinaryActionItem> = DisciplinaryActionItem.fetchRequest()
        let allDAIs: [DisciplinaryActionItem] = try context.fetch(allDAIFetch)
        
        XCTAssertTrue(allDAIs.isEmpty, "All DAIs should have been deleted but there are \(allDAIs.count) remaining.")
        
        controller.deleteAll()
        
    }//: testDeletingCredentialDeletesAllDAIS()
    
    
    /// Test for confirming two things: 1) deleting the Credential object will delete all associated RenewalPeriods and 2) all CeActivities associated
    /// with the RenewalPeriod will remain (all activities are separately associated with one or more Credential objects)
    func testDeletingCredentialDeletesRenewalsButLeavesActivities() throws {
        // Generate sample data, which will generate 5 tags, 50 activities, 1 Credential
        // and 1 RenewalPeriod object
        controller.createSampleData()
        
        // Getting the sample credential object
        let credFetch = NSFetchRequest<Credential>(entityName: "Credential")
        let fetchedCred: Credential = (try context.fetch(credFetch)).first!
        
        // Getting the sample renewal period object
        let renewalFetch = NSFetchRequest<RenewalPeriod>(entityName: "RenewalPeriod")
        // Making fetchedRenewal an optional so it can be used later after the credential is deleted
        let fetchedRenewal: RenewalPeriod? = (try context.fetch(renewalFetch)).first
        
        // Making sure there is a renewal period in fetchedRenewal
        XCTAssertNotNil(fetchedRenewal)
        
        // Getting the pre-delete activity count
        let activitiesFetch = NSFetchRequest<CeActivity>(entityName: "CeActivity")
        let fetchedActivities: [CeActivity] = try context.fetch(activitiesFetch)
        let activityCount = fetchedActivities.count
        
        XCTAssert(activityCount == 50, "The number of sample activities should be 50 but is \(activityCount) instead.")
        
        // Deleting the Credential object
        controller.delete(fetchedCred)
        
       // Checking to see if the renewal period object was deleted
        let postDeleteRenewalFetch = NSFetchRequest<RenewalPeriod>(entityName: "RenewalPeriod")
        let fetchedPostDeleteRenewal: RenewalPeriod? = (try context.fetch(postDeleteRenewalFetch)).first
        
        XCTAssertNil(fetchedPostDeleteRenewal, "The renewal period should have been deleted but remains in place.")
        
        // Checking # of CE activities post Credential deletion
        let postDeleteActivitiesFetch = NSFetchRequest<CeActivity>(entityName: "CeActivity")
        let postDeleteActivities = try context.fetch(postDeleteActivitiesFetch)
        let postDeleteActivitiesCount = postDeleteActivities.count
        
        XCTAssertEqual(postDeleteActivitiesCount, activityCount, "The number of sample activities should be 50 but is \(postDeleteActivitiesCount) instead.")
        
        controller.deleteAll()
        
    }//: testDeletingCredentialDeletesRenewalsButLeavesActivities()

}
