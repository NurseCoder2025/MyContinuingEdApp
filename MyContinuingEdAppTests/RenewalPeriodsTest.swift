//
//  RenewalPeriodsTest.swift
//  MyContinuingEdAppTests
//
//  Created by Ilum on 10/21/25.
//

import CoreData
import XCTest
@testable import MyContinuingEdApp

final class RenewalPeriodsTest: BaseTestCase {
    
    /// Test to determine that deleting a RenewalPeriod object still leaves all CeActivity objects that were assigned to it saved in persistent storage as the
    /// deletion rule is currently set to nullify
    func testRenewalDeleteLeavesActivities() throws {
        controller.createSampleData()
        
        let activitiesFetch = NSFetchRequest<CeActivity>(entityName: "CeActivity")
        let activities = try context.fetch(activitiesFetch)
        let activitiesCount = activities.count  // should be a total of 50 activities
        XCTAssertTrue(activitiesCount == 50, "There should be 50 total activities")
        
        let renewalsRequest = NSFetchRequest<RenewalPeriod>(entityName: "RenewalPeriod")
        let renewals = try context.fetch(renewalsRequest)
        XCTAssertTrue(renewals.count == 1, "There shoud be just 1 sample Renewal Period.")
        
        let renewalToDelete = renewals[0]
        
        controller.delete(renewalToDelete)
        
        XCTAssertTrue(activitiesCount == 50, "There should still be 50 CE activities after deleting the renewal period.")
        controller.deleteAll()
    }//: testRenewalDeleteLeavesActivities()
    
    
    /// Test to determine that deleting a RenewalPeriod object still leaves whatever Credential object was assigned to it in place in persistent storage as the
    /// delete rule is nullify
    func testRenewalDeleteLeavesCredential() throws {
        controller.createSampleData()
        
        let renewalsRequest = NSFetchRequest<RenewalPeriod>(entityName: "RenewalPeriod")
        let renewals = try context.fetch(renewalsRequest)
        XCTAssertTrue(renewals.count == 1, "There shoud be just 1 sample Renewal Period.")
        
        let renewalToDelete = renewals[0]
        
        controller.delete(renewalToDelete)
        
        let credentialFetch = NSFetchRequest<Credential>(entityName: "Credential")
        let credentials = try context.fetch(credentialFetch)
        let credentialCount = credentials.count
        
        XCTAssertTrue(credentialCount == 1, "There should still be 1 Credential after deleting the renewal period.")
        controller.deleteAll()
        
    }//: testRenewalDeleteLeavesCredential()
    
    
    /// Test to determine that upon deleting a Renewal Period object and then adding a new one (for the same Credential) will auto-assign all completed
    /// CeActivities to it.
    func testDeleteAndAddingNewRenewalAutoAssignsActivities() throws {
        controller.createSampleData()
        
        // Getting the count of all completed CeActivities
        let activitiesFetch = NSFetchRequest<CeActivity>(entityName: "CeActivity")
        activitiesFetch.predicate = NSPredicate(format: "activityCompleted == true")
        let allCompletedActivities = try context.fetch(activitiesFetch)
        let allCompletedCount = allCompletedActivities.count
        
        // Deleting the sample renewal period
        let renewalsRequest = NSFetchRequest<RenewalPeriod>(entityName: "RenewalPeriod")
        let renewals = try context.fetch(renewalsRequest)
        XCTAssertTrue(renewals.count == 1, "There shoud be just 1 sample Renewal Period.")
        
        let renewalToDelete = renewals[0]
        
        // Getting the number of completed activities assigned to the Renewal Period before deletion
        let completedActivities = renewalToDelete.cesCompleted as? Set<CeActivity> ?? []
        let completedCount = completedActivities.count
        
        // Making sure that the # of completed activities connected to the Renewal Period is the same as the total
        // number of completed activities
        XCTAssertEqual(
            allCompletedCount,
            completedCount,
            "The number of completed activities (\(completedCount)) assigned to the Renewal Period should be the same as the total number of completed activities (\(allCompletedCount))."
        )
        
        controller.delete(renewalToDelete)
        
        // Creating a new sample renewal period
        // Fetching the credential created by the createSampleData() in order to assign it
        // to the new renewal period object
        let credentialsFetch = NSFetchRequest<Credential>(entityName: "Credential")
        let credentials = try context.fetch(credentialsFetch)
        let sampleCredential = credentials[0]
        
        // Creating the new RenewalPeriod object
        let newRenewal = controller.createRenewalPeriod()
        // newRenewal has a startDate of Date.now & endDate of Date.now + 730 days
        
        // Since the createSampleData() method creates a unique starting date value of January 1st of
        // the current year, then in order for the test to work properly the same start date should
        // be assigned, which will override the createRenewalPeriod method's startDate assignment.
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let janFirst = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1))!
        
        newRenewal.periodStart = janFirst
        newRenewal.periodEnd = janFirst.addingTimeInterval(86400 * 730)
        
        // Assigning sample Credential object to newRenewal
        newRenewal.credential = sampleCredential
        
        // Assigning all completed CE activities to the new renewal period
        controller.assignActivitiesToRenewalPeriods()
        
        // Retrieving the number of completed activities assigned to newRenewal
        let newRenewalCompletedActivities = newRenewal.cesCompleted as? Set<CeActivity> ?? []
        let newRenewalCompletedCount = newRenewalCompletedActivities.count
        
        XCTAssertEqual(
            allCompletedCount,
            newRenewalCompletedCount,
            "The number of completed activities (\(newRenewalCompletedCount)) assigned to the new Renewal Period should be the same as the total number of completed activities (\(allCompletedCount))."
        )
        
        controller.deleteAll()
        
    }//: testDeleteAndAddingNewRenewalAutoAssignsActivities()
    
}
