//
//  ComputationsTest.swift
//  MyContinuingEdAppTests
//
//  Created by Ilum on 1/6/26.
//

import Foundation
import CoreData
import XCTest
@testable import MyContinuingEdApp

final class ComputationsTest: BaseTestCase {
    
    /// Test to ensure that the DataController method for calculating the total number of CE clock hours required for a given
    /// RenewalPeriod works properly and returns the correct numerical value.
    ///
    ///
    /// Given: Sample Credential, sample RenewalPeriod with the following values:
    ///     - Scenario #1:  Credential requiring 30 clock hours for the renewal
    ///     - Scenario #2:  Credential requiring 2.5 UNITS for the renewal, with 10 CE hours per unit
    ///     - Scenario #3:  Credential requiring 20 clock hours for renewal
    /// When:
    ///     - Scenario #1: NO reinstatement hours required
    ///     - Scenario #2: NO reinstatement hours required
    ///     - Scenario #3: 20 reinstatement hours required
    /// Then:
    ///     - Scenario #1:  Returns 30.0
    ///     - Scenario #2: Returns 25.0
    ///     - Scenario #3: Returns 40.0
    func testTotalRequiredCEsFor() throws {
        // MARK: Scenario #1
        let firstSampleCred = Credential(context: context)
        firstSampleCred.credentialName = "Sample Credential 1"
        firstSampleCred.measurementDefault = Int16(1)
        firstSampleCred.renewalCEsRequired = 30.0
        
        let firstRenewal = RenewalPeriod(context: context)
        firstRenewal.reinstateCredential = false
        // Adding this value to check that the reinstateCredential is checked properly
        firstRenewal.reinstatementHours = 50.0
        firstRenewal.periodStart = Date.renewalStartDate
        firstRenewal.periodEnd = Date.renewalEndDate
        firstRenewal.credential = firstSampleCred
        
        controller.save()
        
        XCTAssertFalse(firstRenewal.reinstateCredential)
        let scenarioOneHours = controller.calculateTotalRequiredCEsFor(renewal: firstRenewal)
        XCTAssertEqual(scenarioOneHours, 30.0)
        
        // MARK: Scenario #2
        let secondSampleCred = Credential(context: context)
        secondSampleCred.credentialName = "Sample Credential 2"
        secondSampleCred.measurementDefault = Int16(2)
        secondSampleCred.defaultCesPerUnit = 10.0
        secondSampleCred.renewalCEsRequired = 2.5
        
        let secondRenewal = RenewalPeriod(context: context)
        secondRenewal.reinstateCredential = false
        secondRenewal.reinstatementHours = 50.0
        secondRenewal.periodStart = Date.renewalStartDate
        secondRenewal.periodEnd = Date.renewalEndDate
        secondRenewal.credential = secondSampleCred
        
        controller.save()
        
        XCTAssertFalse(secondRenewal.reinstateCredential)
        let scenarioTwoHours = controller.calculateTotalRequiredCEsFor(renewal: secondRenewal)
        XCTAssertEqual(scenarioTwoHours, 25.0)
        
        // MARK: Scenario #3
        let thirdSampleCred = Credential(context: context)
        thirdSampleCred.credentialName = "Sample Credential 3"
        thirdSampleCred.measurementDefault = Int16(1)
        thirdSampleCred.renewalCEsRequired = 20.0
        
        let thirdRenewal = RenewalPeriod(context: context)
        thirdRenewal.reinstateCredential = true
        thirdRenewal.reinstatementHours = 20.0
        thirdRenewal.periodStart = Date.renewalStartDate
        thirdRenewal.periodEnd = Date.renewalStartDate
        thirdRenewal.credential = thirdSampleCred
        
        controller.save()
        
        XCTAssertTrue(thirdRenewal.reinstateCredential)
        let scenarioThreeHours = controller.calculateTotalRequiredCEsFor(renewal: thirdRenewal)
        XCTAssertEqual(scenarioThreeHours, 40.0)
        
    }//: testTotalRequiredCEsFor()
    
