//
//  CMB_CKDatabase.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/27/26.
//

import CloudKit
import Foundation


extension CloudMediaBrain {
    
    // MARK: - CKDATABASE SUBSCRIPTION
    
    func setupInitialCloudDBSubscription(repeatCount: Int = 0) async -> Result<Bool, Error> {
        guard iCloudIsAccessible else {return Result.failure(CloudSyncError.cloudUnavailable)}//: GUARD
        
        let initialDbSub = configureDatabaseSubscription()
        let dbModOp = CKModifySubscriptionsOperation()
        dbModOp.subscriptionsToSave = [initialDbSub]
        
        cloudDB.add(dbModOp)
        return Result.success(true)
    }//: setupInitialCloudDBSubscription
    
    func configureDatabaseSubscription() -> CKDatabaseSubscription {
        return CKDatabaseSubscription(subscriptionID: String.cloudDbSubID)
    }//: configureDatabaseSubscription
    
}//: EXTENSION
