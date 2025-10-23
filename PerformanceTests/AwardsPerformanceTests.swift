//
//  AwardsPerformanceTests.swift
//  PerformanceTests
//
//  Created by Ilum on 10/22/25.
//

import CoreData
import XCTest
@testable import MyContinuingEdApp

final class AwardsPerformanceTests: BasePerformanceTest {
    
    /// This test evaluates the performance of the app when there are a large number of CeActivities entered and many, many award objects that
    /// are earned by the user (725!).
    ///
    /// All sample data is created 150 times and an array of 25 joined, decoded Award arrays from the Award.json file
    /// is used for setting up the measurement.  The enlarged awards array is filtered through the data controller's hasEarned(award) method and the
    /// time it takes for that to complete provides the performance number.
    ///
    /// **Given:** A large set of sample data (150 x 5 tags x 10 activities) + 725 Award objects
    ///
    /// **When:** the Awards array is created
    ///
    /// **Then:** Ensure that there are exactlly 725 awards and measure the time it takes to filter out all earned awards
    func testAwardEarningPerformance() {
        // Test setup
        for _ in 0..<150 {
            controller.createSampleData()
        }//: LOOP
        
        let awards = Array(repeating: Award.allAwards, count: 25).joined()
        XCTAssertEqual(awards.count, 725, "This checks that the # of awards is constant. Update this number if you add or remove awards.")
        
        measure {
            _ = awards.filter { controller.hasEarned(award: $0)}
        }
        
    }//: testAwardEarningPerformance

}
