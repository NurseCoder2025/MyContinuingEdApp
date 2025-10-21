//
//  AwardTests.swift
//  MyContinuingEdAppTests
//
//  Created by Ilum on 10/20/25.
//

import CoreData
import XCTest
@testable import MyContinuingEdApp

final class AwardTests: BaseTestCase {
    let awards = Award.allAwards
    
    /// This tests whether the string ID property for each award object is equal to its name in order to ensure that every award object is created
    /// with a unique ID as it conforms to Identifiable
    func testAwardIDEqualsName() {
        for award in awards {
            XCTAssertEqual(award.id, award.name, "The award ID should be equal to the award name.")
        }
    }
   
    
    /// Tests whether any award objects exist for a completely new user who shouldn't have earned any awards at this point.
    func testNewUserHasZeroAwards() {
        for award in awards {
            XCTAssertEqual(controller.hasEarned(award: award), false, "A new user should not have earned any awards yet")
        }
    }
    
    
    /// Tests whether the user actually earns an award for earning so many CE contact hours
    func testEarningContactHoursEarnsAwards() {
        let hourThresholds: [Int] = [1, 15, 25, 45, 65, 85, 100, 150]
        
        for (index, hours) in hourThresholds.enumerated() {
            var activities = [CeActivity]()
            
            for _ in 0..<hours {
                let activity = CeActivity(context: context)
                activity.ceAwarded = 1.0
                activities.append(activity)
            }//: LOOP
            
            let hoursEarned = activities.map {$0.ceAwarded}
            var earnedHours: Double = 0.0
            for hours in hoursEarned {
                earnedHours += hours
            }
            
            let matchingAward = awards.filter { award in
                award.criterion == "CEs" && award.value == Int(earnedHours)
            }
            
            XCTAssertEqual(Int(earnedHours), matchingAward[0].value, "The user earned \(earnedHours) contact hours and should have earned the \(awards[index].name) award.")
            controller.deleteAll()
            
        }//: LOOP
            
    }//: testEarningContactHoursEarnsAwards()
    
    /// Test for determining whether the user will actually receive an award after completing so many CE activities
    func testCompletingCEsEarnsAwards() {
        let cesToComplete = [1, 10, 20, 30, 50, 75, 100, 150]
        
        for (_, value) in cesToComplete.enumerated() {
            var activities = [CeActivity]()
            
            for _ in 0..<value {
                let activity = CeActivity(context: context)
                activity.activityCompleted = true
                activities.append(activity)
            }//: LOOP
            
            let matchingAward = awards.filter { award in
                award.criterion == "completed" && award.value == value
            }
            
            XCTAssertEqual(activities.count, matchingAward[0].value, "The user completed \(activities.count) of the \(matchingAward[0].value) CEs required to earn \(matchingAward[0].name)")
            controller.deleteAll()
        }//: LOOP
        
    }//: testCompletingCEsEarnsAwards()
    
    
    /// Test for determining whether adding a specified number of tags will earn the user the respective award
    func testAddingTagsEarnsAwards() {
        let tagThresholds: [Int] = [1, 10, 50]
        
        for (_, value) in tagThresholds.enumerated() {
            var allTags: [Tag] = []
            
            for _ in 0..<value {
                let tag = Tag(context: context)
                allTags.append(tag)
            }//: LOOP
            
            let matchingAward = awards.filter { award in
                award.criterion == "tags" && award.value == value
            }
            
            XCTAssertEqual(allTags.count, matchingAward[0].value, "The user created \(allTags.count) tags and so should have earned the \(matchingAward[0].name) award")
            controller.deleteAll()
            
        }//: LOOP
        
    }//: testAddingTagsEarnsAwards()
    
    
    /// Test for determining whether loving a specified number of CE activities (20) will earn the user the reward
    func testLovingActivitiesEarnsAward() {
        let lovedNumber: Int = 20
        var activities: [CeActivity] = []
        
        for _ in 0..<lovedNumber {
            let activity = CeActivity(context: context)
            activity.evalRating = Int16(4)
            activities.append(activity)
        }//: LOOP
        
        let matchingAward = awards.filter { award in
            award.criterion == "loved" && award.value == lovedNumber
        }
        
        XCTAssertEqual(activities.count, Int(matchingAward[0].value), "The user has loved \(activities.count) CEs and so should have earned the \(matchingAward[0].name) award")
        controller.deleteAll()
        
    }//: testLovingActivitiesEarnsAward()
    
    
    /// Test for determining if the user will earn an award after rating a specified number of CE activities as 'interesting' (int value of 3)
    func testRatingActivitiesInterestingEarnsAward() {
        let interestingNumber: Int = 10
        var activities: [CeActivity] = []
        
        for _ in 0..<interestingNumber {
            let activity = CeActivity(context: context)
            activity.evalRating = Int16(3)
            activities.append(activity)
        } //: LOOP
        
        let matchingAward = awards.filter { award in
            award.criterion == "howInteresting" && award.value == 10
        }
        
        XCTAssertEqual(activities.count, matchingAward[0].value, "The user rated \(activities.count) as interesting, so should have earned the \(matchingAward[0].name) award")
        controller.deleteAll( )
        
    }//: testRatingActivitiesInterestingEarnsAward()
    
    
    /// Test that determines whether the user will earn awards for completing a specified number of activity reflections
    func testCompletingActivityReflectionsEarnsAwards() {
        let reflectionThresholds: [Int] = [20, 45, 75, 100]
        
        for (_, threshold) in reflectionThresholds.enumerated() {
            var allReflections: [ActivityReflection] = []
            for _ in 0..<threshold {
                let reflection = ActivityReflection(context: context)
                reflection.completedYN = true
                allReflections.append(reflection)
            }//: LOOP
            
            let matchingAward = awards.filter { award in
                award.criterion == "reflections" && award.value == threshold
            }
            
            XCTAssertEqual(allReflections.count, matchingAward[0].value, "The user completed \(allReflections.count) activity reflections, so should have earned the \(matchingAward[0].name) award")
            controller.deleteAll()
            
        }//: LOOP
        
    }//: testCompletingActivityReflectionsEarnsAwards()
    
    
    /// Test that determins whether the user will earn awards for documenting surprising things that they learned during a CE activity in the activity reflection.
    func testLearningSuprisingFactEarnsAwards() {
        let surpriseThresholds: [Int] = [1, 10, 25]
        
        for (_, value) in surpriseThresholds.enumerated() {
            var allReflections: [ActivityReflection] = []
            
            for _ in 0..<value {
                let reflection = ActivityReflection(context: context)
                reflection.surpriseEntered = true
                allReflections.append(reflection)
            }//: LOOP
            
            let matchingAward = awards.filter { award in
                award.criterion == "surprises" && award.value == value
            }
            
            XCTAssertEqual(allReflections.count, matchingAward[0].value, "The user documented being surprised by something new \(allReflections.count) times, so should have earned the \(matchingAward[0].name) award")
            controller.deleteAll()
           
        }//: LOOP
        
        
        
    }//: testLearningSuprisingFactEarnsAwards()
}
