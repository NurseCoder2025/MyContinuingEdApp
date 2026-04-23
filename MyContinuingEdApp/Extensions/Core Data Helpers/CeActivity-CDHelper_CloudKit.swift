//
//  CeActivity-CDHelper_CloudKit.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/18/26.
//

import CloudKit
import CoreData
import Foundation


extension CeActivity: DelayedParentObjDeletion {
    
    func prepareForDeletion(dataController: DataController) async {
        self.isMarkedForDeletion = true
        self.deletionTimeStamp = Date()
        dataController.save()
        
        await deleteAssociatedCert()
        
        // TODO: Add code for deleting associated audio reflections
        
    }//: prepareForDeletion(dataController)
    
    
    // MARK: - HELPERS
    
    private func deleteAssociatedCert() async {
        if let certInfo = self.certificate,
            let recID = certInfo.certCKRecordID as? CKRecord.ID, recID.recordName != String.mediaIdPlaceholder,
            let certModel = certInfo.createMediaModelForCertInfo() {
            
            let cloudBrain = CloudMediaBrain.shared
            let noticeCenter = NotificationCenter.default
            
            let ckRecDeletionResult = await cloudBrain.deleteEntireRecord(for: recID, using: certModel)
            switch ckRecDeletionResult {
            case .success(_):
                noticeCenter.post(
                    name: .cloudRecordDeletedSuccessfully,
                    object: self
                )//: post
            case .failure(let error):
                NSLog(">>> CeActivity method error: prepareForDeletion")
                NSLog(">>> Unable to delete the CKRecord associated with the CeActivity '\(self.ceTitle)'")
                NSLog("Details: \(error.localizedDescription)")
                noticeCenter.post(
                    name:  .cloudRecordDeletionFailed,
                    object: self,
                    userInfo: [
                        String.recordNotDeletedKey: recID,
                        String.cloudDeletionErrorKey: error
                     ]
                )//: post
            }//: SWITCH
            
            if let localURL = certInfo.resolveURL(basePath: URL.localCertificatesFolder) {
                try? FileManager.default.removeItem(at: localURL)
            }//: IF LET (localURL)
            
        } else if let certInfo = self.certificate, let localURL = certInfo.resolveURL(basePath: URL.localCertificatesFolder) {
            try? FileManager.default.removeItem(at: localURL)
        }//: IF LET (certInfo)
    }//: deleteAssociatedCerts(in)
    
}//: EXTENSION
