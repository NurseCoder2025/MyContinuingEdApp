//
//  CMB_Saving.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/27/26.
//

import CloudKit
import Foundation


extension CloudMediaBrain {
    
    // MARK: - SAVING (UPLOADING)
    
    func smartSyncCECertificate(
        using certInfo: CertificateInfo,
        with model: MediaModel
    ) async -> Result<CKRecord.ID, Error> {
       let syncWinSetting: Double = settings.smartSyncCertWindow
       let firstCheck = canUserUtilizeCloudSyncFor(mediaType: .certificate)
        
       switch firstCheck {
       case .success(_):
               let smartSyncEligibility = certInfo.isCertEligibleForSmartSync(syncWindow: syncWinSetting)
               
               switch smartSyncEligibility {
               case .success(_):
                   let certRec = createCKRecord(for: .certificate, with: model)
                   if await saveRecToICloud(record: certRec) {
                       return Result.success(certRec.recordID)
                   } else {
                       Task{@MainActor in
                           certInfo.certErrorMessage = CloudSyncError.cloudSaveError(.certificate).localizedDescription
                       }//: TASK
                       return Result.failure(CloudSyncError.cloudSaveError(.certificate))
                   }//: IF AWAIT
               case .failure(let error):
                   Task{@MainActor in
                       certInfo.certErrorMessage = error.localizedDescription
                   }//: MAIN ACTOR
                   return Result.failure(error)
               }//: SWITCH (smartSyncEligibility)
       case .failure(let error):
           Task{@MainActor in
               certInfo.certErrorMessage = error.localizedDescription
           }//: TASK
           return Result.failure(error)
       }//: SWITCH (firstCheck)
    }//: smartSyncCECertificate
    
    func manualCertUpload(
        for certInfo: CertificateInfo,
        with model: MediaModel
    ) async -> Result<CKRecord.ID, Error> {
        guard iCloudIsAccessible else {
            await MainActor.run {
                userErrorMessage = settings.iCloudState.userMessage
            }//: MAIN ACTOR
            return Result.failure(CloudSyncError.cloudUnavailable)
        }//: GUARD
        guard userIsAPaidSupporter else { return Result.failure(CloudSyncError.paidUpgradeNeeded)
        }//: GUARD
        
        if settings.getCurrentPurchaseLevel() == .basicUnlock {
            let certSyncEligibility = certInfo.isCertEligibleForSmartSync(syncWindow: 0)
            switch certSyncEligibility {
            case .success(_):
                return await manualCertUploadProcess(for: certInfo, using: model)
            case .failure(let error):
                return Result.failure(error)
            }//: SWITCH
        } else {
            return await manualCertUploadProcess(for: certInfo, using: model)
        }//: IF ELSE (getCurrentPurchaseLevel)
        
    }//: manualCertUpload(with)
    
    func syncAudioReflection(
        for audioInfo: AudioInfo,
        using model: MediaModel
    ) async -> Result<CKRecord.ID, Error> {
        guard userIsAProUser else { return Result.failure(CloudSyncError.proLevelPurchaseNeeded) }
        
        let preliminaryCheck = canUserUtilizeCloudSyncFor(mediaType: .audioReflection)
        switch preliminaryCheck {
        case .success(_):
            let newRec = createCKRecord(for: .audioReflection, with: model)
            if await saveRecToICloud(record: newRec) {
                return Result.success(newRec.recordID)
            } else {
                Task{@MainActor in
                    audioInfo.audioErrorMessage = CloudSyncError.cloudSaveError(.audioReflection).localizedDescription
                }//: TASK
                return Result.failure(CloudSyncError.cloudSaveError(.audioReflection))
            }//: IF AWAIT
            
        case .failure(let error):
            Task{@MainActor in
                audioInfo.audioErrorMessage = error.localizedDescription
            }//: TASK
            return Result.failure(error)
        }//: SWITCH
    }//: syncAudioReflection()
    
