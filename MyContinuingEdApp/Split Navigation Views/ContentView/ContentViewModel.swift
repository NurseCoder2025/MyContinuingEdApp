//
//  ContentViewModel.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/27/25.
//

import CoreData
import Foundation
import SwiftUI
import UIKit

extension ContentView {
    
    class ViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
        // MARK: - PROPERTIES
        var dataController: DataController
        
        @Environment(\.spotlightCentral) var spotlightCentral
        
        // Properties for deleting an activity in the activity list
        @Published var activityToDelete: CeActivity?
        @Published var showDeleteWarning: Bool = false
        
        @Published var showUpcomingRenewalEndingBox: Bool = false
        
        // MARK: - CORE DATA
        // These properties are needed in order to select the proper
        // view to show in ContentView, depending on whether the
        // user is brand new to the app or simply hasn't added
        // any CE activities to it.
        private let credsController: NSFetchedResultsController<Credential>
        @Published var allCredentials: [Credential] = []
        
        private let activitiesController: NSFetchedResultsController<CeActivity>
        @Published var allActivities: [CeActivity] = []
        
        // MARK: - COMPUTED PROPERTIES
        var computedCEActivityList: [CeActivity] {dataController.activitiesForSelectedFilter()}
        
        /// Computed property used to create headings in the list of CeActivities based on the first letter of each activity so that all activities are grouped
        /// alphabetically
        var alphabeticalCEGroupings: [String : [CeActivity]] {
            Dictionary(grouping: computedCEActivityList) { activity in
                String(activity.ceTitle.prefix(1).uppercased())
            }
        }//: alphabeticalCEGroupings
        
        /// Computed property that returns a string of all letters present in entered CeActivities (keys in the alphabeticalCEGroupings property)
        var sortedKeys: [String] {
            alphabeticalCEGroupings.keys.sorted()
        }
        
        /// Computed property used to determine when to request iOS prompt the user to rate
        /// the app on the AppStore.  Criteria are:  at least 5 tags and 5 CE activities have been
        /// entered (meaning the user has made an in-app purchase and then continued to use the
        /// app for a little bit after purchasing).
        var shouldRequestReview: Bool {
            let tagCount = dataController.count(for: Tag.fetchRequest())
            let activityCount = dataController.count(for: CeActivity.fetchRequest())
            
            // TODO: Replace debug code with return true for release code
            #if DEBUG
            if tagCount >= 5 && activityCount >= 5 {
                dataController.requestReviewCount += 1
                
                if dataController.requestReviewCount.isMultiple(of: 100) {
                    return true
                }//: IF (requestReviewCount)
            }//: IF
            #endif
            
            return false
        }//: shouldRequestReview
        
        // MARK: - FUNCTIONS
        func delete(activity: CeActivity) {
            activityToDelete = activity
            showDeleteWarning = true
            
            if showDeleteWarning {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
            
        } //: DELETE Method
        
        /// Method for the ContentView view model that ONLY deletes a CeActivity object in CoreData.
        /// - Parameter activity: CeActivity object that is to be deleted
        ///
        /// - Important: If the activity argument happens to have any media files associated with
        /// it (ex. certificate and/or audio reflections), and those are not deleted prior to calling this
        /// method then they will remain stored and coordinator objects will continue to be made for them,
        /// though the assignedObjectId property will be referencing an activity that no longer exists. This will
        /// cause more space to be taken up on the user's device and on iCloud.
        func deleteCeActivityCoreDataObject(_ activity: CeActivity) {
            if #available(iOS 17.0, *) {
                dataController.delete(activity)
            } else {
                spotlightCentral?.removeCeActivityFromDefaultIndex(activity)
                dataController.delete(activity)
            }//: IF #available
        }//: deleteCeActivityCoreDataObject(_ activity)
        
        /// Method for updating the values of allCredentials and allActivities whenever a Credential or
        /// CeActivity object is added/deleted.  This method will then update the view model properties
        /// so that UI depending on those properties will be updated.
        /// - Parameter controller: either the credsController or activitiesController as defined in
        ///  the ContentView's view model properties list.
        func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
            if controller == credsController {
                if let newCreds = controller.fetchedObjects as? [Credential] {
                    allCredentials = newCreds
                }
            } else if controller == activitiesController {
                if let newActivities = controller.fetchedObjects as? [CeActivity] {
                    allActivities = newActivities
                }
            }//: IF ELSE
        } //: controllerDidChangeContent()
        
        
        
        
        
        // MARK: - INIT
        init(dataController: DataController) {
            self.dataController = dataController
            
            let credRequest = Credential.fetchRequest()
            credRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Credential.name, ascending: true)]
            
            let activityRequest = CeActivity.fetchRequest()
            activityRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CeActivity.activityTitle, ascending: true)]
            
            credsController = NSFetchedResultsController(
                fetchRequest: credRequest,
                managedObjectContext: dataController.container.viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            activitiesController = NSFetchedResultsController(
                fetchRequest: activityRequest,
                managedObjectContext: dataController.container.viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
                )
            
            super.init()
            credsController.delegate = self
            activitiesController.delegate = self
            
            do {
                try credsController.performFetch()
                allCredentials = credsController.fetchedObjects ?? []
                
                try activitiesController.performFetch()
                allActivities = activitiesController.fetchedObjects ?? []
            } catch {
                NSLog(">>>ContentViewModel init error: \(error.localizedDescription)")
                NSLog(">>>Failed to load any credentials or activities.")
            }
            
        }//: INIT
        
    }//: VIEW MODEL
    
    
}//: EXTENSION
