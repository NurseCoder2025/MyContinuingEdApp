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
    
    
    /// Use this test to ensure that notifications are created for CeActivity objects which meet the inclusion
    /// criteria (has an expiration date, not yet completed by the user, and is marked for notifications by the
    /// user).  For the purpose of this test, two sample CE activities were created with one meeting the criteria
    /// and the other not meeting them.  A successful test should produce a single notification.
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
    
    
    /// Use this test to ensure that notifications are properly scheduled for any RenewalPeriod objects
    /// which meet the criteria for notification scheduling (renewal end date approaching & late fee period
    /// starting).  A successful test should generate a total of 4 notifications given the sample RenewalPeriod
    /// object created within the test.
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
            $0.identifier.starts(with:  String("\(sampleRenewal.renewalPeriodUID.uuidString)-\(NotificationType.renewalEnding.rawValue)"))
        }, "Sample Renewal Period notification should be scheduled")
        
        print("---------------------------OBJECT PRINTOUT---------------------------------------")
        for request in requests {
            print("Object: \(request.identifier)")
            print("Notification title: \(request.content.title)")
            print("Notice body: \(request.content.body)")
            
            // Checking to make sure each notification is scheduled to appear at the
            // proper time (30 days ahead and 7 days ahead)
            if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                let seconds = trigger.timeInterval
                
                let scheduledDate = Date()
                let triggerDate = scheduledDate.addingTimeInterval(seconds)
                let formattedDate = triggerDate.formatted(date: .abbreviated, time: .omitted)
                
                print("Notification scheduled to appear on: \(formattedDate)")
            }
        }
        
        XCTAssertTrue(requests.count == 4, "Should have 4 pending requests, but there are actually \(requests.count)")
        
        pendingExpectation.fulfill( )
        
        await fulfillment(of: [pendingExpectation], timeout: 5)
        
    }//: testRenewalPeriodEndingNotifications()
    
    
    /// Use this test for ensuring that notifications are properly scheduled for any credential disciplinary
    /// actions that meet the inclusion criteria for notification scheduling.  This test creates a single
    /// DisciplinaryActionItem (DAI) object which meets all four criteria and should generate 8 total notifications.
    func testDAINotifications() async throws {
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        
        // Creating sample credential to which DAIs can be assigned to
        let sampleCred = Credential(context: context)
        sampleCred.credentialID = UUID()
        sampleCred.credentialName = "Test Cred"
        
        // Creating sample DAI item that meets notification criteria for all
        // notifications
        let sampleDAI = DisciplinaryActionItem(context: context)
        sampleDAI.disciplineID = UUID()
        sampleDAI.actionName = "Sample Credential Warning"
        sampleDAI.temporaryOnly = true
        sampleDAI.actionEndDate = calendar.date(byAdding: .day, value: 90, to: Date())!
        sampleDAI.commServiceHours = 50
        sampleDAI.commServiceDeadline = calendar.date(byAdding: .day, value: 60, to: Date())!
        sampleDAI.fineAmount = 250.00
        sampleDAI.fineDeadline = calendar.date(byAdding: .day, value: 75, to: Date())!
        sampleDAI.disciplinaryCEHours = 25
        sampleDAI.ceDeadline = calendar.date(byAdding: .day, value: 85, to: Date())!
        sampleDAI.credential = sampleCred
        
        controller.save()
        
        await controller.updateAllReminders()
        
        let pendingExpectation = self.expectation(description: "Pending Notifications")
        let requests = await center.pendingNotificationRequests()
        
        // Disciplinary Action ending notifications
        XCTAssertTrue(requests.contains {
            $0.identifier.starts(with:  String("\(sampleDAI.daiDisciplineID.uuidString)-\(NotificationType.disciplineEnding.rawValue)"))
        }, "Disciplinary Action Ending notification should be scheduled")
        
        // Community service hours deadline notifications
        XCTAssertTrue(requests.contains {
            $0.identifier.starts(with:  String("\(sampleDAI.daiDisciplineID.uuidString)-\(NotificationType.serviceDeadlineApproaching.rawValue)"))
        }, "Community service deadline notification should be scheduled")
        
        // Fine deadline notifications
        XCTAssertTrue(requests.contains {
            $0.identifier.starts(with:  String("\(sampleDAI.daiDisciplineID.uuidString)-\(NotificationType.fineDeadlineApproaching.rawValue)"))
        }, "Disciplinary fine deadline notification should be scheduled")
        
        // Mandated CE hours deadline notifications
        XCTAssertTrue(requests.contains {
            $0.identifier.starts(with:  String("\(sampleDAI.daiDisciplineID.uuidString)-\(NotificationType.ceHoursDeadlineApproaching.rawValue)"))
        }, "Disciplinary Action Ending notification should be scheduled")
        
        
        print("---------------------------OBJECT PRINTOUT---------------------------------------")
        for request in requests {
            print("Object: \(request.identifier)")
            print("Notification title: \(request.content.title)")
            print("Notice body: \(request.content.body)")
            
            // Checking to make sure each notification is scheduled to appear at the
            // proper time (30 days ahead and 7 days ahead)
            if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                let seconds = trigger.timeInterval
                
                let scheduledDate = Date()
                let triggerDate = scheduledDate.addingTimeInterval(seconds)
                let formattedDate = triggerDate.formatted(date: .abbreviated, time: .omitted)
                
                print("Notification scheduled to appear on: \(formattedDate)")
            }
        }//: LOOP
        
        // Verifying total number of notifications
        XCTAssertTrue(requests.count == 8, "There should be 8 notifications scheduled, but there are \(requests.count) instead.")
        
        pendingExpectation.fulfill()
        
        await fulfillment(of: [pendingExpectation], timeout: 10)
        
    }//: testDAINotifications()
    

}//: NotificationsTest