    /// Test for ensuring that the renewalPeriodIsCurrentYN method in DataController returns the correct value for a given
    /// renewal period.
    ///
    /// Given:  two sample renewal periods
    /// When: one period is current and the other is NOT current
    /// Then:  function should return true for the current period and false for the other
    func testRenewalPeriodIsCurrentYN() throws {
        let firstSamplePeriod = RenewalPeriod(context: context)
        firstSamplePeriod.periodID = UUID()
        firstSamplePeriod.periodStart = Date.renewalStartDate
        firstSamplePeriod.periodEnd = Date.renewalEndDate
        
        let secondSamplePeriod = RenewalPeriod(context: context)
        secondSamplePeriod.periodID = UUID()
        let distantDateModifier = TimeInterval(86400 * 1000)
        secondSamplePeriod.periodStart = Date.distantPast
        secondSamplePeriod.periodEnd = Date.distantPast.addingTimeInterval(distantDateModifier)
        
        controller.save()
        
        let allCurrentRenewals = controller.getCurrentRenewalPeriods()
        XCTAssertEqual(allCurrentRenewals.count, 1)
        
        let firstSamplePeriodIsCurrent = controller.renewalPeriodIsCurrentYN(firstSamplePeriod)
        let secondSamplePeriodIsCurrent = controller.renewalPeriodIsCurrentYN(secondSamplePeriod)
        
        XCTAssertTrue(firstSamplePeriodIsCurrent)
        XCTAssertFalse(secondSamplePeriodIsCurrent)
        
    }//: testRenewalPeriodIsCurrentYN()
    
    
    /// Test to ensure that the DataController method for calculating the amount of CEs earned
    /// (in clock hours) for a given renewal period does so correctly.
    ///
    /// Given: sample credential, sample renewal period, 5 sample CE activities
    /// When: 3 of the activities are completed and two are in hours (5.0), one in units (0.75)
    /// Then: correct CE clock hour total of 17.5 clock hours is returned
    ///
    /// The method that is tested happens to invoke two sub-methods also in DataController:
    /// calculateTotalRequiredCEsFor(renewal) and calculateRemainingTotalCEsFor(renewal).
    func testCalculateRenewalPeriodCEsEarned() throws {
        let sampleCredential = Credential(context: context)
        sampleCredential.credentialID = UUID()
        sampleCredential.credentialName = "Test Credential"
        sampleCredential.measurementDefault = 1
        sampleCredential.renewalCEsRequired = 100
        
        let samplePeriod = RenewalPeriod(context: context)
        samplePeriod.periodID = UUID()
        samplePeriod.periodStart = Date.renewalStartDate
        samplePeriod.periodEnd = Date.renewalEndDate
        samplePeriod.reinstateCredential = false
        samplePeriod.credential = sampleCredential
        
        controller.save()
        
        // CE activities that have hours that should be added up
        for i in 1...3 {
            let sampleCe = CeActivity(context: context)
            sampleCe.activityID = UUID()
            sampleCe.ceTitle = "CE Activity \(i)"
            sampleCe.activityCompleted = true
            sampleCe.ceAwarded = (i < 3 ? 5.0 : 0.75)
            sampleCe.hoursOrUnits = (i < 3 ? 1 : 2)
            sampleCe.renewal = samplePeriod
            controller.save()
        }//: LOOP
        
        // CE activities that have hours which should NOT be added up
        for _ in 1...2 {
            let testCe = CeActivity(context: context)
            testCe.activityID = UUID()
            testCe.activityCompleted = false
            testCe.ceAwarded = 35.0
            testCe.hoursOrUnits = 1
            testCe.renewal = samplePeriod
            controller.save()
        }//: LOOP
        
        let requiredCes = controller.calculateTotalRequiredCEsFor(renewal: samplePeriod)
        XCTAssert(requiredCes == 100, "100 CEs were expected, but \(requiredCes) was returned")
        
        let remainingCes = controller.calculateRemainingTotalCEsFor(renewal: samplePeriod)
        XCTAssert(remainingCes == 82.5, "82.5 CEs were expected, but \(remainingCes) was returned")
        
        let awardedCes = controller.calculateRenewalPeriodCEsEarned(renewal: samplePeriod)
        XCTAssert(awardedCes == 17.5, "A total of 17.5 hours was expected, but \(awardedCes) was returned")
       
        
    }//: testCalculateRenewalPeriodCEsFor()
    

}//: ComputationsTest
