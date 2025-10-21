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
                tag.addToActivity(newActivity)
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
    

}//: TagTests
