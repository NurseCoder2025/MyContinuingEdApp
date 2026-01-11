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
        
        await scheduleUpcomingCeActivityNotifications()
        await scheduleExpiringCEsNotifications()
        await scheduleRenewalsEndingNotifications()
        await scheduleDisciplinaryActionNotifications()
        await scheduleRelevantReinstatementInfoNotifications()
        
    }//: updateAllReminders
    
    
    // MARK: - Object Fetching for Notifications
    
    // Fetch all uncompleted CeActivities that are about to expire within a set period
    /// This method searches all CeActivity objects and returns only those that match four criteria for inclusion with
    /// activities that are due to expire in the future and the user specifically wants to be reminded of that ahead of time.
    /// - Returns: array of CeActivity objects meeting the inclusion criteria set within the function
    /// - Criteria:
    ///     - CeActivity must be set to expire (activityExpires = true)
    ///     - The activity's expiration date must be after the current date
    ///     - The activity must not be marked as completed
    ///     - The activity's expirationReminderYN property must be set to true
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
    
    
    /// Method for getting an array of all RenewalPeriod objects for which the current date happens to fall
    /// between the starting and ending date (including either date as well).
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
    
    
    /// Method that returns an array of all CeActivities that meet the criteria for being "upcoming" and can be
    /// included for the scheduling of notifications to the user.
    /// - Returns: Array of CeActivities meeting all fetch predicates
    /// - Criteria:
    ///     - CeActivity must have a startTime value greater than that of the current Date value
    ///     - CeActivity must have the startReminderYN set to true (user wants to be reminded)
    ///     - CeActivity must not have been marked as completed
    ///
    ///  There is a global settings value that also controls whether any CeActivity start reminders are shown,
    ///  showActivityStartNotifications, that value will be used in the notification scheduling function to
    ///  determine whether to schedule any notifications.
    func fetchUpcomingCeActivities() -> [CeActivity] {
        let activityFetch = CeActivity.fetchRequest()
        activityFetch.sortDescriptors = [NSSortDescriptor(key: "activityTitle", ascending: true)]
        
        let activityPredicates: [NSPredicate] = [
            NSPredicate(format: "startTime > %@", Date.now as NSDate),
            NSPredicate(format: "startReminderYN == true"),
            NSPredicate(format: "activityCompleted == false")
        ]
        
        activityFetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: activityPredicates)
        
        let fetchedActivities = (try? container.viewContext.fetch(activityFetch)) ?? []
        return fetchedActivities
    }//: fetchUpcomingCeActivities()
    
    
    /// Method for fetching all ReinstatementInfo objects for the purpose of creating and
    /// scheduling notifications to the user.
    /// - Returns: Array containing any ReinstatementInfo objects that meet the criteria
    ///
    /// Predicate criteria include:
    ///     - Reinstatement deadline must still be future AND any of the following:
    ///         - Background check is required
    ///         - Interview is required
    ///         - Additional knowledge testing is required
    ///         - The required CEs for reinstatement are not completed yet
    func fetchCurrentReinstatmentItems() -> [ReinstatementInfo] {
        let reinInfoFetch = ReinstatementInfo.fetchRequest()
        reinInfoFetch.sortDescriptors = [NSSortDescriptor(key: "reinstatementDeadline", ascending: true)]
        
        let reinInfoANDPredicates: [NSPredicate] = [
            NSPredicate(format: "reinstatementDeadline > %@", Date.now as NSDate),
        ]
        
        let reinInfoORPredicates: [NSPredicate] = [
            NSPredicate(format: "backgroundCheckYN == true"),
            NSPredicate(format: "interviewYN == true"),
            NSPredicate(format: "additionalTestingYN == true"),
            NSPredicate(format: "cesCompletedYN == false")
        ]
        
        let reinInfoPredicateCompound: NSCompoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: reinInfoORPredicates)
        
        let reinInfoFinalPredicate: NSCompoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: reinInfoANDPredicates + [reinInfoPredicateCompound])
        
        reinInfoFetch.predicate = reinInfoFinalPredicate
        
        let fetchedReinstatementInfo: [ReinstatementInfo] = (try? container.viewContext.fetch(reinInfoFetch)) ?? []
        
        return fetchedReinstatementInfo
    }//: fetchCurrentReinstatementItems
    
    
    // MARK: - Object Specific Notifications
    // ** It is important that all of the methods in this section are included
    // in the updateAllReminders() method **
    
    /// This method creates two notifications for each CeActivity which meets the inclusion criteria for being an upcoming,
    /// expiring actiivty.  Each notification's trigger date is determined by what the user entered in settings for primary and
    /// secondary notification day intervals.
    func scheduleExpiringCEsNotifications() async {
        guard showExpiringCesNotification == true else { return }
            let firstNotification = primaryNotificationDays
            let secondNotification = secondaryNotificationDays
        
            let calendar = Calendar.current
            let amNotificationTime = Double (60 * 60 * 10)
            
            let expiringCes = fetchUpcomingExpiringCeActivities()
            
            // Creating notifications
            for ce in expiringCes {
                guard let expiresOn = ce.expirationDate, ce.expirationReminderYN == true else { continue }
                for i in 1...2 {
                    let title = ce.ceTitle
                    let daysToExpiration = (expiresOn.timeIntervalSinceNow) / 86400
                    let targetDaysAhead: Double = (
                        Double(i == 1 ? firstNotification : secondNotification)) * 86400
                    let body = "This CE activity ^[is scheduled to expire \(Int(daysToExpiration)) day](inflect:true) from now! Make sure you complete it before then if you wish to count it for the current renewal period."
                    let triggerDate = calendar.startOfDay(for: expiresOn).addingTimeInterval(-targetDaysAhead)
                    let morningNoticeTime = triggerDate.addingTimeInterval(amNotificationTime)
                    let noticeType: NotificationType = .upcomingExpiration
                    let noticeNumber: Int = i
                    
                    await addReminder(
                        for: ce,
                        title: title,
                        body: body,
                        onDate: morningNoticeTime,
                        notificationType: noticeType,
                        noticeNum: noticeNumber
                    )
                }//: INNER LOOP
            }//: LOOP
            
    }//: scheduleExpiringCEsNotifications()
    
    /// This method creates multiple notifications related to the end of a renewal period and the need for them to complete all required CEs and renew
    /// their credential before it ends to prevent the credential from lapsing.
    ///
    /// A total of five different notification types are created and scheduled by this method, if the notification criteria for each are met.  For three of the
    /// types (6 month renewal notice, renewal application window starting, and late fee starting), only one notification is scheduled and is for a specific
    /// date.  For the remaining two types (general renewal reminder & late fee approaching), two notifications are generated based on the user's
    /// notification preferences as set in Settings. All notifications created by this method are scheduled to be triggered at 10am on the day they are to
    /// be shown to the user.
    func scheduleRenewalsEndingNotifications() async {
        guard showRenewalEndingNotification == true else {return}
            let firstNotification = primaryNotificationDays
            let secondNotification = secondaryNotificationDays
        
            let calendar = Calendar.current
            let morningNotificationTimeFactor: Double = (60 * 60 * 10)
            
            let endingRenewalPeriods = getCurrentRenewalPeriods()
            
            // Scheduling a 6 month renewal notification
            // Note: first & second notifications do NOT apply to this particular notification
            for period in endingRenewalPeriods {
                guard period.periodEnd != nil, period.renewalCompletedYN == false else { continue }
                let credName = period.credential?.credentialName ?? "credential"
                let title = "6 months remaining until renewal!"
                let body = "Time flies! You only have six months left before your \(credName) expires. Now is the time to start working on getting all your required CEs if you haven't done so yet."
                
                if let triggerDate = getCustomMonthsLeftInRenewalDate(months: -6, renewal: period) {
                    let noticeTime = triggerDate.addingTimeInterval(morningNotificationTimeFactor)
                    let noticeType: NotificationType = .renewalEnding
                    let noticeNumber: Int = 666
                    
                    await addReminder(
                        for: period,
                        title: title,
                        body: body,
                        onDate: noticeTime,
                        notificationType: noticeType,
                        noticeNum: noticeNumber)
                }//: IF LET
            }//: LOOP
        
            // Renewal application window now open notification
            for period in endingRenewalPeriods {
                guard let endDate = period.periodEnd, let windowOpens = period.periodBeginsOn else { continue }
                
                let credName = period.credential?.credentialName ?? "credential"
                let title = "Application window for the next renewal cycle now open!"
                let lateFeeString = (
                    period.renewalHasLateFeeYN ? "Your credential issuer will charge a late fee of $\(period.lateFeeAmount) if you don't renew before \(period.renewalLateFeeStartDate), so be sure to renew before then."
                    : "Don't wait until the last minute to renew!"
                    )
                let body = "You can now renew your \(credName) anytime between now and \(endDate). \(lateFeeString)"
                let triggerDate = calendar.startOfDay(for: windowOpens).addingTimeInterval(morningNotificationTimeFactor)
                let noticeType: NotificationType = .renewalProcessStarting
                let noticeNumber: Int = 777
                
                await addReminder(
                    for: period,
                    title: title,
                    body: body,
                    onDate: triggerDate,
                    notificationType: noticeType,
                    noticeNum: noticeNumber
                )
            }//: LOOP
            
            
            // Scheduling notifications related to the renewal period end date
            for period in endingRenewalPeriods {
                guard let endDate = period.periodEnd, period.renewalCompletedYN == false else { continue }
                let credName = period.credential?.credentialName ?? "your credential"
                for i in 1...2 {
                    let title = "The \(period.renewalPeriodName) for \(credName) ends soon!"
                    let targetDaysAhead: Double = (
                        Double(i == 1 ? firstNotification : secondNotification)) * 86400
                    let daysRemaining = Int((endDate).timeIntervalSinceNow / 86400)
                    let body = "^[You have \(daysRemaining) day](inflect:true) left before your credential expires if you haven't renewed yet!"
                    let triggerDate = calendar.startOfDay(for: endDate).addingTimeInterval(-targetDaysAhead)
                    let amNoticeTime = triggerDate.addingTimeInterval(morningNotificationTimeFactor)
                    let noticeType: NotificationType = .renewalEnding
                    let noticeNumber: Int = i
                    
                    await addReminder(
                        for: period,
                        title: title,
                        body: body,
                        onDate: amNoticeTime,
                        notificationType: noticeType,
                        noticeNum: noticeNumber
                    )
                }//: INNER LOOP
            }//: LOOP
            
            
            // Scheduling notifications related to each renewal's late fee start date
            for period in endingRenewalPeriods {
                guard showRenewalLateFeeNotification, period.lateFeeAmount > 0, let lateFeeDate = period.lateFeeStartDate, period.renewalCompletedYN == false, let endDate = period.periodEnd else { continue }
                let credName = period.credential?.credentialName ?? "your credential"
                for i in 1...2 {
                    let title = "The late fee for the \(period.renewalPeriodName) approaches!"
                    let targetDaysAhead: Double = (
                        Double(i == 1 ? firstNotification : secondNotification)) * 86400
                    let daysRemaining = Int((lateFeeDate).timeIntervalSinceNow / 86400)
                    let body = "^[You have \(daysRemaining) day](inflect:true) left before renewing your \(credName) will cost you $\(period.lateFeeAmount) extra - renew soon!"
                    let triggerDate = calendar.startOfDay(for: lateFeeDate).addingTimeInterval(-targetDaysAhead)
                    let amNoticeTime = triggerDate.addingTimeInterval(morningNotificationTimeFactor)
                    let noticeType: NotificationType = .lateFeeStarting
                    let noticeNumber: Int = i
                    
                    await addReminder(
                        for: period,
                        title: title,
                        body: body,
                        onDate: amNoticeTime,
                        notificationType: noticeType,
                        noticeNum: noticeNumber
                    )
                }//: INNER LOOP
                
                // Adding same day late fee starting notification if user still has not renewed
                let title = "The late fee for the \(period.renewalPeriodName) starts TODAY!"
                let daysLeftToRenew = Int((endDate).timeIntervalSinceNow / 86400)
                let body = "Unfortunately,renewing your \(credName) will now cost you $\(period.lateFeeAmount) extra. You only have \(daysLeftToRenew) days left to renew, so make sure you do so before \(endDate). Otherwise, your credential will lapse and you will need to reinstate it."
                let triggerDate = calendar.startOfDay(for: lateFeeDate)
                let amNoticeTime = triggerDate.addingTimeInterval(morningNotificationTimeFactor)
                let noticeType: NotificationType = .lateFeeStarting
                let noticeNumber: Int = 3
                
                await addReminder(
                    for: period,
                    title: title,
                    body: body,
                    onDate: amNoticeTime,
                    notificationType: noticeType,
                    noticeNum: noticeNumber
                )
                
            }//: LOOP
            
       
    } //: scheduleRenewalsEndingNotifications()
    
    
    func scheduleDisciplinaryActionNotifications() async {
        guard showDAINotifications == true else {return}
            let firstNotice = primaryNotificationDays
            let secondNotice = secondaryNotificationDays
            
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
                    let body = "^[You have \(daysRemaining) day](inflect:true) left before the \(dai.daiActionType) period taken against your credential ends.  Be sure that you have completed all required actions by the governing body by this date."
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
                    let body = "^[You have \(daysRemaining) day](inflect:true) left ^[before the \(dai.commServiceHours) hour](inflect:true) of community service must be completed.  Be sure that you have completed all required hours by this date."
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
                    let body = "^[You have \(daysRemaining) day](inflect:true) left before the $\(dai.fineAmount) fine levied against your credential is due to the \(credIssuer).  Be sure that you have paid it  by this date."
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
                    let body = "^[You have \(daysRemaining) day](inflect:true) left ^[before the \(dai.disciplinaryCEHours) hour](inflect:true) of required continuing education hours must be completed for your \(credName).  Be sure that all hours are completed by this day."
                    let triggerDate = (dai.daiCEDeadlineDate).addingTimeInterval(-targetDaysAhead)
                    let noticeType: NotificationType = .ceHoursDeadlineApproaching
                    let noticeNumber: Int = i
                    
                    await addReminder(for: dai, title: title, body: body, onDate: triggerDate, notificationType: noticeType, noticeNum: noticeNumber)
                }//: INNER LOOP
            }//: LOOP
            
        
    }//: scheduleDisciplinaryActionNotifications()
    
    
    /// Method that creates multiple notifications for CeActivities that have a specified starting time.
    ///
    /// The notifications are created both in terms of days ahead as well as minutes ahead, based on the values
    /// entered by the user in Settings for primary and secondary notifications as well as live alerts.  If an activity has
    /// a starting time, hasn't been completed, and has been marked for notifications, then the method will create 2 alerts
    /// in the days leading up to the event, based on user preference.  Then, on the day of the live even two notifications
    /// will be scheduled for however many minutes ahead the user sets the preferences for.  If set to 0 minutes, no notification
    /// will be made.
    func scheduleUpcomingCeActivityNotifications() async {
        guard showAllLiveEventAlerts else { return }
        
        let firstNotification = primaryNotificationDays
        let secondNotification = secondaryNotificationDays
        let calendar = Calendar.current
        let morningNoticeTime = Double(60 * 60 * 10)
        
        let eligibleActivities = fetchUpcomingCeActivities()
        guard eligibleActivities.isNotEmpty else {return}
        
        // Creating and scheduling the two notifications for each activity
        for activity in eligibleActivities {
            guard let startTime = activity.startTime else { continue }
            let startDate = startTime.formatted(date: .numeric, time: .omitted)
            let time = startTime.formatted(date: .omitted, time: .shortened)
            
            // Notifications scheduled days ahead
            for i in 1...2 {
                let targetDaysAhead: Double = Double((i == 1 ? firstNotification : secondNotification) * 86400)
                let daysUntilEvent: Int = Int((startTime.timeIntervalSinceNow) / 86400)
                
                let title: String = "Live CE activity coming up!"
                let body: String = "Don't miss the live CE activity, \(activity.ceTitle), on \(startDate) at \(time)! It's only \(daysUntilEvent) away from now!"
                
                let triggerDate = calendar.startOfDay(for: startTime).addingTimeInterval(-targetDaysAhead)
                let amNoticeTime = triggerDate.addingTimeInterval(morningNoticeTime)
                let noticeType: NotificationType = .liveActivityStarting
                let noticeNumber: Int = i
                
                await addReminder(
                    for: activity,
                    title: title,
                    body: body,
                    onDate: amNoticeTime,
                    notificationType: noticeType,
                    noticeNum: noticeNumber
                )
            }//: LOOP (inner)
            
            
            // Notifications scheduled for hours / minutes ahead
            // Multiplying by 60 because the Settings keys that these variables point to
            // return a Double value that represents the number of minutes ahead that the
            // user wishes to receive a notification for
            let firstAlert = (firstLiveEventAlert * 60)
            let secondAlert = (secondLiveEventAlert * 60)
            
            for j in 1...2 {
                let targetTimeAhead: Double = Double((j == 1 ? firstAlert : secondAlert))
                guard targetTimeAhead > 0 else {continue}
                let timeUntilEvent: Int = Int(startTime.timeIntervalSinceNow / 60)
                
                let title: String = "Live CE activity coming up!"
                let body: String = "Don't miss the live CE activity, \(activity.ceTitle), starting in \(timeUntilEvent) minutes at \(time)!"
                
                let triggerTime = startTime.addingTimeInterval(-targetTimeAhead)
                let noticeType: NotificationType = .liveActivityStarting
                let noticeNumber: Int = j
                
                await addReminder(
                    for: activity,
                    title: title,
                    body: body,
                    onDate: triggerTime,
                    notificationType: noticeType,
                    noticeNum: noticeNumber
                )
            }//: LOOP
        }//: LOOP (activity in eligibleActivities)
    }//: scheduleUpcomingCeActivityNotifications()
    
    
    /// Method for scheduling notifications related to ReinstatementInfo objects.  If the showReinstatementAlerts
    /// settings is set to true, then notifications will be generated for ReinstatementInfo objects when other criteria
    /// is met.
    ///
    /// The specific types of notifications scheduled by this method include: deadline notifications, interview date
    /// notifications, and exam notifications. All notifications that are date based will be scheduled for 10am on the
    /// day that they are to appear.
    func scheduleRelevantReinstatementInfoNotifications() async {
        guard showReinstatementAlerts else { return }
        
        let relevantRIs = fetchCurrentReinstatmentItems()
        guard relevantRIs.isNotEmpty else { return }
        
        let firstNotification = primaryNotificationDays
        let secondNotification = secondaryNotificationDays
        let calendar = Calendar.current
        let morningNotificationInterval: Double = (60 * 60 * 10)
        
        for relevantRI in relevantRIs {
            // deadline approaching notifications
            for a in 1...2 {
                guard let riDeadline = relevantRI.reinstatementDeadline else { continue }
                let pureDeadline = calendar.startOfDay(for: riDeadline)
                let daysToDeadline = Int(pureDeadline.timeIntervalSinceNow / 86400)
                let targetDaysAhead: Double = (a == 1 ? Double(firstNotification) : Double(secondNotification) * 86400)
                
                let title: String = "Reinstatement Deadline/Goal Approaching"
                let body: String = "This is a friendly reminder that there are only \(daysToDeadline) days left to reinstate your credential (if this date is a goal you set versus a hard deadline set by the licensing board or governing body, then try to get everything done by then). Please ensure that you are on track towards getting everything done that is needed for reinstatement by \(pureDeadline.formatted(date: .abbreviated, time: .omitted))."
                
                let triggerDate = pureDeadline.addingTimeInterval(-targetDaysAhead)
                let amNoticeTime = triggerDate.addingTimeInterval(morningNotificationInterval)
                let noticeType: NotificationType = .reinstatementDeadline
                let noticeNumber: Int = a
                
                await addReminder(
                    for: relevantRI,
                    title: title,
                    body: body,
                    onDate: amNoticeTime,
                    notificationType: noticeType,
                    noticeNum: noticeNumber
                )
            }//: LOOP (a)
            
            // interview notifications
            // Interview DATE reminders
            for b in 1...2 {
                guard let interviewDate = relevantRI.interviewScheduled, interviewDate > Date.now else { continue }
                let pureInterviewDate = calendar.startOfDay(for: interviewDate)
                let dateString = pureInterviewDate.formatted(date: .numeric, time: .omitted)
                let timeString = interviewDate.formatted(date: .omitted, time: .shortened)
                
                let daysToInterview = Int(pureInterviewDate.timeIntervalSinceNow / 86400)
                let targetDaysAhead: Double = (b == 1 ? Double(firstNotification) : Double(secondaryNotificationDays) * 86400)
                
                let title: String = "Reinstatement Interview Approaching"
                let body: String = "Don't forget that you have an important interview coming up with your credential issuer to help get it reinstated. It is only \(daysToInterview) days away from now, on \(dateString) at \(timeString). Please make sure you have everything ready and on track for this important meeting."
                
                let triggerDate = pureInterviewDate.addingTimeInterval(-targetDaysAhead)
                let amNoticeTime = triggerDate.addingTimeInterval(morningNotificationInterval)
                let noticeType: NotificationType = .interview
                let noticeNumber: Int = b
                
                await addReminder(
                    for: relevantRI,
                    title: title,
                    body: body,
                    onDate: amNoticeTime,
                    notificationType: noticeType,
                    noticeNum: noticeNumber
                )
            }//: LOOP (b)
            
            // Interview TIME reminders
            for c in 1...2 {
                guard let interviewDate = relevantRI.interviewScheduled, interviewDate > Date.now else { continue }
                let timeString = interviewDate.formatted(date: .omitted, time: .shortened)
                let firstAlert = (firstLiveEventAlert * 60)
                let secondAlert = (secondLiveEventAlert * 60)
                let targetTimeAhead = (c == 1 ? Double(firstAlert) : Double(secondAlert))
                
                let minutesToEvent = Int(interviewDate.timeIntervalSinceNow / 60)
                guard minutesToEvent > 0 else { continue }
                
                let title: String = "Reinstatement Interview Reminder"
                let body: String = "You have an important interview coming up with your credential issuer to help get it reinstated. It will start in \(minutesToEvent) minutes at \(timeString). Please make sure you have everything ready and on track for this important meeting."
                
                let triggerTime = interviewDate.addingTimeInterval(-targetTimeAhead)
                let noticeType: NotificationType = .interview
                let noticeNumber: Int = c
                
                await addReminder(
                    for: relevantRI,
                    title: title,
                    body: body,
                    onDate: triggerTime,
                    notificationType: noticeType,
                    noticeNum: noticeNumber
                )
            }//: LOOP (c)
            
            // testing date notifications
            for d in 1...2 {
                guard let testDate = relevantRI.additionalTestDate, testDate > Date.now else { continue }
                
                let firstNotification = primaryNotificationDays
                let secondNotification = secondaryNotificationDays
                let targetDaysAhead = (d == 1 ? Double(firstNotification) : Double(secondNotification)) * 86400
                
                let dateString = testDate.formatted(date: .numeric, time: .omitted)
                let timeString = testDate.formatted(date: .omitted, time: .shortened)
                
                let daysToTest = Int(testDate.timeIntervalSinceNow / 86400)
               
                let title: String = "Credential Re-Test Date Approaching"
                let body: String = "As part of your credential reinstatement, the governing body requires you to take an exam, which is now only \(daysToTest) days away on \(dateString) at \(timeString). Study hard!"
                
                let triggerDate = calendar.startOfDay(for: testDate).addingTimeInterval(-targetDaysAhead)
                let amNoticeTime = triggerDate.addingTimeInterval(morningNotificationInterval)
                let noticeType: NotificationType = .additionalTestDate
                let noticeNumber: Int = d
                
                await addReminder(
                    for: relevantRI,
                    title: title,
                    body: body,
                    onDate: amNoticeTime,
                    notificationType: noticeType,
                    noticeNum: noticeNumber
                )
            }//: LOOP (d)

        }//: LOOP
    }//: scheduleRelevantReinstatementInfoNotifications()
    
}//: DATA CONTROLLER

