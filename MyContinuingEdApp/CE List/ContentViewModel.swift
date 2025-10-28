//
//  ContentViewModel.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/27/25.
//

import CoreData
import Foundation
import UIKit

extension ContentView {
    
    class ViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
        // MARK: - PROPERTIES
        var dataController: DataController
        
        // Properties for deleting an activity in the activity list
        @Published var activityToDelete: CeActivity?
        @Published var showDeleteWarning: Bool = false
        
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
        
        // MARK: - FUNCTIONS
        func delete(_ offsets: IndexSet) {
            let activities = dataController.activitiesForSelectedFilter()
            
            for offset in offsets {
                let item = activities[offset]
                activityToDelete = item
            }
            
            showDeleteWarning = true
            
            if showDeleteWarning {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
            
        } //: DELETE Method
        
        
        // MARK: - INIT
        init(dataController: DataController) {
            self.dataController = dataController
        }//: INIT
        
    }//: VIEW MODEL
    
    
}//: EXTENSION
