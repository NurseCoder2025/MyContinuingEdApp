//
//  Achievement-CoreDataHelper.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/27/26.
//

import Foundation


extension Achievement {
    // MARK: - UI HELPERS
    
    /// Computed CoreData helper property which gets the id property for an Achievement entity.
    /// If the property happens to be nil, then a new UUID value is returned.
    var achievementID: UUID {
        get {id ?? UUID()}
    }//: achievementID
    
    /// Computed CoreData helper property which returns either the name property for an
    /// Achievement entity or the string "Unnamed Achievement" if nil.  Also sets new values
    /// for the property.
    var achievementName: String {
        get {
            name ?? "Unnamed Achievement"
        }
        set {
            name = newValue
        }
    }//: achievementName
    
    /// Computed CoreData helper property which returns either the achievementDescript
    /// property for an Achievement entity or the string "Add description" if nil.
    /// Also sets new values for the property.
    var achieveDescription: String {
        get {
            achievementDescript ?? "Add description"
        }
        set {
            achievementDescript = newValue
        }
    }//: achieveDescription
    
    /// Computed CoreData helper property which returns either the notificationText
    /// property for an Achievement entity or the string "Add text to show in notifications"
    /// if nil.  Also sets new values for the property.
    var achievementNotificationText: String {
        get {
            notificationText ?? "Add text to show in notifications"
        }
        set {
            notificationText = newValue
        }
    }//: achievementNotificationText
    
    /// Computed CoreData helper property which returns either the criterion property for an
    /// Achievement entity or the string "Need single word criterion for achievement" if nil.
    /// Also sets new values for the property.
    var achievementCriterion: String {
        get {
            criterion ?? "Need single word criterion for achievement"
        }
        set {
            criterion = newValue
        }
    }//: achievementCriterion
    
    /// Computed CoreData helper property which returns either the color property for an
    /// Achievement entity or the string "secondary" if nil.  Also sets new values
    /// for the property.
    ///
    /// - Important: The color property for Achievement is used in AwardsView as part of
    /// the foregroundStyle modifier (as a Color instance), so the string value needs to be a
    /// valid Color or else either a crash will occur or the foregroundStyle will not be applied.
    var achievementColor: String {
        get {
            color ?? "secondary"
        }
        set {
            color = newValue
        }
    }//: achievementColor
    
    /// Computed CoreData helper property which returns either the image property for an
    /// Achievement entity or the string "" if nil.  Also sets new values
    /// for the property.
    ///
    /// - Important: The value for this property needs to be a string corresponding to the
    /// name of an existing SF symbol as that is what is used in AwardsView to show an icon
    /// to represent the achievement.
    var achievementImage: String {
        get {
            image ?? ""
        }
        set {
            image = newValue
        }
        
    }//: achievementImage
    
    /// Computed CoreData helper property which returns either the dateEarned property for an
    /// Achievement entity or the Date.distantPast value if nil.  Also sets new values
    /// for the property.
    var achievementDate: Date {
        get {
            dateEarned ?? Date.distantPast
        }
        set {
            dateEarned = newValue
        }
    }//: achievementDate
    
    /// Computed CoreData helper property which returns either the notifiedOn Date property for an
    /// Achievement entity or the Date.distantPast value if nil.  NO setter.
    var achievementNotifiedOn: Date {
        notifiedOn ?? Date.distantPast
    }//: achievementNotifiedOn
    
}//: EXTENSION
