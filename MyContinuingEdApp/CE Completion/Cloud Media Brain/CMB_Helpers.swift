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
    
   
    
}//: EXTENSION
