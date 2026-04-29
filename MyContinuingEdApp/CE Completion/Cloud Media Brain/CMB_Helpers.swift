//
//  CMB_Helpers.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/27/26.
//

import CloudKit
import Foundation

extension CloudMediaBrain {
    
    // MARK: - HELPERS
    
    func retrievePathFromID(recID: CKRecord.ID) -> String {
        var returnedPath: String = ""
        let recName = recID.recordName
        if recName.contains(where: {$0 == "|"}) {
            returnedPath = String(recName.split(separator: "|")[1])
        } else {
            returnedPath = recName
        }//: IF ELSE
        return returnedPath
    }//: retrievePathFromID
    
    func canUserUtilizeCloudSyncFor(mediaType: MediaClass) -> Result<Bool, Error> {
        var userWantsToStoreInCloud: Bool = true
        switch mediaType {
        case .certificate:
            userWantsToStoreInCloud = settings.userCloudBooleanPrefs[.certsInCloud] ?? true
        case .audioReflection:
            userWantsToStoreInCloud = settings.userCloudBooleanPrefs[.audioInCloud] ?? true
        }// SWITCH
        
        let cloudSyncGoAhead: Bool = userIsAPaidSupporter && userWantsToStoreInCloud && iCloudIsAccessible
        
        if cloudSyncGoAhead {
            return Result.success(true)
        } else if userWantsToStoreInCloud == false {
            return Result.failure(CloudSyncError.prefersLocalStorage(mediaType))
        } else if iCloudIsAccessible == false {
            return Result.failure(CloudSyncError.cloudUnavailable)
        } else {
            return Result.failure(CloudSyncError.paidUpgradeNeeded)
        }//: IF ELSE
    }//: canUserUtilizeCloudSync()
    
    func addOrUpdateMasterListEntryWithError(
        forRecord record: CKRecord.ID,
        errorText text: String,
        setDownloadFlag: Bool = false,
        setManDeletionFlag deleteFlag: Bool = false
    ) {
        let masterList = MasterMediaList.shared
        
        if let savedEntry = masterList.getLocalMediaRecord(using: record) {
            savedEntry.errorMessage = text
            if setDownloadFlag {
                savedEntry.shouldReDownload = true
            }//: IF (setDownloadFlag)
            
            if deleteFlag {
                savedEntry.shouldDelete = true
            }//: IF (deleteFlag)
        } else {
            let newEntry = LocalMediaFileInfo(
                id: record,
                mediaURL: nil,
                errorMessage: text,
                manualDownload: setDownloadFlag,
                manualDeletion: deleteFlag
            )//: LocalMediaFileInfo
        }//: IF LET ELSE (savedEntry)
        
        masterList.saveList()
    }//: addOrUpdateMasterListEntryWithError()
    
    func addOrUpdateMasterListEntryNoError(
        forRec record: CKRecord.ID,
        mediaAt savelocation: URL? = nil
    ) {
        let masterList = MasterMediaList.shared
        
        if let savedEntry = masterList.getLocalMediaRecord(using: record) {
            savedEntry.mediaURL = savelocation
            savedEntry.errorMessage = ""
            savedEntry.shouldReDownload = false
            savedEntry.shouldDelete = false
        } else {
            let newEntry = LocalMediaFileInfo(
                id: record,
                mediaURL: savelocation,
                errorMessage: ""
              )//: LocalMediaFileInfo
        }//: IF LET ELSE (savedEntry)
        
        masterList.saveList()
    }//: addOrUpdateMasterListEntryNoError()
    
    func removeMasterListEntry(forRecord record: CKRecord.ID) {
        let masterList = MasterMediaList.shared
        
        if let savedRec = masterList.getLocalMediaRecord(using: record) {
            masterList.removeMediaRecord(withID: savedRec.id)
            masterList.saveList()
        }//: IF LET (savedRec)
    }//: removeMasterListEntry
    
}//: EXTENSION
