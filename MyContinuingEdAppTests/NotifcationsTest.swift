//
//  NotifcationsTest.swift
//  MyContinuingEdAppTests
//
//  Created by Ilum on 10/31/25.
//

import CoreData
@testable import MyContinuingEdApp
import XCTest

final class NotifcationsTest: BaseTestCase {

    func testLocalNotificationSetup() {
        let center = UNUserNotificationCenter.current()
        let expectation = self.expectation(description: "Notification Authorization")
        
        //  Requesting authorization
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            XCTAssertNil(error)
            XCTAssertTrue(granted)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5)
        
        // Scheduling a notification
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "Test", content: content, trigger: trigger)
        
        center.add(request)
        
        // Verifying notification is scheduled
        let pendingExpectation = self.expectation(description: "Pending Notification")
        center.getPendingNotificationRequests { requests in
            XCTAssertTrue(requests.contains {
                $0.identifier == "Test"
            }, "Notification should be scheduled")
            
            pendingExpectation.fulfill()
            
        } //: getPendingNotifcationRequests()
        
        wait(for: [pendingExpectation], timeout: 5)
        
    }//: testLocalNotificationSetup
    
    
    
    /// The purpose of this test is to make sure that the scheduleExpiringCEsNotification and child functions work properly in
    /// creating a notifcation for a test CeActivity that meets all of the criteria for notification creation.
    func testExpiringActivityNotification() async throws {
        let center = UNUserNotificationCenter.current()
        
        // Create sample activity that meets criteria
        let calendar = Calendar.current
        let expDate = calendar.startOfDay(for: Date()).addingTimeInterval(86400*15)
        let sampleActivity = CeActivity(context: context)
            sampleActivity.activityID = UUID()
            sampleActivity.activityTitle = "Test Activity"
            sampleActivity.activityCompleted = false
            sampleActivity.activityExpires = true
            sampleActivity.expirationDate = expDate
            sampleActivity.expirationReminderYN = true
        
        controller.save()
        
        let enteredCes = controller.fetchUpcomingExpiringCeActivities()
        XCTAssert(enteredCes.contains(sampleActivity), "The sample activity was not found in the activity fetch")
        
        await controller.scheduleExpiringCEsNotifications( )
        
        let pendingExpectation = self.expectation(description: "Pending Notification")
        let requests = await center.pendingNotificationRequests()
        // TEST results here
        XCTAssertTrue(requests.contains {
            $0.content.title == "Test Activity"
        }, "Test Activity notification should be scheduled")
        
        pendingExpectation.fulfill( )
        
        await fulfillment(of: [pendingExpectation], timeout: 5)
        
    }//: testExpiringActivityNotification
    
    
    
    /// This test ensures that only CeActivities that meet the criteria for expiration notification creation actually have notifications created for
    /// them.  In this test two test objects are created: one that meets the criteria and a second which doesn't.
    func testExpiringAndNonExpirinActivityNotifications() async throws {
        let center = UNUserNotificationCenter.current()
        
        // Create sample activity that meets criteria
        let calendar = Calendar.current
        let expDate = calendar.startOfDay(for: Date()).addingTimeInterval(86400*45)
        let sampleActivity = CeActivity(context: context)
            sampleActivity.activityID = UUID()
            sampleActivity.activityTitle = "Test Activity"
            sampleActivity.activityCompleted = false
            sampleActivity.activityExpires = true
            sampleActivity.expirationDate = expDate
            sampleActivity.expirationReminderYN = true
        
        
        // Creating sample activity that does NOT meet criteria
        let nonExpiringActivity = CeActivity(context: context)
            nonExpiringActivity.activityID = UUID()
            nonExpiringActivity.activityTitle = "Non Expiring Activity"
            nonExpiringActivity.activityCompleted = false
            nonExpiringActivity.activityExpires = false
            nonExpiringActivity.expirationDate = expDate
            nonExpiringActivity.expirationReminderYN = true
        
        controller.save()
        
                
        let enteredCes = controller.fetchUpcomingExpiringCeActivities()
        XCTAssert(enteredCes.contains(sampleActivity), "The sample activity was not found in the activity fetch")
        
        await controller.scheduleExpiringCEsNotifications( )
        
        let pendingExpectation = self.expectation(description: "Pending Notification")
        let requests = await center.pendingNotificationRequests()
        // TEST results here
        XCTAssertTrue(requests.contains {
            $0.content.title == "Test Activity"
        }, "Test Activity notification should be scheduled")
        
        XCTAssertFalse(requests.contains {
            $0.content.title == "Non Expiring Activity"
        }, "Non Expiring Activity notification should NOT be scheduled")
        
        pendingExpectation.fulfill( )
        
        await fulfillment(of: [pendingExpectation], timeout: 5)
        
        
    }//: testExpiringAndNonExpiringActivityNotifications()
    
    
    func testUpdateAllRemindersForCeActivities() async throws {
        let center = UNUserNotificationCenter.current()
        
        // Create sample activity that meets criteria
        let calendar = Calendar.current
        let expDate = calendar.startOfDay(for: Date()).addingTimeInterval(86400*45)
        let sampleActivity = CeActivity(context: context)
            sampleActivity.activityID = UUID()
            sampleActivity.activityTitle = "Test Activity"
            sampleActivity.activityCompleted = false
            sampleActivity.activityExpires = true
            sampleActivity.expirationDate = expDate
            sampleActivity.expirationReminderYN = true
        
        
        // Creating sample activity that does NOT meet criteria
        let nonExpiringActivity = CeActivity(context: context)
            nonExpiringActivity.activityID = UUID()
            nonExpiringActivity.activityTitle = "Non Expiring Activity"
            nonExpiringActivity.activityCompleted = false
            nonExpiringActivity.activityExpires = false
            nonExpiringActivity.expirationDate = expDate
            nonExpiringActivity.expirationReminderYN = true
        
        controller.save()
        
        await controller.updateAllReminders()
       
        let pendingExpectation = self.expectation(description: "Pending Notification")
        let requests = await center.pendingNotificationRequests()
        // TEST results here
        XCTAssertTrue(requests.contains {
            $0.content.title == "Test Activity"
        }, "Test Activity notification should be scheduled")
        
        XCTAssertFalse(requests.contains {
            $0.content.title == "Non Expiring Activity"
        }, "Non Expiring Activity notification should NOT be scheduled")
        
        pendingExpectation.fulfill( )
        
        await fulfillment(of: [pendingExpectation], timeout: 5)
    }//: testUpdateAllRemindersForCeActivities
    
    
    
    func testRenewalPeriodEndingNotifications() async throws {
         let center = UNUserNotificationCenter.current()
         let calendar = Calendar.current
        
        let sampleCred = Credential(context: context)
        sampleCred.credentialID = UUID()
        sampleCred.credentialName = "Test Cred"
        
        // For the purposes of this test, creating a renewal period that has both an end
        // date close to the current date as well as a late fee starting date so both
        // reminders are tested
        let sampleRenewal = RenewalPeriod(context: context)
        sampleRenewal.periodID = UUID()
        sampleRenewal.periodStart = calendar.startOfDay(for: Date.renewalStartDate)
        sampleRenewal.periodEnd = calendar.startOfDay(for: Date.renewalEndDate)
        sampleRenewal.lateFeeStartDate = calendar.startOfDay(
            for: Date.renewalStartDate.addingTimeInterval(86400 * 548))
        sampleRenewal.lateFeeAmount = 75.00
        sampleRenewal.credential = sampleCred
        
        controller.save()
        
        await controller.updateAllReminders()
        
        let pendingExpectation = self.expectation(description: "Pending Notification")
        let requests = await center.pendingNotificationRequests()
        
        // TEST results here
        // Identifier for each object should be: "\(uuIDString)-\(notificationType.rawValue)"
        XCTAssertTrue(requests.contains {
            $0.identifier == String("\(sampleRenewal.renewalPeriodUID.uuidString)-\(NotificationType.renewalEnding.rawValue)")
        }, "Sample Renewal Period notification should be scheduled")
        
        print("---------------------------OBJECT PRINTOUT---------------------------------------")
        for request in requests {
            print("Object: \(request.identifier)")
            print("Notification title: \(request.content.title)")
        }
        
        XCTAssertTrue(requests.count == 4, "Should have 4 pending requests, but there are actually \(requests.count)")
        
        pendingExpectation.fulfill( )
        
        await fulfillment(of: [pendingExpectation], timeout: 5)
        
    }//: testRenewalPeriodEndingNotifications()
    

}//: NotificationsTest
