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
    
    /// Method that creates and sends a notification request to the UNUserNotificationCenter for a NON-NSManaged object.
    /// - Parameters:
    ///   - object: Any object that conforms to Identifiable (but should not be a NSManaged Object - those have a separate method)
    ///   - title: String value representing the title for the notification
    ///   - body: String value representing the body for the notification
    ///   - triggerDate: Date on which the notification is to be generated and shown to the user
    ///   - notificationType: NotificationType enum specifying what type of notification is being created (for identification purposes)
    ///   - noticeNum: Int representing the notification number in a series of notices for the same object to help create a unique notification ID
    ///
    /// - Important: This method should ONLY be used for objects that do not conform to the NSManagedObject protocol.  For those objects
    /// please use the scheduleSingleNotification() method.  This method should be called within the addNonCoreDataObjNotification method.
    ///
    /// This method requires an object conforming to Identifiable because it is the id property required for all objects following that protocol which is
    /// used to create a unique notification center ID (required by the UserNotifications API).  Since non-NSManagedObjects will not have a UUID
    /// property, this is the replacement for that.  Other than that, all of the logic is exactly the same to that of the scheduleSingleNotification method.
    private func scheduleNonCoreDataObjSingleNotification<T: Identifiable>(
        for object: T,
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
        
        // Getting the id property from the identifiable object that was passed in to use as part
        // of the identifier for each notification center request
            let uniqueID = object.id
            let identifier = "\(uniqueID)-\(notificationType.rawValue).\(noticeNum)"
            
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            return try await center.add(request)
    }//: scheduleOneNotificationForNonCoreDataObj()
    
    // MARK: ADD REMINDER
    /// The public function for adding notifications to various objects in the app.  Structured generally so each
    /// notification can be customized based on the object and specific circumstances surrounding the notification.
    /// - Parameters:
    ///   - object: object with a key date property the user should be aware of, like CeActivity & RenewalPeriod
    ///   - title: title for the notification
    ///   - body: text describing details relvant to the notification
    ///   - onDate: when the notification is to be shown to the user
    /// - Returns: True or False, based on whether the notifcation was successfully scheduled or not
    ///
    /// - Important: If you need to create a notification for a non-Core Data object, then please use the addNonCoreDataObjReminder
    /// method as it takes any object that conforms to Identifiable.  This method requires an object inheriting from the NSManagedObject class.
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
    
    /// Method for initializing the process for notification creation for a non-CoreData object.  The object argument takes anything conforming to
    /// Identifiable and then uses the remaining arguments to determine if notifications are authorized, and if so, call the
    /// scheduleNonCoreDataObjSingleNotification method for doing the actual notification center request.  If notification authorization status is
    /// not yet determined, the method will call the requestNotifications method to get the user to authorize them.
    /// - Parameters:
    ///   - object: Any object conforming to the Identifiable protocol
    ///   - title: String value representing the title for the notification
    ///   - body: String value representing the body message of the notification
    ///   - onDate: Date value for the date & time on which the notifcation should be shown to the user
    ///   - notificationType: NotificationType enum value representing the type of notification being created
    ///   - noticeNum: Int representing the sequence number for the notification if created in series of notifications for the same object and
    ///   same type (reason)
    ///
    /// - Important: If creating a notification for a CoreData or NSManagedObject object, then please use the addReminder method.
    private func addNonCoreDataObjReminder<T: Identifiable>(
        for object: T,
        title: String,
        body: String,
        onDate: Date,
        notificationType: NotificationType,
        noticeNum: Int
    ) async {
        do {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            
            switch settings.authorizationStatus {
            case .notDetermined:
                // more code to come
                let isAuthorized = try await requestNotifications()
                
                if isAuthorized {
                    try await scheduleNonCoreDataObjSingleNotification(for: object, title: title, body: body, triggerDate: onDate, notificationType: notificationType, noticeNum: noticeNum)
                } else {
                    print("Sorry, but notifications are not yet enabled")
                }
                
            case .authorized:
                try await scheduleNonCoreDataObjSingleNotification(
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
    }//: addReminderNonCoreDateObj()
    
    // MARK: Object Notification Creation
    
    /// Method that generates up to 4 notifications for any given object passed in as an argument, depending on whether the
    /// object represents a live event (conference, webinar, etc.) or anything else (renewal period deadlines, activity expiration).
    /// - Parameters:
    ///   - forObject: Any CoreData object for which notifications are to be created for
    ///   - objType: ObjectCategory enum value representing whether the object is a live even or not (default: .nonLive)
    ///   - noticeForDate: Date value for which the notification is being generated for (deadline, starting time,etc.)
    ///   - title: String for whatever will go in the notification's title
    ///   - body: String for whatever will go in the notification body
    ///   - type: NotificationType enum indicating the type of notifcation that is being created
    ///   - timePreferred: TimePreference enum value for whether day-based notifications should be shown in the morning,
    ///   afternoon, or evening
    ///   - singleNoticeYN: Boolean representing whether only 1 notification should be created (non-live ONLY)
    ///   - customNoticeDate: OPTIONAL Date for specifying a specific day on which a notification is to be given (default: nil); should ONLY
    ///   be used when singleNoticeYN is true
    ///   - timeTitle: OPTIONAL String representing a custom header value for notifications created for live events (default: nil)
    ///   - timeBody: OPTIONAL String representing a custom body text for notifications created for live events (default: nil)
    ///
    /// - Important: This method must remain defined & used within the DataController-Notifications file as it references a PRIVATE
    /// method, addReminder, contained within that file.  If called or defined elsewhere, two compiler errors will be thrown.
    ///
    /// Use this method for simplifying the process of creating notifications for objects within this app.  If an object represents a "live"
    /// activity such as a simulation or live webinar, then up to four different notifcations will be generated, depending on the app's
    /// notification settings.  For all objects, day-based notifications will be shown at either 10am, 3pm, or 7pm, depending on the
    /// timePreferred argument that is passed in.  For more choices, additional enum values for TimePreferences will need to be added
    /// along with corresponding Double static property that provides the number of seconds between midnight and the desired time.
    func createObjectNotifications(
        forObject: NSManagedObject,
        objType: ObjectCategory = .nonLive,
        noticeForDate: Date,
        title: String,
        body: String,
        timeTitle: String? = nil,
        timeBody: String? = nil,
        type: NotificationType,
        timePreferred: TimePreference = .morning,
        singleNoticeYN: Bool = false,
        customNoticeDate: Date? = nil
    ) async {
        // MARK: - ALL Notifications
        let calendar = Calendar.current
        let firstNotification = primaryNotificationDays
        let secondNotification = secondaryNotificationDays
        guard firstNotification > 0 && secondNotification > 0 else {return}
        
        // Making sure that the string values passed into the method are more than just
        // white spaces
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedTitle.isNotEmpty && trimmedBody.isNotEmpty else {return}
        
        // Defining noticeTime depending on value of timePreferred argument
        let noticeTime: Double
        switch timePreferred {
        case .morning:
            noticeTime = Double.morningNotificationTimeAdjustment
        case .afternoon:
            noticeTime = Double.afternoonNotificationTimeAdjustment
        case .evening:
            noticeTime = Double.eveningNotificationTimeAdjustment
        }//: SWITCH
        
        // MARK: - ALL OBJECT NOTIFICATIONS (day-based)
        // Creating day-based notifications, using a pre-determined display time
        // from the Double extension
        let endValue: Int = singleNoticeYN ? 1 : 2
        for i in 1...endValue {
            let pureTargetDate = calendar.startOfDay(for: noticeForDate)
            var daysAheadTrigger: Double
            // For the logic in this block, making sure that if a custom trigger date value was
            // passed in for the customNoticeDate parameter, then both that date value as well
            // as the noticeForDate arguments have the same time value so same day notifications
            // can be created.
            if let singleTriggerDate = customNoticeDate {
                let pureSingleTriggerDate = calendar.startOfDay(for: singleTriggerDate)
                 daysAheadTrigger = Double(pureTargetDate.timeIntervalSince(pureSingleTriggerDate))
                // Setting daysAheadTrigger to negative value if greater than 0 (days are different)
                // If days are the same, then daysAheadTrigger should be 0 which will allow for same
                // day notifications.
                if daysAheadTrigger > 0 {
                    daysAheadTrigger = 0 - daysAheadTrigger
                }
            } else {
                daysAheadTrigger = Double((i == 1 ? firstNotification : secondNotification) * 86400)
            }
            
            let noticeTitle = title
            let noticeBody = body
            
            let triggerDate = pureTargetDate.addingTimeInterval(daysAheadTrigger)
            let desiredNoticeTime = triggerDate.addingTimeInterval(noticeTime)
            let type: NotificationType = type
            let noticeNumber: Int = i
            
            await addReminder(
                for: forObject,
                title: noticeTitle,
                body: noticeBody,
                onDate: desiredNoticeTime,
                notificationType: type,
                noticeNum: noticeNumber
            )
            
        }//:LOOP
        
         // MARK: - LIVE EVENT ONLY Notifications
        if objType == .live {
            // Notifications scheduled for hours / minutes ahead
            // Multiplying by 60 because the Settings keys that these variables point to
            // return a Double value that represents the number of minutes ahead that the
            // user wishes to receive a notification for
            let firstAlert = (firstLiveEventAlert * 60)
            let secondAlert = (secondLiveEventAlert * 60)
            
            // Scheduling notifications
            for j in 1...2 {
                let minutesAheadTrigger: Double = Double((j == 1) ? firstAlert : secondAlert)
                guard minutesAheadTrigger > 0 else { continue }
                
                let liveAlertTitle: String
                let liveAlertBody: String
                
                if let titleString = timeTitle, let bodyString = timeBody {
                    liveAlertTitle = titleString
                    liveAlertBody = bodyString
                } else if let titleString = timeTitle, timeBody == nil {
                    liveAlertTitle = titleString
                    liveAlertBody = body
                } else if let bodyString = timeBody, timeTitle == nil {
                    liveAlertTitle = title
                    liveAlertBody = bodyString
                } else {
                    liveAlertTitle = title
                    liveAlertBody = body
                }
                
                let triggerTime = noticeForDate.addingTimeInterval(-minutesAheadTrigger)
                let type: NotificationType = type
                let noticeNumber: Int = j
                
                await addReminder(
                    for: forObject,
                    title: liveAlertTitle,
                    body: liveAlertBody,
                    onDate: triggerTime,
                    notificationType: type,
                    noticeNum: noticeNumber
                 )
            }//: LOOP
        }//: IF LIVE
    }// createObjectNotifications
    
    //MARK: Removing & Updating Reminders
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
    
    /// Method for removing any existing CE Achievement award notifications from the UNUserNotificationCenter.
    /// - Parameters:
    ///   - award: Award object for which the notification is to be removed
    ///   - type: NotificationType (default: .achievementEarned) - should not be changed for the purposes of this method
    ///
    ///   Will also remove the Award from the notifiedCEAchievements Set (in DataController, main file) in order to ensure that the
    ///   notification will be shown to the user in the future since it was cancelled.
    func removeEarnedAchievementReminders(for award: Award, type: NotificationType = .achievementEarned) {
        let center = UNUserNotificationCenter.current()
        
            let uniqueID = award.id
            let noticeNum: Int = Int(award.name.count)
            let identifier = "\(uniqueID)-\(type.rawValue).\(noticeNum)"
            
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
        
            // Removing the award from the notifiedCEAchievements Set becuase the notification was
            // cancelled before being shown to the user, so want to make sure it can be shown to
            // the user again.
            if notifiedCEAchievements.contains(award) {
                notifiedCEAchievements.remove(award)
            }
    }//: removeEarnedAchievementReminders()
    
    /// This method removes any pending notifications for all eligible objects in the UNNotificationCenter.  Specifically,
    /// those objects are CeActivities set to be expiring in the near future, any RenewalPeriods that are about to end, and
    /// any DisciplinaryActionItems that are temporary or have a requirement with a time-sensitive deadline (ex. for extra CE hours
    /// or community service requirement).
    func removeAllReminders() async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
    }//: removeAllReminders
    
    /// Method for refreshing the stored notifications in UNUserNotificationCenter for all applicable objects in this app. Upon being called,
    /// all existing notifications are removed via the removeAllReminders method and then new notifications are generated by the respective
    /// object-specific methods in DataController-Notifications, Object Fetching section.
    ///
    /// - Note: The scheduleEarnedAwardNotifications method is NOT called here because of how the app keeps track of which achievements
    /// have been earned. The removeAllReminders function would get rid of all achievement notifications BUT it would not remove them from the
    /// notifiedCEAchievements DataController property, which would mean that as new achievements are earned they would be scheduled and
    /// then added to the property but would never be removed.  Effectively, the user would likely never see them.  Therefore, this particular method
    /// will be called separately in a Task apart from the other notification methods.
    func updateAllReminders() async {
        await removeAllReminders()
        
        await scheduleUpcomingLiveActivities()
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
    
    /// Method for capturing all CE related achievements that have been earned by the user for the purpose of notifying them.
    /// - Returns: Array of Award objects that produce a result of true when used as the argurment for the hasEarned(award)
    /// method.
    func fetchEarnedAchievements() -> [Award] {
        let possibleAchievements = Award.allAwards
        let earnedAwards = possibleAchievements.filter {hasEarned(award: $0)}
        return earnedAwards
    }//: fetchEarnedAchievements()
    
    
    // MARK: - Object Specific Notifications
    // ** It is important that all of the methods in this section are included
    // in the updateAllReminders() method **
    
    /// Method for creating notifications based on any new CE achievements that the user earns.
    ///
    /// All previously earned achievements are stored as a Set in the DataController @Published property notifiedCEAchievements, and is used
    /// to compare what has already been earned with all earned achievements from the fetchEarnedAchivements method.  Only those that are
    /// truly new for the user will have a notification scheduled.  The timing for the notifications is set to a random number of
    /// minutes (between 1 to 30) from the current date & time to allow for spacing if multiple achievements are scheduled at the same time.
    ///
    ///- Important: This method needs to be called separately from the updateAllReminders method due to the fact that achievement
    /// notifications are directly tied to the values inside of the notifiedCEAchievements property and therefore should not be removed unless
    /// the removeEarnedAchievementReminders method can be called to both remove the notifcation AND the entry in the notifiedCEAchievements
    /// set in DataController.
    ///
    /// - Note: Due to the fact that the Award struct does not inherit from NSManagedObject, two separate methods were created to allow
    /// for non-CoreData objects to get notifications scheduled, and they are based around objects conforming to Identifiable.
    func scheduleEarnedAwardNotifications() async {
        let currentlyEarnedAwards = fetchEarnedAchievements()
        guard currentlyEarnedAwards.isNotEmpty else { return }
        
        for achievement in currentlyEarnedAwards {
            guard notifiedCEAchievements.doesNOTContain(achievement) else { continue }
            
            // Scheduling the notification for a random number of minutes from current time
            // between 1 and 30 minutes
            let calendar = Calendar.current
            let triggerDate = Date.now
            let timerSpacer: Int = Int.random(in: 1...30)
            let triggerComponents = DateComponents(calendar: .current, minute: timerSpacer)
            let triggerTime = calendar.date(byAdding: triggerComponents, to: triggerDate)
            
            if let notificationDate = triggerTime {
                let title: String = "Congratulations! Another CE Achievement Earned!"
                let body: String = "You just met the criteria to earn the CE award '\(achievement.name)' by \(achievement.notificationText) Keep up the amazing work with your CEs!"
                
                let noticeType: NotificationType = .achievementEarned
                let noticeNumber: Int = Int(achievement.name.count)
                
                await addNonCoreDataObjReminder(
                    for: achievement,
                    title: title,
                    body: body,
                    onDate: notificationDate,
                    notificationType: noticeType,
                    noticeNum: noticeNumber
                )
            }//: IF LET
        }//: LOOP

    }//: scheduleEarnedAwardNotifications()
    
    /// This method creates two notifications for each CeActivity which meets the inclusion criteria for being an upcoming,
    /// expiring actiivty.  Each notification's trigger date is determined by what the user entered in settings for primary and
    /// secondary notification day intervals.
    func scheduleExpiringCEsNotifications() async {
        guard showExpiringCesNotifications == true else { return }
        let expiringCes = fetchUpcomingExpiringCeActivities()
        guard expiringCes.isNotEmpty else { return }
        
            // Creating notifications
            for ce in expiringCes {
                let title = ce.ceTitle
                guard let expiresOn = ce.expirationDate, ce.expirationReminderYN == true else { continue }
                    let daysToExpiration = (expiresOn.timeIntervalSinceNow) / 86400
                    let body = "This CE activity ^[is scheduled to expire \(Int(daysToExpiration)) day](inflect:true) from now! Make sure you complete it before then if you wish to count it for the current renewal period."
                
                await createObjectNotifications(
                    forObject: ce,
                    objType: .nonLive,
                    noticeForDate: expiresOn,
                    title: title,
                    body: body,
                    type: .upcomingExpiration
                )
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
        guard showRenewalEndingNotifications == true else {return}
            let endingRenewalPeriods = getCurrentRenewalPeriods()
            guard endingRenewalPeriods.isNotEmpty else { return }
            
            // Scheduling a 6 month renewal notification
            // Note: first & second notifications do NOT apply to this particular notification
            for period in endingRenewalPeriods {
                guard let endsOn = period.periodEnd, period.renewalCompletedYN == false else { continue }
                let credName = period.credential?.credentialName ?? "credential"
                let title = "6 months remaining until renewal!"
                let body = "Time flies! You only have six months left before your \(credName) expires. Now is the time to start working on getting all your required CEs if you haven't done so yet."
                
                if let triggerDate = getCustomMonthsLeftInRenewalDate(months: -6, renewal: period) {
                   await createObjectNotifications(
                    forObject: period,
                    noticeForDate: endsOn,
                    title: title,
                    body: body,
                    type: .sixMonthAlert,
                    singleNoticeYN: true,
                    customNoticeDate: triggerDate
                   )
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
                
                await createObjectNotifications(
                    forObject: period,
                    noticeForDate: windowOpens,
                    title: title,
                    body: body,
                    type: .renewalProcessStarting,
                    singleNoticeYN: true,
                    customNoticeDate: windowOpens
                )
            }//: LOOP
            
            
            // Scheduling notifications related to the renewal period end date
            for period in endingRenewalPeriods {
                guard let endDate = period.periodEnd, period.renewalCompletedYN == false else { continue }
                let credName = period.credential?.credentialName ?? "your credential"
                let title = "The \(period.renewalPeriodName) for \(credName) ends soon!"
                let daysRemaining = Int((endDate).timeIntervalSinceNow / 86400)
                let body = "^[You have \(daysRemaining) day](inflect:true) left before your credential expires if you haven't renewed yet!"
                
                 await createObjectNotifications(
                    forObject: period,
                    noticeForDate: endDate,
                    title: title,
                    body: body,
                    type: .renewalEnding
                 )
            }//: LOOP
            
            
            // Scheduling notifications related to each renewal's late fee start date
            for period in endingRenewalPeriods {
                guard showRenewalLateFeeNotifications, period.lateFeeAmount > 0, let lateFeeDate = period.lateFeeStartDate, period.renewalCompletedYN == false, let endDate = period.periodEnd else { continue }
                let credName = period.credential?.credentialName ?? "your credential"
                let title = "The late fee for the \(period.renewalPeriodName) approaches!"
                let daysRemaining = Int((lateFeeDate).timeIntervalSinceNow / 86400)
                let body = "^[You have \(daysRemaining) day](inflect:true) left before renewing your \(credName) will cost you $\(period.lateFeeAmount) extra - renew soon!"
                
                await createObjectNotifications(
                    forObject: period,
                    noticeForDate: lateFeeDate,
                    title: title,
                    body: body,
                    type: .lateFeeStarting
                )
                
                // Adding same day late fee starting notification if user still has not renewed
                let sameDayTitle = "The late fee for the \(period.renewalPeriodName) starts TODAY!"
                let daysLeftToRenew = Int((endDate).timeIntervalSinceNow / 86400)
                let sameDayBody = "Unfortunately,renewing your \(credName) will now cost you $\(period.lateFeeAmount) extra. You only have \(daysLeftToRenew) days left to renew, so make sure you do so before \(endDate). Otherwise, your credential will lapse and you will need to reinstate it."
                
                await createObjectNotifications(
                    forObject: period,
                    noticeForDate: lateFeeDate,
                    title: sameDayTitle,
                    body: sameDayBody,
                    type: .lateFeeBeginsToday,
                    singleNoticeYN: true,
                    customNoticeDate: lateFeeDate
                )
            }//: LOOP
    } //: scheduleRenewalsEndingNotifications()
    
    /// Method for scheduling notifications related to DisciplinaryActionItem objects
    /// that meet specific criteria.  Only creates notifications if user is current a Pro subscriber as
    /// DisciplinaryActionItems are only available at that purchase level.
    ///
    /// Four different notifications are created by this method, and they are for:
    /// - Reminding users of when any temporary disciplinary action is coming to an end
    /// - Upcoming deadline for completing any required community service hours
    /// - Upcoming deadline for paying any associated fines
    /// - Upcoming deadline for completing any remedial CE requirements
    ///
    /// All notifications are created by the createObjectNotifications method within DataController-Notifications.  All objects
    /// which meet the criteria will have two notifications scheduled based on the primary and secondary notification days
    /// settings.
    func scheduleDisciplinaryActionNotifications() async {
        guard showDAINotifications == true, purchaseStatus == PurchaseStatus.proSubscription.id else {return}
        
            let allDAIS = fetchActiveDisciplinaryActions()
            guard allDAIS.isNotEmpty else {return}
        
            let calendar = Calendar.current
            let todaysDate = calendar.startOfDay(for: Date())
            
            // MARK: Scheduling DAI end date notifications (for temporary actions ONLY)
            for dai in allDAIS {
                guard let endsOn = dai.actionEndDate, endsOn > todaysDate else { continue }
                let credName = dai.credential?.credentialName ?? "your credential"
                
                let title = "The \(dai.daiActionName) for \(credName) ends soon!"
                let daysRemaining = Int((dai.actionEndDate ?? Date.probationaryEndDate).timeIntervalSinceNow / 86400)
                let body = "^[You have \(daysRemaining) day](inflect:true) left before the \(dai.daiActionType) period taken against your credential ends.  Be sure that you have completed all required actions by the governing body by this date."
                    
                await createObjectNotifications(
                    forObject: dai,
                    noticeForDate: endsOn,
                    title: title,
                    body: body,
                    type: .disciplineEnding
                )
            }//: LOOP
            
            // MARK: Scheduling community service due date notifications
            for dai in allDAIS {
                guard let serviceDue = dai.commServiceDeadline, serviceDue > todaysDate, dai.commServiceCompletedOn == nil else { continue }
               
                let title = "Community service hours due soon!"
                let daysRemaining = Int((dai.commServiceDeadline ?? Date.probationaryEndDate).timeIntervalSinceNow / 86400)
                let body = "^[You have \(daysRemaining) day](inflect:true) left ^[before the \(dai.commServiceHours) hour](inflect:true) of community service must be completed.  Be sure that you have completed all required hours by this date."
                    
                await createObjectNotifications(
                    forObject: dai,
                    noticeForDate: serviceDue,
                    title: title,
                    body: body,
                    type: .serviceDeadlineApproaching
                )
            }//: LOOP
            
        
            // MARK: Scheduling DAI fine deadline notifications
            for dai in allDAIS {
                guard let fineDue = dai.fineDeadline, dai.finePaidOn == nil else { continue }
                let credIssuer = dai.credential?.issuer?.issuerName ?? "governing body"
              
                let title = "Fine due soon!"
                let daysRemaining = Int((dai.fineDeadline ?? Date.probationaryEndDate).timeIntervalSinceNow / 86400)
                let body = "^[You have \(daysRemaining) day](inflect:true) left before the $\(dai.fineAmount) fine levied against your credential is due to the \(credIssuer).  Be sure that you have paid it  by this date."
                   
                await createObjectNotifications(
                    forObject: dai,
                    noticeForDate: fineDue,
                    title: title,
                    body: body,
                    type: .fineDeadlineApproaching
                )
            }//: LOOP
            
            
            // MARK: Scheduling DAI extra CE hours deadline notifications
            for dai in allDAIS {
                guard let ceDue = dai.ceDeadline, dai.daiActionEndDate > todaysDate else { continue }
                let credName = dai.credential?.credentialName ?? "your credential"
              
                let title = "Mandated CE hours due soon!"
                let daysRemaining = Int((dai.ceDeadline ?? Date.probationaryEndDate).timeIntervalSinceNow / 86400)
                let body = "^[You have \(daysRemaining) day](inflect:true) left ^[before the \(dai.disciplinaryCEHours) hour](inflect:true) of required continuing education hours must be completed for your \(credName).  Be sure that all hours are completed by this day."
                    
                await createObjectNotifications(
                    forObject: dai,
                    noticeForDate: ceDue,
                    title: title,
                    body: body,
                    type: .ceHoursDeadlineApproaching
                )
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
    func scheduleUpcomingLiveActivities() async {
        guard showAllLiveEventAlerts else { return }
        
        let eligibleActivities = fetchUpcomingCeActivities()
        guard eligibleActivities.isNotEmpty else {return}
        
        // Creating and scheduling the two notifications for each activity
        for activity in eligibleActivities {
            guard let startTime = activity.startTime else { continue }
            let startDate = startTime.formatted(date: .numeric, time: .omitted)
            let time = startTime.formatted(date: .omitted, time: .shortened)
            
            // Day-based notification variables and constants
            let daysUntilEvent: Int = Int((startTime.timeIntervalSinceNow) / 86400)
            let title: String = "Live CE activity coming up!"
            let body: String = "Don't miss the live CE activity, \(activity.ceTitle), on \(startDate) at \(time)! It's only \(daysUntilEvent) away from now!"
            
            // Time based notification variables & constants
            let timeUntilEvent: Int = Int(startTime.timeIntervalSinceNow / 60)
            let timeReminderTitle: String = "Live CE activity coming up!"
                
            // Property for any item reminders that the user needs to bring
            let itemsReminder: Bool = (activity.ceItemsToBring.trimmingCharacters(in: .whitespacesAndNewlines) != "")
                
            let timeReminderBody: String = "Don't miss the live CE activity, \(activity.ceTitle), starting in \(timeUntilEvent) minutes at \(time)!\(itemsReminder ? " Also, don't forget to bring: \(activity.ceItemsToBring)." : "")"
                
            await createObjectNotifications(
                forObject: activity,
                objType: .live,
                noticeForDate: startTime,
                title: title,
                body: body,
                timeTitle: timeReminderTitle,
                timeBody: timeReminderBody,
                type: .liveActivityStarting
            )
        }//: LOOP (activity in eligibleActivities)
    }//: scheduleUpcomingLiveActivities()
    
    /// Method that schedules reminders for any live CE activities where prior registration is marked as being required and
    /// the user has not yet registered yet.
    ///
    /// Not all CE activities may set a deadline for registration, but for those that do the method will generate notifications
    /// based on the activityRegistrationDeadlineYN and registrationDeadline (Date) properties. If a deadline is not set or
    /// not entered by the user, then notifications will be based on the activity's starting date.
    func scheduleRegistrationReminders() async {
        guard showAllLiveEventAlerts else { return }
        let calendar = Calendar.current
        let upcomingCEs = fetchUpcomingCeActivities()
        var liveActivitiesForNotifications: [CeActivity] = []
        
        liveActivitiesForNotifications = upcomingCEs.filter {
            if $0.registrationRequiredYN {
                // If there is a deadline, then a date should be entered and it needs to be still future yet
                // AND the user hasn't registered yet (registeredOn is nil)
                if $0.registrationDeadlineYN, let deadline = $0.registrationDeadline, deadline > Date.now, $0.registeredOn == nil {
                    return true
                } else if $0.registeredOn == nil {
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        }//: FILTER
        guard liveActivitiesForNotifications.isNotEmpty else { return }
        
        // Creating & scheduling the notifications
        for ce in liveActivitiesForNotifications {
            // Notifications if there is a deadline involved
            if ce.registrationDeadlineYN, let deadline = ce.registrationDeadline, let activityStarts = ce.startTime {
                    let pureDeadline = calendar.startOfDay(for: deadline)
                    let daysUntilDeadline: Int = Int(pureDeadline.timeIntervalSinceNow / 86400)
                    
                    let title: String = "Registration Deadline Approaching!"
                    let body: String = "Only \(daysUntilDeadline) days remain to register for the CE activity '\(ce.ceTitle)' on \(activityStarts.formatted(date: .numeric, time: .omitted)), so be sure to do so at your earliest convenience if you are still interested in attending."
                    
                    await createObjectNotifications(
                        forObject: ce,
                        noticeForDate: deadline,
                        title: title,
                        body: body,
                        type: .registrationDeadline
                    )
                
                    // Notifications when there is no deadline (or one entered)
                } else if ce.registeredOn == nil, let activityStarts = ce.startTime {
                    let pureStart = calendar.startOfDay(for: activityStarts)
                    let daysUntilStart: Int = Int(pureStart.timeIntervalSinceNow / 86400)
                    
                    let title: String = "Activity Starting Soon - Register Now"
                    let body: String = "Only \(daysUntilStart) days remain before the CE activity '\(ce.ceTitle)' begins on \(pureStart.formatted(date: .numeric, time: .omitted)) at \(activityStarts.formatted(date: .omitted, time: .shortened)). Registration is required for you to participate, so be sure to get that done prior to that time."
                    
                    await createObjectNotifications(
                        forObject: ce,
                        noticeForDate: activityStarts,
                        title: title,
                        body: body,
                        type: .registrationNeeded
                    )
                } else {
                    return
                }//: IF ELSE
        }//: LOOP (for ce in liveActivitiesForNotifications)
    }//: scheduleRegistrationReminders
    
    /// Method for scheduling notifications related to ReinstatementInfo objects.
    /// If the showReinstatementAlerts settings is set to true, then notifications will be
    /// generated for ReinstatementInfo objects when other criteria is met.
    ///
    /// This method just calls three sub-methods for generating individual notifications based on various credential
    /// reinstatement requirements and circumstances.  Those methods are:
    /// - scheduleReinstatementDeadlineNotifications()
    /// - scheduleReinstatementInterviewNotifications()
    /// - scheduleReinstatementTestingNotifications()
    ///
    /// - Important: Notifications will only be generated if the user also happens to be
    /// a Pro subscriber (annual or monthly) as the ReinstatementInfo object is only available to
    /// users at that purchase level.
    func scheduleRelevantReinstatementInfoNotifications() async {
        guard showReinstatementAlerts, purchaseStatus == PurchaseStatus.proSubscription.id else { return }
        
        await scheduleReinstatementDeadlineNotifications()
        await scheduleReinstatmentInterviewNotifications()
        await scheduleReinstatementTestingNotifications()
        
    }//: scheduleRelevantReinstatementInfoNotifications()
    
    // MARK: - OBJECT SUB METHODS
    /// Submethod intended for use and calling within DataController's scheduleRelevantReinstatementInfoNotifications method.
    ///
    /// Calls the createObjectNotifications method for creating all notifications - must be used within the DataController-Notifications file.
   private func scheduleReinstatementDeadlineNotifications() async {
        guard showReinstatementAlerts else { return }
        
        let calendar = Calendar.current
        let relevantRIs = fetchCurrentReinstatmentItems()
        guard relevantRIs.isNotEmpty else { return }
        
        for relevantRI in relevantRIs {
            // deadline approaching notifications
            guard let riDeadline = relevantRI.reinstatementDeadline else { continue }
            let pureDeadline = calendar.startOfDay(for: riDeadline)
            let daysToDeadline = Int(pureDeadline.timeIntervalSinceNow / 86400)
            
            let title: String = "Reinstatement Deadline/Goal Approaching"
            let body: String = "This is a friendly reminder that there are only \(daysToDeadline) days left to reinstate your credential (if this date is a goal you set versus a hard deadline set by the licensing board or governing body, then try to get everything done by then). Please ensure that you are on track towards getting everything done that is needed for reinstatement by \(pureDeadline.formatted(date: .abbreviated, time: .omitted))."
            
            await createObjectNotifications(
                forObject: relevantRI,
                noticeForDate: riDeadline,
                title: title,
                body: body,
                type: .reinstatementDeadline
            )
        }//: LOOP
    }//: scheduleReinstatementDeadlineNotifications()
    
    /// Submethod intended for use and calling within DataController's scheduleRelevantReinstatementInfoNotifications method for
    /// generating notifications for any ReinstatementInfo objects where an interview with a licensing board or other governing body
    /// is required in order for the user to reinstate a lapsed credential.
    private func scheduleReinstatmentInterviewNotifications() async {
        guard showReinstatementAlerts else { return }
        
        let calendar = Calendar.current
        let relevantRIs = fetchCurrentReinstatmentItems()
        guard relevantRIs.isNotEmpty else { return }
        
        for relevantRI in relevantRIs {
            guard let interviewDate = relevantRI.interviewScheduled, interviewDate > Date.now else { continue }
            let pureInterviewDate = calendar.startOfDay(for: interviewDate)
            let dateString = pureInterviewDate.formatted(date: .numeric, time: .omitted)
            let timeString = interviewDate.formatted(date: .omitted, time: .shortened)
            
            // Day based notification values
            let daysToInterview = Int(pureInterviewDate.timeIntervalSinceNow / 86400)
            
            let interviewDayTitle: String = "Reinstatement Interview Approaching"
            let interviewDayBody: String = "Don't forget that you have an important interview coming up with your credential issuer to help get it reinstated. It is only \(daysToInterview) days away from now, on \(dateString) at \(timeString). Please make sure you have everything ready and on track for this important meeting."
            
            // Time based notification values
            let minutesToEvent = Int(interviewDate.timeIntervalSinceNow / 60)
            guard minutesToEvent > 0 else { continue }
            
            let interviewTimeTitle: String = "Reinstatement Interview Reminder"
            let interviewTimeBody: String = "You have an important interview coming up with your credential issuer to help get it reinstated. It will start in \(minutesToEvent) minutes at \(timeString). Please make sure you have everything ready and on track for this important meeting."
            
            await createObjectNotifications(
                forObject: relevantRI,
                objType: .live,
                noticeForDate: interviewDate,
                title: interviewDayTitle,
                body: interviewDayBody,
                timeTitle: interviewTimeTitle,
                timeBody: interviewTimeBody,
                type: .interview
            )
        }//: LOOP
    }//: scheduleReinstatementInterviewNotifications()
    
    /// Submethod intended for use and calling within DataController's scheduleRelevantReinstatementInfoNotifications method for
    /// any situations in which the holder of a lapsed credential is required by their licensing or governing board to take a recertification,
    /// licensing, or other knowledge-based exam in order to reinstate the credential.
    private func scheduleReinstatementTestingNotifications() async {
        guard showReinstatementAlerts else { return }
        
        let relevantRIs = fetchCurrentReinstatmentItems()
        guard relevantRIs.isNotEmpty else { return }
        
        for relevantRI in relevantRIs {
            guard let testDate = relevantRI.additionalTestDate, testDate > Date.now else { continue }
            let testDateString = testDate.formatted(date: .numeric, time: .omitted)
            let testTimeString = testDate.formatted(date: .omitted, time: .shortened)
                
            let daysToTest = Int(testDate.timeIntervalSinceNow / 86400)
               
            let testTitle: String = "Credential Re-Test Date Approaching"
            let testBody: String = "As part of your credential reinstatement, the governing body requires you to take an exam, which is now only \(daysToTest) days away on \(testDateString) at \(testTimeString). Study hard!"
                
            await createObjectNotifications(
                forObject: relevantRI,
                noticeForDate: testDate,
                title: testTitle,
                body: testBody,
                type: .additionalTestDate
            )
        }//: LOOP
    }//: scheduleReinstatementTestingNotifications()
    
}//: DATA CONTROLLER

