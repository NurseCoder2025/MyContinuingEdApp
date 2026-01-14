//
//  CeActivityTests.swift
//  MyContinuingEdAppTests
//
//  Created by Ilum on 1/13/26.
//

import CoreData
import XCTest
@testable import MyContinuingEdApp

final class CeActivityTests: BaseTestCase {
    
    /// Test to determine if the CeActivity computed property isLiveActivity returns the right
    /// value properly or not.
    /// - Parameters:
    ///     - Given: 2 sample CeActivities
    ///     - When : one activity is assigned a live ActivityType, and another is assigned a non-live
    ///     ActivityType
    ///     - Then: activity with live ActivityType returns true and the other returns false
    func testActivityIsLiveProperty() throws {
        // loading all ActivityTypes
        let activityTypes = controller.allActivityTypes
        XCTAssert(activityTypes.isNotEmpty, "It was expected for there to be activity types in the array, but none were found.")
        XCTAssertTrue(activityTypes.count == 9, "9 ActivityType objects were expected, but only \(activityTypes.count) were found.")
        
        let activityNames = activityTypes.map(\.activityTypeName).joined(separator: ", ")
       print(activityNames)
        
        let liveActivities = activityTypes.filter { $0.typeName != "Recording" && $0.typeName != "Article" }
        XCTAssertEqual(liveActivities.count, 7, "7 live ActivityType objects were expected, but only \(liveActivities.count) were found.")
        
        // Creating sample activity with live ActivityType
        let sampleLiveActivity = controller.createSampleCeActivity(name: "Live Sample Activity")
        sampleLiveActivity.type = activityTypes[1]
        controller.save()
        
        if let sampleActType = sampleLiveActivity.type, let satName = sampleActType.typeName {
            print(satName)
        }
        
        // Creating sample non-live activity
        let sampleNonLiveActivity = controller.createSampleCeActivity(
            name: "Non-Live Sample Activity",
            onDate: nil,
            format: "N/A",
            startReminderYN: false,
            endTime: nil
        )
        
        // Making sure there are two CeActivity objects saved
        XCTAssertEqual(try context.count(for: NSFetchRequest<CeActivity>(entityName: "CeActivity")), 2)
        
        XCTAssertTrue(sampleLiveActivity.isLiveActivity,"Expected true as liveActivity is live, but it returned false somehow.")
        XCTAssertFalse(sampleNonLiveActivity.isLiveActivity)
    }//: testActivityIsLiveProperty()

}//: CLASS
