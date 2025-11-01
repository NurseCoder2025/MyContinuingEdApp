//
//  DataController-Notifications.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/29/25.
//

// Purpose: Extension on DataController to hold all code needed for the
// creation and removal of timed notifications in the app.

/*
 Default notifications (& settings)
  - uncompleted CE activity about to expire
  - RenewalPeriod ending
  - RenewalPeriod late fee date
  - DAI end date
  - DAI community service due date
  - DAI fine deadline
  - DAI ce hours deadline
 */

import CoreData
import Foundation
import UserNotifications


extension DataController {

    // MARK: - Notification Configuration and Scheduling
    /// PRIVATE method for returning whether authorization for a nontification has been given.  Called within the addReminder function
    /// as a way to determine if the user has enabled notifications for the app or not.
    /// - Returns: Boolean representing whether "yes" or "no"
    private func requestNotifications() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        
    }
    
    // MARK: SCHEDULE SINGLE NOTIFICATION
    /// PRIVATE function for creating a notification of any kind for any type of object in the app.  The notification trigger is
    /// determined by the amount of time remaining between the present date value and the triggerDate value.
    /// - Parameters:
    ///   - object: any entity with important date properties like CeActivity, RenwalPeriod, DisciplinaryActionItem
    ///   - title: String representing the title of the notification to the user
    ///   - body: Text of what the user needs to be notified about (days until renewal, more hours to earn, etc.)
    ///   - triggerDate: Date on which the notification will be triggered and shown to the user
    private func scheduleSingleNotification(
        for object: NSManagedObject,
        title: String,
        body: String,
        triggerDate: Date,
        notificationType: NotificationType,
        noticeNum: Int
    ) async throws {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Making sure that the number of seconds being passed in to the trigger is a positive number
        // only and not negative. In running a test it was discovered that negative values were being
        // passed in and that was causing a fatal error.
        let interval = triggerDate.timeIntervalSinceNow
        print("trigger date time interval: \(triggerDate.timeIntervalSinceNow)")
        guard interval > 0 else {
            print("Trigger date is now in the past. Notification will not be scheduled.")
            return
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerDate.timeIntervalSinceNow, repeats: false)
        
        // Getting the UUID string for the object being passed in so it can be part
        // of the unique identifier.  Decided to use the UUID instead of objectID
        // to make testing notification functions easier.
        if let uuIDString = getUUIDString(for: object) {
            let identifier = "\(uuIDString)-\(notificationType.rawValue).\(noticeNum)"
            
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            return try await center.add(request)
        }
        
    }//: scheduleSingleNotification()
    
    // MARK: ADD REMINDER
    /// The public function for adding notifications to various objects in the app.  Structured generally so each
    /// notification can be customized based on the object and specific circumstances surrounding the notification.
    /// - Parameters:
    ///   - object: object with a key date property the user should be aware of, like CeActivity & RenewalPeriod
    ///   - title: title for the notification
    ///   - body: text describing details relvant to the notification
    ///   - onDate: when the notification is to be shown to the user
    /// - Returns: True or False, based on whether the notifcation was successfully scheduled or not
    private func addReminder<T: NSManagedObject>(
        for object: T,
        title: String,
        body: String,
        onDate: Date,
        notificationType: NotificationType,
        noticeNum: Int
    ) async{
        do {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            
            switch settings.authorizationStatus {
            case .notDetermined:
                // more code to come
                let isAuthorized = try await requestNotifications()
                
                if isAuthorized {
                    try await scheduleSingleNotification(for: object, title: title, body: body, triggerDate: onDate, notificationType: notificationType, noticeNum: noticeNum)
                } else {
                    print("Sorry, but notifications are not yet enabled")
                }
                
            case .authorized:
                try await scheduleSingleNotification(
                    for: object,
                    title: title,
                    body: body,
                    triggerDate: onDate,
                    notificationType: notificationType,
                    noticeNum: noticeNum
                )
            default:
                print("Unable to add notification - check settings.")
                return
            }//: SWITCH
            return
        } catch {
            print("Other notification error: \(error.localizedDescription)")
            return
        }
    }//: addReminder()
    
    
    /// Method that removes all reminders/notifications assigned to any specific  object, but because
    /// the unique id for each notification is based on both the object's UUID string value and NotificationType
    /// enum (raw value), the notification type must also be passed in.
    /// - Parameter object: NSManagedObject whose notifications are to be removed
    func removeReminders<T: NSManagedObject>(for object: T, type: NotificationType) {
        let center = UNUserNotificationCenter.current()
        
        if let objIDString = getUUIDString(for: object) {
            let identifier = "\(objIDString)-\(type.rawValue)"
            
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
        }//: IF LET
    }//: removeReminders(object)
    
    
    /// This method removes any pending notifications for all eligible objects in the UNNotificationCenter.  Specifically,
    /// those objects are CeActivities set to be expiring in the near future, any RenewalPeriods that are about to end, and
    /// any DisciplinaryActionItems that are temporary or have a requirement with a time-sensitive deadline (ex. for extra CE hours
    /// or community service requirement).
    func removeAllReminders() async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
    }//: removeAllReminders
    
    func updateAllReminders() async {
        await removeAllReminders()
        
        await scheduleExpiringCEsNotifications()
        await scheduleRenewalsEndingNotifications()
        await scheduleDisciplinaryActionNotifications()
        
    }//: updateAllReminders
    
    
    // MARK: - Object Fetching for Notifications
    
    // Fetch all uncompleted CeActivities that are about to expire within a set period
    /// This method searches all CeActivity objects and returns only those that match four criteria for inclusion with
    /// activities that are due to expire in the future and the user specifically wants to be reminded of that ahead of time.
    /// - Returns: array of CeActivity objects meeting the inclusion criteria set within the function
    func fetchUpcomingExpiringCeActivities() -> [CeActivity] {
        let request: NSFetchRequest<CeActivity> = CeActivity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CeActivity.expirationDate, ascending: true)]
        
        // Criteria for activities expiring within the firstNoticeDays (AND criteria)
        // The activity must have have the expiration toggle set to true, with an expiration date still
        // future, not marked as completed, and has the expiration reminder toggle set to true.
        var expirationPredicates: [NSPredicate] = []
        let expiringActivitiesPredicate = NSPredicate(format: "activityExpires == true")
        let activitiesWithFutureExpiration = NSPredicate(format: "expirationDate > %@", Date.now as NSDate)
        let uncompletedActivitiesPredicate = NSPredicate(format: "activityCompleted == false")
        let userWantsExpirationReminderPredicate = NSPredicate(format:"expirationReminderYN == true")
        expirationPredicates.append(expiringActivitiesPredicate)
        expirationPredicates.append(activitiesWithFutureExpiration)
        expirationPredicates.append(uncompletedActivitiesPredicate)
        expirationPredicates.append(userWantsExpirationReminderPredicate)
        
        let combinedExpirationPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: expirationPredicates)
        request.predicate = combinedExpirationPredicate
        
        let fetchedActivities = (try? container.viewContext.fetch(request)) ?? []
        return fetchedActivities
       
    }//: fetchUpcomingExpiringCeActivities()
    
    
    /// This function pulls out only a single RenewalPeriod object, if any, that corresponds to what should be the current
    /// renewal period for all saved credentials
    /// - Returns: array of renewal periods in which the current date falls between the period's start and end dates
    func getCurrentRenewalPeriods() -> [RenewalPeriod] {
        let renewalRequest = RenewalPeriod.fetchRequest()
        renewalRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \RenewalPeriod.periodStart, ascending: true)
        ]
        
        var renewalPredicates: [NSPredicate] = []
        let startingDatePredicate = NSPredicate(format: "periodStart <= %@", Date.now as NSDate)
        let endingDatePredicate = NSPredicate(format: "periodEnd >= %@", Date.now as NSDate)
        renewalPredicates.append(startingDatePredicate)
        renewalPredicates.append(endingDatePredicate)
        
        let combinedRenewalPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: renewalPredicates)
        renewalRequest.predicate = combinedRenewalPredicate
        
        let fetchedRenewalPeriods = (try? container.viewContext.fetch(renewalRequest)) ?? []
        return fetchedRenewalPeriods
        
    }//: getCurrentRenewalPeriod()
    
    
    /// This function returns an array of all DisciplinaryActionItems that meet the criteria for being "active".  This
    /// means that the item is either permanent or, if temporary, has an end date that's still in the future.
    /// - Returns: array of DisciplinaryActionItems meeting the inclusion criteria
    func fetchActiveDisciplinaryActions() -> [DisciplinaryActionItem] {
        let daiRequest = DisciplinaryActionItem.fetchRequest()
        daiRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \DisciplinaryActionItem.actionName, ascending: true)
        ]
        
        var daiANDPredicates: [NSPredicate] = []
        let tempOnlyPredicate = NSPredicate(format: "temporaryOnly == true")
        let endDatePredicate = NSPredicate(format: "actionEndDate >= %@", Date.now as NSDate)
        daiANDPredicates.append(tempOnlyPredicate)
        daiANDPredicates.append(endDatePredicate)
        
        let daiANDCombinedPredicates = NSCompoundPredicate(andPredicateWithSubpredicates: daiANDPredicates)
        
        let permanentActionPredicate = NSPredicate(format: "temporaryOnly == false")
        
        let combinedPredicates = NSCompoundPredicate(orPredicateWithSubpredicates: [
            daiANDCombinedPredicates, permanentActionPredicate
            ]
        )
        
        daiRequest.predicate = combinedPredicates
        
        let fetchedDAIs = (try? container.viewContext.fetch(daiRequest)) ?? []
        return fetchedDAIs
        
    }
    
    // MARK: - Object Specific Notifications
    
    /// This method creates two notifications for each CeActivity which meets the inclusion criteria for being an upcoming,
    /// expiring actiivty.  Each notification's trigger date is determined by what the user entered in settings for primary and
    /// secondary notification day intervals.
    func scheduleExpiringCEsNotifications() async {
        // Accessing user settings
        if let userSettings = accessUserSettings() {
            let firstNotification = userSettings.daysUntilPrimaryNotification
            let secondNotification = userSettings.daysUntilSecondaryNotification
            
            let expiringCes = fetchUpcomingExpiringCeActivities()
            
            // Creating notifications
            for ce in expiringCes {
                for i in 1...2 {
                    let title = ce.ceTitle
                    let daysToExpiration = (ce.ceActivityExpirationDate.timeIntervalSinceNow) / 86400
                    let targetDaysAhead: Double = (
                        Double(i == 1 ? firstNotification : secondNotification)) * 86400
                    let body = "This CE activity is scheduled to expire \(Int(daysToExpiration)) day(s) from now! Make sure you complete it before then if you wish to count it for the current renewal peroid."
                    let triggerDate = (
                        ce.ceActivityExpirationDate).addingTimeInterval(-targetDaysAhead)
                    let noticeType: NotificationType = .upcomingExpiration
                    let noticeNumber: Int = i
                    
                    await addReminder(for: ce, title: title, body: body, onDate: triggerDate, notificationType: noticeType, noticeNum: noticeNumber)
                }//: INNER LOOP
            }//: LOOP
            
        }//: IF LET
    }//: scheduleExpiringCEsNotifications()
    
    /// This method creates notifications to alert the user when the end date for a credential's renewing period approaches and
    /// when the late renewal fee will be taking effect (if the user put that info in).  In both cases two notifications are created
    /// using the primary and secondary notifcation preferences set by the user as trigger dates.
    func scheduleRenewalsEndingNotifications() async {
        // Accessing user settings
        if let userSettings = accessUserSettings() {
            let firstNotification = userSettings.daysUntilPrimaryNotification
            let secondNotification = userSettings.daysUntilSecondaryNotification
            
            let endingRenewalPeriods = getCurrentRenewalPeriods()
            
            // Scheduling notifications related to the renewal period end date
            for period in endingRenewalPeriods {
                guard period.periodEnd != nil else { continue }
                let credName = period.credential?.credentialName ?? "your credential"
                for i in 1...2 {
                    let title = "The \(period.renewalPeriodName) for \(credName) ends soon!"
                    let targetDaysAhead: Double = (
                        Double(i == 1 ? firstNotification : secondNotification)) * 86400
                    let daysRemaining = Int((period.renewalPeriodEnd).timeIntervalSinceNow / 86400)
                    let body = "You have \(daysRemaining) days left before your credential expires if you haven't renewed yet!"
                    let triggerDate = (period.renewalPeriodEnd).addingTimeInterval(-targetDaysAhead)
                    let noticeType: NotificationType = .renewalEnding
                    let noticeNumber: Int = i
                    
                    await addReminder(for: period, title: title, body: body, onDate: triggerDate, notificationType: noticeType, noticeNum: noticeNumber)
                }//: INNER LOOP
            }//: LOOP
            
            
            // Scheduling notifications related to each renewal's late fee start date
            for period in endingRenewalPeriods {
                guard period.lateFeeAmount > 0, period.lateFeeStartDate != nil else { continue }
                let credName = period.credential?.credentialName ?? "your credential"
                for i in 1...2 {
                    let title = "The late fee for the \(period.renewalPeriodName) approaches!"
                    let targetDaysAhead: Double = (
                        Double(i == 1 ? firstNotification : secondNotification)) * 86400
                    let daysRemaining = Int((period.renewalLateFeeStartDate).timeIntervalSinceNow / 86400)
                    let body = "You have \(daysRemaining) days left before renewing your \(credName) will cost you $\(period.lateFeeAmount) extra - renew soon!"
                    let triggerDate = (period.renewalLateFeeStartDate).addingTimeInterval(-targetDaysAhead)
                    let noticeType: NotificationType = .lateFeeStarting
                    let noticeNumber: Int = i
                    
                    await addReminder(for: period, title: title, body: body, onDate: triggerDate, notificationType: noticeType, noticeNum: noticeNumber)
                }//: INNER LOOP
            }//: LOOP
            
        }//: IF LET
    } //: scheduleRenewalsEndingNotifications()
    
    
    func scheduleDisciplinaryActionNotifications() async {
        if let userSettings = accessUserSettings() {
            let firstNotice = userSettings.daysUntilPrimaryNotification
            let secondNotice = userSettings.daysUntilSecondaryNotification
            
            let calendar = Calendar.current
            let todaysDate = calendar.startOfDay(for: Date())
            
            let allDAIS = fetchActiveDisciplinaryActions()
            
            // MARK: Scheduling DAI end date notifications (for temporary actions ONLY)
            for dai in allDAIS {
                guard dai.actionEndDate != nil, dai.daiActionEndDate > todaysDate else { continue }
                let credName = dai.credential?.credentialName ?? "your credential"
                for i in 1...2 {
                    let title = "The \(dai.daiActionName) for \(credName) ends soon!"
                    let targetDaysAhead: Double = (
                        Double(i == 1 ? firstNotice : secondNotice)) * 86400
                    let daysRemaining = Int((dai.actionEndDate ?? Date.probationaryEndDate).timeIntervalSinceNow / 86400)
                    let body = "You have \(daysRemaining) day(s) left before the \(dai.daiActionType) period taken against your credential ends.  Be sure that you have completed all required actions by the governing body by this date."
                    let triggerDate = (dai.daiActionEndDate).addingTimeInterval(-targetDaysAhead)
                    let noticeType: NotificationType = .disciplineEnding
                    let noticeNumber: Int = i
                    
                    await addReminder(for: dai, title: title, body: body, onDate: triggerDate, notificationType: noticeType, noticeNum: noticeNumber)
                }//: INNER LOOP
            }//: LOOP
            
            // MARK: Scheduling community service due date notifications
            for dai in allDAIS {
                guard dai.commServiceDeadline != nil, dai.daiCommunityServiceDeadline > todaysDate, dai.commServiceCompletedOn == nil else { continue }
                for i in 1...2 {
                    let title = "Community service hours due soon!"
                    let targetDaysAhead: Double = (
                        Double(i == 1 ? firstNotice : secondNotice)) * 86400
                    let daysRemaining = Int((dai.commServiceDeadline ?? Date.probationaryEndDate).timeIntervalSinceNow / 86400)
                    let body = "You have \(daysRemaining) day(s) left before the \(dai.commServiceHours) hours of community service must be completed.  Be sure that you have completed all required hours by this date."
                    let triggerDate = (dai.daiCommunityServiceDeadline).addingTimeInterval(-targetDaysAhead)
                    let noticeType: NotificationType = .serviceDeadlineApproaching
                    let noticeNumber: Int = i
                    
                    await addReminder(for: dai, title: title, body: body, onDate: triggerDate, notificationType: noticeType, noticeNum: noticeNumber)
                }//: INNER LOOP
            }//: LOOP
            
        
            // MARK: Scheduling DAI fine deadline notifications
            for dai in allDAIS {
                guard dai.fineDeadline != nil, dai.finePaidOn == nil else { continue }
                let credIssuer = dai.credential?.issuer?.issuerName ?? "governing body"
                for i in 1...2 {
                    let title = "Fine due soon!"
                    let targetDaysAhead: Double = (
                        Double(i == 1 ? firstNotice : secondNotice)) * 86400
                    let daysRemaining = Int((dai.fineDeadline ?? Date.probationaryEndDate).timeIntervalSinceNow / 86400)
                    let body = "You have \(daysRemaining) day(s) left before the $\(dai.fineAmount) fine levied against your credential is due to the \(credIssuer).  Be sure that you have paid it  by this date."
                    let triggerDate = (dai.daiFinesDueDate).addingTimeInterval(-targetDaysAhead)
                    let noticeType: NotificationType = .fineDeadlineApproaching
                    let noticeNumber: Int = i
                    
                    await addReminder(for: dai, title: title, body: body, onDate: triggerDate, notificationType: noticeType, noticeNum: noticeNumber)
                }//: INNER LOOP
            }//: LOOP
            
            
            // MARK: Scheduling DAI extra CE hours deadline notifications
            for dai in allDAIS {
                guard dai.ceDeadline != nil, dai.daiCEDeadlineDate > todaysDate else { continue }
                let credName = dai.credential?.credentialName ?? "your credential"
                for i in 1...2 {
                    let title = "Mandated CE hours due soon!"
                    let targetDaysAhead: Double = (
                        Double(i == 1 ? firstNotice : secondNotice)) * 86400
                    let daysRemaining = Int((dai.ceDeadline ?? Date.probationaryEndDate).timeIntervalSinceNow / 86400)
                    let body = "You have \(daysRemaining) day(s) left before the \(dai.disciplinaryCEHours) hours of required continuing education hours must be completed for your \(credName).  Be sure that all hours are completed by this day."
                    let triggerDate = (dai.daiCEDeadlineDate).addingTimeInterval(-targetDaysAhead)
                    let noticeType: NotificationType = .ceHoursDeadlineApproaching
                    let noticeNumber: Int = i
                    
                    await addReminder(for: dai, title: title, body: body, onDate: triggerDate, notificationType: noticeType, noticeNum: noticeNumber)
                }//: INNER LOOP
            }//: LOOP
            
        }//: IF LET
        
    }//: scheduleDisciplinaryActionNotifications()
    
    
}//: DATA CONTROLLER

// MARK: - Accessing User Settings
extension DataController {
    
    /// This method reads out the contents of the AppSettings struct which are encoded in a document within FileManager.  This was originally
    /// created by the CeAppSettings class initializer, but reusing some of the functionality so that other functions within DataController can
    /// easily access all user settings as needed.
    /// - Returns: AppSettings struct decoded from the settings.json file which contains all saved user settings for the app
    func accessUserSettings() -> AppSettings? {
        let settingsFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("settings.json")
        
        guard let data = try? Data(contentsOf: settingsFileURL) else { return nil }
        return try? JSONDecoder().decode(AppSettings.self, from: data)
    }//: accessUserSettings()
    
    
}//: DATA CONTROLLER
