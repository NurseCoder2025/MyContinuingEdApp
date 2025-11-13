//
//  ChartDataExtraction.swift
//  MyContinuingEdAppTests
//
//  Created by Ilum on 11/10/25.
//

import CoreData
import XCTest
@testable import MyContinuingEdApp

final class ChartDataExtraction: BaseTestCase {
    
    func testCesRemainingCalculation() throws {
        // Create sample Credential
        let sampleCred: Credential = Credential(context: context)
        sampleCred.name = "Test Cred"
        sampleCred.renewalPeriodLength = 24
        sampleCred.renewalCEsRequired = 40
        sampleCred.isActive = true
        
        // Create sample RenewalPeriod
        let sampleRenewal: RenewalPeriod = RenewalPeriod(context: context)
        sampleRenewal.periodStart = Date.renewalStartDate
        sampleRenewal.periodEnd = Date.renewalEndDate
        sampleRenewal.credential = sampleCred
        
        controller.save()
        
        // Create sample CEs in RenewalPeriod
        // Creating 10 sample CES with 1.0 contact hours each, for a total of 10.0 hours
        for i in 0..<10 {
            let sampleCE: CeActivity = CeActivity(context: context)
            sampleCE.ceTitle = "Sample Activity \(i)"
            sampleCE.ceAwarded = 1.0
            sampleCE.hoursOrUnits = 1
            sampleCE.activityCompleted = true
            sampleCE.dateCompleted = Date.now.addingTimeInterval((86400 * Double(i)) + 20)
            sampleCE.renewal = sampleRenewal
            controller.save()
        }//: LOOP
        
        // Call calculateRemainingTotalCEsFor function & assign returned tuple
        // Fetch renewal period object and pass it in to the calculateRemainingTotalCEsFor method
        let renewalFetch = RenewalPeriod.fetchRequest()
                
        if let renewals = (try? context.fetch(renewalFetch)) {
            guard renewals.isNotEmpty else {
                XCTFail("No RenewalPeriods were fetched. This test requires at least one RenewalPeriod to function correctly.")
                return
            }
            
            let testRenewal = renewals.first!
            
            let renewalRemainingCes = controller.calculateRemainingTotalCEsFor(renewal: testRenewal)
            let cesToEarn = renewalRemainingCes.ces
            let renewalIsCurrentYN = renewalRemainingCes.current
            let ceUnits = renewalRemainingCes.unit
            
            // Check result
            XCTAssert(
                cesToEarn == 30.0,
                "A total of 10 contact hours was earned, so there should be 30 remaining. However, there are \(cesToEarn) hours remaining."
            )
            XCTAssertTrue(renewalIsCurrentYN == true, "The sample renewal period should be identified as a current renewal period - double check renewal period dates.")
            XCTAssert(ceUnits == 1, "The units for CEs earned were given as hours or 1.  That should be the unit portion of the returned tuple.")
            
        }//: IF LET
        
    }//: testCesRemainingCalculation()

    
    /// This test is designed to ensure that the DataController's calculateRemainingSpecialCECatHoursFor() method properly computes the
    /// total number of CE clock hours or units (depending on the Special Category setting) that still need to be completed for a given Renwal
    /// Period. Test also checks that the function skips over any CeActivities that are not designated for any special categories.
    func testCalculateRemainingSpecialCECatHoursFor() throws {
        // Create sample Credential
        let sampleCred: Credential = Credential(context: context)
        sampleCred.name = "Test Cred"
        sampleCred.renewalPeriodLength = 24
        sampleCred.renewalCEsRequired = 40
        sampleCred.measurementDefault = 1
        sampleCred.isActive = true
        
        // Create sample RenewalPeriod
        let sampleRenewal: RenewalPeriod = RenewalPeriod(context: context)
        sampleRenewal.periodStart = Date.renewalStartDate
        sampleRenewal.periodEnd = Date.renewalEndDate
        sampleRenewal.credential = sampleCred
        
        // Create sample special CE category
        let sampleSpecialCat = SpecialCategory(context: context)
        sampleSpecialCat.name = "Test Special Cat"
        sampleSpecialCat.measurementDefault = 1
        sampleSpecialCat.requiredHours = 1
        sampleSpecialCat.credential = sampleCred
        
        controller.save()
        
        // Create sample CEs for the RenewalPeriod
        // Creating 10 sample CES with 1.0 contact hours each, for a total of 10.0 hours
        // However, none of them counted towards the special category requirement
        for i in 0..<10 {
            let sampleCE: CeActivity = CeActivity(context: context)
            sampleCE.ceTitle = "Sample Activity \(i)"
            sampleCE.ceAwarded = 1.0
            sampleCE.hoursOrUnits = 1
            sampleCE.activityCompleted = true
            sampleCE.dateCompleted = Date.now.addingTimeInterval((86400 * Double(i)) + 20)
            sampleCE.renewal = sampleRenewal
            controller.save()
        }//: LOOP
        
        // Fetch renewal period object and pass it in to the calculateRemainingTotalCEsFor method
        let renewalFetch = RenewalPeriod.fetchRequest()
            
        // Checking to make sure that the function returns an empty dictionary when all entered activities
        // do NOT count towards the credential's special renewal category
        if let renewals = (try? context.fetch(renewalFetch)) {
            guard renewals.isNotEmpty else {
                XCTFail("No RenewalPeriods were fetched. This test requires at least one RenewalPeriod to function correctly.")
                return
            }
            let testRenewal = renewals.first!
            let specialCatHoursRemaining = controller.calculateRemainingSpecialCECatHoursFor(renewal: testRenewal)
            XCTAssert(specialCatHoursRemaining.isEmpty)
        }//: IF LET
        
        // Creating a CeActivity that DOES count towards the special category requirement
        let specialCatCe = CeActivity(context: context)
        specialCatCe.ceTitle = "Special Cat Test Activity"
        specialCatCe.ceAwarded = 0.5
        specialCatCe.hoursOrUnits = 1
        specialCatCe.activityCompleted = true
        specialCatCe.dateCompleted = Date.now.addingTimeInterval(86400 * 45)
        specialCatCe.renewal = sampleRenewal
        specialCatCe.specialCat = sampleSpecialCat
        controller.save()
        
        // Now check to see that the calculateRemainingSpecialCECatHoursFor method works by returning
        // a dictionary with the key "Special Cat Test Activity" and the value of 0.5
        if let renewals = (try? context.fetch(renewalFetch)) {
            guard renewals.isNotEmpty else {
                XCTFail("No RenewalPeriods were fetched. This test requires at least one RenewalPeriod to function correctly.")
                return
            }
            
            let testRenewal = renewals.first!
            let specialCatHoursRemaining = controller.calculateRemainingSpecialCECatHoursFor(renewal: testRenewal)
            let returnedHours = specialCatHoursRemaining["Test Special Cat"] ?? 0.0
            print(specialCatHoursRemaining)
            XCTAssertEqual(specialCatHoursRemaining.count, 1)
            XCTAssert(specialCatHoursRemaining["Test Special Cat"] == 0.5, "The returned value of special CE cat hours remaining should be 0.5, but \(returnedHours) were returned instead.")
               
        }//: IF LET
        
        
    }//: testCalculateRemainingSpecialCECAtHoursFor()
   
    
    /// Test that checks whether the testCalculateCEsEarnedByMonth function finds and adds up all CEs earned for every given month represented
    /// in the data in terms of clock hours.  Given a sample data set of 60 CeActivities spaced over the course of 12 months (5 per month)
    /// that meet the inclusion criteria for the function and have a ceAwarded value of 1.0 clock hours, the test should pass when the function
    /// returns a dictionary consisting of 12 keys (one per month) and a total of 5.0 hours for each key.
    func testCalculateCEsEarnedByMonth() throws {
        // Since the function this test checks only fetches completed CeActivities and does not need any
        // related relationships (Credential, RenewalPeriod), only sample CeActivity objects will be
        // created in this test.
        for month in 1...12 {
            let calendar = Calendar.current
            for day in 1...5 {
                let sampleActivity = CeActivity(context: context)
                sampleActivity.ceTitle = "CE # \(day)"
                sampleActivity.activityCompleted = true
                sampleActivity.ceAwarded = 1.0
                sampleActivity.hoursOrUnits = 1
                
                // Creating an assigned completion date for the current month
                let randomizedDate = DateComponents(year: 2024, month: month, day: day + Int.random(in: 1...15))
                if let date = calendar.date(from: randomizedDate) {
                    sampleActivity.dateCompleted = date
                } else  {
                    let assignedPastDateAmount = Double(-(86400 * 500))
                    sampleActivity.dateCompleted = Date.now.addingTimeInterval(assignedPastDateAmount)
                }
            }//: LOOP (activities per month)
        }//: LOOP (calendar months)
        
        controller.save()
        
        let earnedCEs = controller.calculateCEsEarnedByMonth()
        guard earnedCEs.isNotEmpty else {
            XCTFail("Expected 12 months of CE earnings, but got 0")
            return
        }
        
        // Checking result of function
        XCTAssert(earnedCEs.count == 12, "Expected 12 months of CE earnings, but got \(earnedCEs.count)")
        
        for key in earnedCEs.keys {
          XCTAssert(earnedCEs[key] == 5.0, "Expected 5.0 CE hours for month \(key), but got \(earnedCEs[key] ?? 0.0)")
        }
        
    }//: testCalculateCEsEarnedByMonth()
    
    
    /// Test that follows the same basic pattern as testCalculateCEsEarnedByMonth, but configures the sample activities to have CEs awarded in
    /// terms of UNITS versus clock hours.  Given a sample credential with a custom hours to unit conversion ratio and activities with units awarded,
    /// the test should return the proper number of clock hours for each month in the data set.
    func testCalculateCEsEarnedByMonthWithUnits() throws {
        // Since this function tests whether activities entered with CEs as units (versus clock hours), a
        // sample credential will be created with a custom hours per unit ratio to test whether the conversion
        // is done correctly
        let sampleCred = Credential(context: context)
        sampleCred.name = "Test Cred"
        sampleCred.measurementDefault = 2
        sampleCred.defaultCesPerUnit = 20
        
        controller.save()
    
        for month in 1...12 {
            let calendar = Calendar.current
            for day in 1...5 {
                let sampleActivity = CeActivity(context: context)
                sampleActivity.ceTitle = "CE # \(day)"
                sampleActivity.activityCompleted = true
                sampleActivity.ceAwarded = 0.05
                sampleActivity.hoursOrUnits = 2
                
                // Creating an assigned completion date for the current month
                let randomizedDate = DateComponents(year: 2024, month: month, day: day + Int.random(in: 1...15))
                if let date = calendar.date(from: randomizedDate) {
                    sampleActivity.dateCompleted = date
                } else  {
                    let assignedPastDateAmount = Double(-(86400 * 500))
                    sampleActivity.dateCompleted = Date.now.addingTimeInterval(assignedPastDateAmount)
                }
                
                sampleActivity.addToCredentials(sampleCred)
            }//: LOOP (activities per month)
        }//: LOOP (calendar months)
        
        controller.save()
        
        let earnedCEs = controller.calculateCEsEarnedByMonth()
        guard earnedCEs.isNotEmpty else {
            XCTFail("Expected 12 months of CE earnings, but got 0")
            return
        }
        
        // Checking result of function
        XCTAssert(earnedCEs.count == 12, "Expected 12 months of CE earnings, but got \(earnedCEs.count)")
        
        for key in earnedCEs.keys {
          XCTAssert(earnedCEs[key] == 5.0, "Expected 5.0 CE hours for month \(key), but got \(earnedCEs[key] ?? 0.0)")
        }
        
    }//: testCalculateCEsEarnedByMonthWithUnits()
    
}//: ChartDataExtraction
