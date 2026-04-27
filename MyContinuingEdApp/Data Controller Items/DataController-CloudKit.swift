//
//  DataController-CloudKit.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/15/26.
//

import CloudKit
import CoreData
import Foundation

extension DataController {
    
    // MARK: - MEDIA Notification HANDLING
    
    @objc func handleCloudDbChangedNotification(_ notification: Notification) {
        Task{
            let mediaBrain = CloudMediaBrain.shared
            await mediaBrain.syncLocalMediaFiles()
        }//: TASK
    }//: handleCloudDbChangedNotification
    
    
    // MARK: - CLOUDKIT SETUP
    
    func setupCloudKitItems() async {
        let settings = AppSettingsCache.shared
        guard settings.iCloudState.iCloudIsAvailable else { return }
        
        let _ = await CloudMediaBrain.handleCloudDbSubscriptionSetup()
        await CloudMediaBrain.setupAndVerifyZones()
    }//: setupCloudKitItems
    
    // MARK: - HELPERS
    
    func findCoreDateEntityForSpecifiedRecord<T: NSManagedObject>(
        savedObj: T.Type,
        havingId recID: CKRecord.ID,
        using objIdField: String
    ) -> T? {
        let context = container.viewContext
        
        let coreDataObjectFetch = NSFetchRequest<T>(entityName: String(describing: savedObj))
        let matchingObjectPred: NSPredicate = NSPredicate(
            format: "\(objIdField) == %@",
            recID as NSObject
        )//: matchingCertInfoPred
        
        coreDataObjectFetch.predicate = matchingObjectPred
        let fetchResults = (try? context.fetch(coreDataObjectFetch)) ?? []
        guard fetchResults.count == 1 else { return nil }
        return fetchResults.first
    }//: findCoreDateEntityForSpecifiedRecord
    
   
    
    
}//: DATA CONTROLLER

