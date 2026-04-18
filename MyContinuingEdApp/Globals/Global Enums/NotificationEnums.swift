//
//  NotificationEnums.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/17/26.
//

import Foundation


// MARK: - Notification ENUMs

/// Enum used primarily for creating suffix values that will be appended to the string UUID values of Core Data
/// entities as part of their unique NotificationCenter identifier value. This will allow for multiple notifications for the same
/// object to be created.
enum NotificationType: String, CaseIterable {
    case upcomingExpiration
    case renewalProcessStarting
    case renewalEnding
    case sixMonthAlert
    case lateFeeStarting
    case lateFeeBeginsToday
    case disciplineEnding
    case serviceDeadlineApproaching
    case fineDeadlineApproaching
    case ceHoursDeadlineApproaching
    case liveActivityStarting
    case reinstatementDeadline
    case interview
    case additionalTestDate
    case registrationDeadline
    case registrationNeeded
    case achievementEarned
}//: NotificationType

/// Enum used to identify whether the argument being passed into the DataController's createObjectNotifications objType
/// parameter represents a live or non-live event.  This will determine the total number of notifications scheduled.
///
/// Depending on the settings for live event alert notifications, up to 4 total notifications will be scheduled versus just
/// two for non-live notifications. Most objects for which notifications are created are considered to be non-live, such
/// as renewal period related deadlines, disciplinary action related alerts, and expiring CEs.  CeActivities which are
/// a live activity (ex. conference, simulation, webinar, etc.) are considered to be live so additional alerts will be made
/// for them unless the user explicitly indicates they don't want them via settings.
enum ObjectCategory {
    case live, nonLive
}//: NOTIFICATION TARGET

/// Enum used to configure notifications for display at a specified time of day within the DataController's createObjectNotifications
/// method.
///
/// These values correlate with the static properties in the Double extension where the number of seconds from midnight until
/// a given time (10am, 3pm, and 7pm) are calculated.  The createObjectNotifications method will read the enum value argument
/// and then pass in the corresponding Date static property for configuring the time a notification should be shown.
enum TimePreference {
    case morning, afternoon, evening
}//: TimePreference
