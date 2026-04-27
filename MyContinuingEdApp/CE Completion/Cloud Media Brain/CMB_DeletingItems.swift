//
//  CMB_DeletingItems.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/27/26.
//

import CloudKit
import Foundation

extension CloudMediaBrain {
    
    // MARK: - DELETING
    
    func deleteEntireRecord(
        for object: CKRecord.ID,
        using model: MediaModel
    ) async -> Result<Bool, CloudSyncError> {
        guard iCloudIsAccessible else {
            await MainActor.run {
                userErrorMessage = settings.iCloudState.userMessage
            }//: MAIN ACTOR
            return Result.failure(CloudSyncError.cloudUnavailable)
        }//: GUARD
        
        let mediaClass = model.designatedClass
        if let matchingRec = await findMatchingRecordWith(
            recId: object,
            recType: mediaClass,
            using: model
        ) {
            // Delete the entire record
            let recID = matchingRec.recordID
            do {
                _ = try await cloudDB.deleteRecord(withID: recID)
                return Result.success(true)
            } catch {
                return Result.failure(
                    CloudSyncError.mediaDeletionError("Error deleting the iCloud file: \(error.localizedDescription)")
                )//: failure
            }//: DO-CATCH
        } else {
            return Result.failure(
                CloudSyncError.mediaDeletionError("Unable to locate the iCloud record for the \(model.ckRecType.rawValue) you are trying to delete.")
            )//: failure
        }//: IF LET ELSE (matchingRec)
    }//: deleteEntireRecord(for)
    
    
    func removeUploadedCerts(
        certs: [CertificateInfo]
    ) async {
        guard settings.getCurrentPurchaseLevel() == PurchaseStatus.basicUnlock else {
            return
        }//: GUARD
        let nc = NotificationCenter.default
        let certsDeletionDone: Notification = Notification(name: .uploadedCertsDeleted)
        
        for cert in certs {
            let recId = cert.certCloudRecordName
            if let certModel = cert.createMediaModelForCertInfo() {
               let deleteResult = await deleteEntireRecord(for: recId, using: certModel)
                switch deleteResult {
                case .success:
                    cert.ckRecordID = nil
                    cert.uploadedToICloud = false
                case .failure:
                    // TODO: Re-evaluate logic
                    // Should the errorMessage property be assigned a value instead?
                    cert.uploadedToICloud = false
                }//: SWITCH
            }//: IF LET
        }//: LOOP
        nc.post(certsDeletionDone)
    }//: removeUploadedCerts()
    
}//: EXTENSION
