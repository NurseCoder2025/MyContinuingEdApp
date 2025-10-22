//
//  DevelopmentTest.swift
//  MyContinuingEdAppTests
//
//  Created by Ilum on 10/21/25.
//

import CoreData
import XCTest
@testable import MyContinuingEdApp

final class DevelopmentTest: BaseTestCase {
    
    /// Test to determine whether the Data Controller's createSampleData() method creates the right number of objects as intended
    func testSampleDataCreation() throws {
        controller.createSampleData()
        
        // Counting the various types of sample data that were created
        let allTags = controller.count(for: Tag.fetchRequest())
        let allActivities = controller.count(for: CeActivity.fetchRequest())
        let allRenewalPeriods = controller.count(for: RenewalPeriod.fetchRequest())
        let allIssuers = controller.count(for: Issuer.fetchRequest())
        let allCredentials = controller.count(for: Credential.fetchRequest())
        
        XCTAssertEqual(allTags, 5, "There should be just 5 tags but in reality there are \(allTags)) tags.")
        
        XCTAssertEqual(allActivities, 50, "There should be 50 activities (10 per tag), but instead there are \(allActivities) activities")
        
        XCTAssertEqual(allRenewalPeriods, 1, "There should be a single renewal period, but instead there are \(allRenewalPeriods) periods")
        
        XCTAssertEqual(allIssuers, 1, "There should be just one issuer, but instead there are \(allIssuers) issuers.")
        
        XCTAssertEqual(allCredentials, 1, "There should be just one Credential, but instead there are \(allCredentials) Credentials.")
        
        controller.deleteAll()
    }//: testSampleDataCreation()
    
    /// Test to determine whether the createSampleData() method correctly creates and assigns a single ActivityReflection object for every
    /// sample activity that was randomly designated as completed.
    func testSampleDataActivityReflectionNumber() throws {
        controller.createSampleData()
        
        // Get the number of completed activities
        let activityFetch = NSFetchRequest<CeActivity>(entityName: "CeActivity")
        activityFetch.predicate = NSPredicate(format: "activityCompleted == true")
        let activities = try context.fetch(activityFetch)
        let completedCount = activities.count
        
        // Get the number of Activity Reflections
        let numberOfReflections = controller.count(for: ActivityReflection.fetchRequest())
        
        XCTAssertEqual(completedCount, numberOfReflections, "A total of \(completedCount) activities were finished, but only \(numberOfReflections) Activity Reflections were created.")
        
        controller.deleteAll()
    } //: testSampleDataActivityReflectionNumber()
    
    
    /// Test to determine that the Data Controller's deleteAll() method actually deletes all sample data that was created by the createSampleData() method
    func testDeleteAllSampleData() throws {
        controller.createSampleData()
        
        // Deleting all objects
        controller.deleteAll()
        
        // Retrieving object count for all sample data items for final check
        let allTags = controller.count(for: Tag.fetchRequest())
        let allActivities = controller.count(for: CeActivity.fetchRequest())
        let allRenewalPeriods = controller.count(for: RenewalPeriod.fetchRequest())
        let allIssuers = controller.count(for: Issuer.fetchRequest())
        let allCredentials = controller.count(for: Credential.fetchRequest())
        let allReflections = controller.count(for: ActivityReflection.fetchRequest())
        
        // Checking for a count of 0 for each sample data item
        XCTAssert(allTags == 0, "There are still \(allTags) Tag objects remaining.")
        XCTAssert(allActivities == 0, "There are still \(allActivities) CeActivity objects remaining.")
        XCTAssert(allRenewalPeriods == 0, "There are still \(allRenewalPeriods) RenewalPeriod objects remaining.")
        XCTAssert(allIssuers == 0, "There are still \(allIssuers) issuer objects remaining.")
        XCTAssert(allCredentials == 0, "There are still \(allCredentials) Credential objects remaining.")
        XCTAssert(allReflections == 0, "There are still \(allReflections) ActivityReflection objects remaining.")
        
    }//: testDeleteAllSampleData()
    
    
    /// Test to determine that every sample activity has been assigned an evaluation rating # between 0 - 4 (as an Int16 Core Data type) on creation
    func testSampleActivitiesHaveRating()  throws {
        controller.createSampleData()
        
        // Fetch all activities
        let activityFetch = NSFetchRequest<CeActivity>(entityName: "CeActivity")
        let allActivities = try context.fetch(activityFetch)
        
        // Check that each activity has a rating
        for activity in allActivities {
            XCTAssert(Int(activity.evalRating) >= 0 && Int(activity.evalRating) <= 4, "\(activity.activityTitle ?? "Unknown") has no rating.")
        }//: LOOP
        
        controller.deleteAll()
        
    }//: testSampleActivitiesHaveRating()
    
    
    /// Test to determine that creating a new tag will not create new activites that go along with it (using the data controller's createTag methods)
    func testNewTagsHaveNoActivities() throws {
        // Creating sample tags
        for num in 0..<10 {
            controller.createTagWithName("Test Tag #\(num)")
        }//: LOOP
        
        let tagFetch = NSFetchRequest<Tag>(entityName: "Tag")
        let allTags = try context.fetch(tagFetch)
        
        for tag in allTags {
            let activities = tag.activity as? Set<CeActivity> ?? []
            let activityCount = activities.count
            XCTAssert(activityCount == 0, "\(tag.tagName ?? "Unknown") has \(activityCount) activities.")
        }//: LOOP
        
        controller.deleteAll()
    }//: testNewTagsHaveNoActivities()
    
    
    // MARK: - SAMPLE DATA TESTING

}