    // MARK: - SAVE HELPERS
    private func createCKRecord(for objType: MediaClass, with model: MediaModel) -> CKRecord {
        var recType: String = ""
        let mediaName = model.getMediaTypeName()
        let assignedObjString = model.createAssignedObjIdString()
        
        let recAsset = CKAsset(fileURL: model.mediaDataSavedAt)
        var originalTranscription: CKAsset? = nil
        var zoneToUse: CKRecordZone.ID
        var recID: CKRecord.ID
        
        switch objType {
        case .certificate:
            zoneToUse = certZone.zoneID
            recType = CkRecordType.certificate.rawValue
        case .audioReflection:
            zoneToUse = audioZone.zoneID
            recType = CkRecordType.audioReflection.rawValue
            originalTranscription = CKAsset(fileURL: model.transcriptionSavedAt)
        }//: SWITCH
        
        recID = createCKRecordID(using: model, forZoneId: zoneToUse)
        
        let record = CKRecord(recordType: recType, recordID: recID)
        record[String.mediaKey] = mediaName as CKRecordValue
        record[String.assignedObjectKey] = assignedObjString as CKRecordValue
        record[String.mediaDataKey] = recAsset
        
        // For audio reflections, store the original transcription as a CKAsset
        if let savedTranscription = originalTranscription {
            record[String.originalAudioTranscriptionKey] = savedTranscription
        }//: IF LET (savedTranscription)
        
        return record
    }//: createCKRecord(for)
    
    private func saveRecToICloud(
        record: CKRecord,
        retryCount: Int = 0
    ) async -> Bool {
        guard settings.zonesCreated else {
            NSLog(">>> CloudMediaBrain error: saveRecToICloud(record) - Zones not yet created")
            await CloudMediaBrain.setupAndVerifyZones()
            return false
        }//: GUARD
        
        do {
            _ = try await cloudDB.save(record)
            return true
        } catch let error as CKError {
            if shouldRetry(error: error, currentRetry: retryCount) {
                let delay = calculateRetryBackoff(retryCount: retryCount, error: error)
                NSLog(">>> CloudMediaBrain: saveRecToICloud")
                NSLog(">>> Retrying save after \(delay) seconds (attempt \(retryCount + 1)/3")
                
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return await saveRecToICloud(record: record, retryCount: retryCount + 1)
            }//: IF (shouldRetry)
            
            NSLog(">>> CloudMediaBrain error: saveRecToICloud(record) error")
            NSLog(">>> Error: \(error.localizedDescription)")
            await MainActor.run {
                userErrorMessage = "Encountered a problem while trying to upload the file to iCloud. Check your network connection, iCloud settings, & iCloud storage, and try uploading again later. Contact the developer if this issue persists."
            }//: MAIN ACTOR
            return false
        } catch {
            NSLog(">>> CloudMediaBrain error: saveRecToICloud(record) error")
            NSLog(">>> Error: \(error.localizedDescription)")
            await MainActor.run {
                userErrorMessage = "Encountered a problem while trying to upload the file to iCloud. Check your network connection, iCloud settings, & iCloud storage, and try uploading again later. Contact the developer if this issue persists."
            }//: MAIN ACTOR
            return false
        }//: DO - CATCH
    }//: saveRecToICloud(record)
    
    private func manualCertUploadProcess(
        for certInfo: CertificateInfo,
        using model: MediaModel
    ) async -> Result<CKRecord.ID, Error> {
        let firstCheck = canUserUtilizeCloudSyncFor(mediaType: .certificate)
        switch firstCheck {
        case .success(_):
            let newRec = createCKRecord(for: .certificate, with: model)
            if await saveRecToICloud(record: newRec) {
                return Result.success(newRec.recordID)
            } else {
                Task{@MainActor in
                    certInfo.certErrorMessage = CloudSyncError.cloudSaveError(.certificate).localizedDescription
                }//: TASK
                return Result.failure(CloudSyncError.cloudSaveError(.certificate))
            }//: IF AWAIT
        case .failure(let error):
            Task{@MainActor in
                certInfo.certErrorMessage = error.localizedDescription
            }//: TASK
            return Result.failure(error)
        }//: SWITCH
    }//: manualCertUploadProcess(using)
    
    func createCKRecordID(
        using model: MediaModel,
        forZoneId zone: CKRecordZone.ID
    ) -> CKRecord.ID {
        var idToReturn: CKRecord.ID
        let recName: String = "\(model.createAssignedObjIdString())|\(model.relPathForCKRecordID)"
        if recName.count <= 255 {
            idToReturn = CKRecord.ID(recordName: recName,zoneID: zone )
        } else {
            idToReturn = CKRecord.ID(recordName: model.relPathForCKRecordID, zoneID: zone)
        }//: IF ELSE
        return idToReturn
    }//: createCKRecordID()
    
}//: EXTENSION
