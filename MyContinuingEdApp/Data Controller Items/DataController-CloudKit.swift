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
        
    }//: handleCloudDbChangedNotification
    
    // MARK: - COORDINATING MEDIA CHANGES
    
    func syncLocalMediaFiles() async {
        
        
        
        
    }//: syncLocalMediaFiles()
    
   
    // MARK: - SUB METHODS
    
    private func addNewLocalMediaFile(
        usingRec record: CKRecord.ID,
        repeatCount: Int = 0
    ) async -> Bool {
        let mediaList = MasterMediaList.shared
        let mediaBrain = CloudMediaBrain.shared
        let cloudDB = mediaBrain.cloudDB
        
        let downloadRecResult = await mediaBrain.downloadOnlineMediaFile(for: record)
        switch downloadRecResult {
        case .success(let url):
            mediaList.addMediaRecord(fromRec: record, savedAt: url)
            mediaList.saveList()
            return true
        case .failure(let error):
            NSLog(">>> DataController error: addNewLocalMediaFile")
            NSLog(">>> The downlaodOnlineMediaFile method in CloudMediaBrain returned a Result.failure case.")
            NSLog(">>> Error: \(error.localizedDescription)")
            return false
        }//: SWITCH
    }//: addNewLocalMediaFile()
    
    private func deleteLocallySavedMediaFile(using record: CKRecord.ID) async -> Bool {
        let mediaList = MasterMediaList.shared
        let mediaBrain = CloudMediaBrain.shared
        let fileSystem = FileManager.default
        
        let savedFilePathString: String = mediaBrain.retrievePathFromID(recID: record)
        let fileToDelete: URL = URL.documentsDirectory.appending(path: savedFilePathString, directoryHint: .notDirectory)
        
        do {
            _ = try fileSystem.removeItem(at: fileToDelete)
            mediaList.removeMediaRecord(withID: record)
            mediaList.saveList()
            return true
        } catch {
            NSLog(">>> DataController error: deleteLocallySavedMediaFile")
            NSLog(">>> The fileSystem.removeItem(at:) method threw an error while trying to delete a media file located at \(fileToDelete.absoluteString).")
            return false
        }//: DO-CATCH
    }//: deleteLocallySavedMediaFile()
    
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

