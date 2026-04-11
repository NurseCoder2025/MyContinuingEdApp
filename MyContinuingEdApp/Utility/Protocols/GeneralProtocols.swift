//
//  GeneralProtocols.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/28/26.
//

// Only protocols should be placed within this file

import Foundation


/// Protocol for comparing a source of truth (JSON-based structs) and CoreData entities so
/// that objects which are NOT user-editable can be synced between values inside of a
/// JSON file and objects stored in persistent storage as NSManagedObjects.
///
/// To conform to this protocol, add the syncID computed property to a struct or CoreData entity
/// (via extension) and replace the get keyword within the brackets with whatever String based
/// property should be used for comparing the object with its counterpart.
///
/// - Note: This protocol is intended to be used where the number of CoreData objects are
/// limited to a specific number, and that number is controlled via an internal JSON file from which
/// objects are created via a custom struct.  The number of objects created form that file is then used
/// to determine what CoreData objects will be created for the user.  This should not be used on
/// any CoreData entity where the user is allowed to create and delete
/// values for (such as CeDesignation or Country).
///
/// Examples of where this can be used:
///     - PromptQuestionJSON (struct) objects) vs ReflectionPrompt (CoreData) objects
///     - ActivityTypeJSON objects vs ActivityType (CoreData) objects
///     - Award (struct) objecs vs Achievement (CoreData) objects
protocol SyncIdentifiable {
    var syncID: String { get }
}//: PROTOCOL
