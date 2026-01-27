//
//  TagTests.swift
//  MyContinuingEdAppTests
//
//  Created by Ilum on 10/20/25.
//

import CoreData
import XCTest
@testable import MyContinuingEdApp

final class TagTests: BaseTestCase {
    
    /// Test to ensure that tags and CeActivity objects are created properly
    func testCreatingTagsAndActivities() {
        let tagCount: Int = 5
        let activitiesCount: Int = 10
        let totalActivities: Int = tagCount * activitiesCount
        
        // Create 5 tags
        for tagNum in 0..<tagCount {
            let tag = Tag(context: context)
            tag.tagName = "Tag \(tagNum))"
            
            // For each tag, create 10 activities
            for _ in 0..<activitiesCount {
                let newActivity = CeActivity(context: context)
                tag.addToActivities(newActivity)
            } //: LOOP (activity)
        }//: LOOP (tag)
        
        XCTAssertEqual(controller.count(for: Tag.fetchRequest()), tagCount, "Expected \(tagCount) tags")
        XCTAssertEqual(controller.count(for: CeActivity.fetchRequest()), totalActivities, "Expected \(totalActivities) activities")
    }//: testCreatingTagsAndActivities method
    
    func testTagDeletionSparesActivities() throws {
       // Create sample data using data controller's createSampleData(), which will create tags, CeActivities, an Issuer for
       // all activities as well as a Credential object and a renewal period
        controller.createSampleData()
        
        // Fetch all tag objects
        let tagFetch = NSFetchRequest<Tag>(entityName: "Tag")
        let tags = try context.fetch(tagFetch)
        
        // Delete the first tag
        controller.delete(tags[0])
        
        // Run tests to ensure there are only 4 tags but 50 total activities
        XCTAssertEqual(controller.count(for: Tag.fetchRequest()), 4, "Expected 4 tags after deleting one")
        XCTAssertEqual(controller.count(for: CeActivity.fetchRequest()), 50, "Expected 50 activities after deleting a tag.")
        
    }
    
    
    /// Method that tests each of the CeActivity-related computed properties in the Tag-CoreDataHelper file (Tag extension)
    /// to ensure that the correct number of CeActivities is being returned for a given Tag object.
    ///
    /// - Given: sample tag object and 15 sample CeActivity objects
    /// - When:  5 activities are marked as completed, 5 are marked as live and uncompleted,  3 marked as non-live and
    /// not yet completed, & 2 uncompleted activities that are not assigned an ActivityType object
    /// - Then:
    ///     - tagAllActivities returns a value of 15
    ///     - tagActiveActivities returns a value of 10
    ///     - tagCompletedActivities returns a value of 5
    func testTagActivityComputedProperties() {
        // Sample tag
        let sampleTag = Tag(context: context)
        sampleTag.tagID = UUID()
        sampleTag.tagName = "Test Tag"
        
        // Creating sample activity types for testing purposes
        let atStrings: [String] = [
            "Webinar", "Article", "Conference", "Podcast", "Simulation"
        ]
        for item in atStrings {
            let sampleActivityType = ActivityType(context: context)
            sampleActivityType.typeID = UUID()
            sampleActivityType.typeName = item
        }//: LOOP
        
        controller.save()
        
        let typeFetch = ActivityType.fetchRequest()
        typeFetch.sortDescriptors = [
            NSSortDescriptor(key: "typeName", ascending: true)
        ]
        let allTypes = (try? context.fetch(typeFetch)) ?? []
        
        // Creating and assigning 5 live, uncompleted activities to sample tag
        for i in 0..<5 {
            let liveType = allTypes[1]
            let activity = controller.createSampleCeActivity(name: "Live CE #\(i)", type: liveType)
            sampleTag.addToActivities(activity)
        }//: LOOP
        
        controller.save()
        
        // Creating & assigning 3 unexpired non-live activities to sample tag
        for j in 0..<3 {
            let nonLiveType = allTypes[0]
            let activity = controller.createSampleCeActivity(
                name: "Fun Article #\(j)",
                onDate: nil,
                type: nonLiveType,
                startReminderYN: false,
                endTime: nil,
                expiresYN: true,
                expiresOn: Date.futureExpiration
            )
            sampleTag.addToActivities(activity)
        }//: LOOP
        
        controller.save()
        
        // Creating & assinging 2 unspecified activities that are not
        // marked as completed
        for k in 0..<2 {
            let activity = controller.createSampleCeActivity(
                name: "Other CE Activity #\(k)",
                onDate: nil,
                endTime: nil,
            )
            sampleTag.addToActivities(activity)
        }//: LOOP
        
        controller.save()
        
        // Creating & assigning 5 completed Ce Activities
        for l in 0..<5 {
            let activity = controller.createSampleCeActivity(
                name: "Completed Activity #\(l)",
                completedYN: true,
                completedOnDate: Date.now.addingTimeInterval(-86400 * 30)
            )
            sampleTag.addToActivities(activity)
        }//: LOOP
        
        controller.save()
        
        let allActivityCount = sampleTag.tagAllActivities.count
        let activeActivityCount = sampleTag.tagActiveActivities.count
        let completedActivityCount = sampleTag.tagCompletedActivities.count
        
        // Checking totals with expected values
        XCTAssertEqual(allActivityCount, 15, "A total of 15 activities were assigned to the tag, but the returned count is \(allActivityCount)")
        XCTAssertEqual(activeActivityCount, 10, "A total of 10 activities are expected, but \(activeActivityCount) were returned.")
        XCTAssertEqual(completedActivityCount, 5, "A total of 5 activities are expected to be marked as completed, but \(completedActivityCount) were returned.")
        
    }//: testComputedTagProperties

}//: TagTests
