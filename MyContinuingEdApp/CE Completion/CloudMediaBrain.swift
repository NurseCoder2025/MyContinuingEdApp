//
//  MediaBrain.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/10/26.
//

import CloudKit
import CoreData
import Foundation


final class CloudMediaBrain: ObservableObject {
    // MARK: - PROPERTIES
    
    let settings = AppSettingsCache.shared
    let dataController: DataController
    
    let cloudDB: CKDatabase = CKContainer.default().privateCloudDatabase
    let certZone = CKRecordZone(zoneName: String.certificateZoneId)
    let audioZone = CKRecordZone(zoneName: String.audioReflectionZoneId)
    
    @Published var zonesCreated: Bool = false
    @Published var userErrorMessage: String = ""
    
    // MARK: - COMPUTED PROPERTIES
    
    var iCloudIsAccessible: Bool {
        return settings.iCloudState.iCloudIsAvailable
    }//: okToRunOnlineMethods
    
    var userIsAProUser: Bool {
        let purchased = settings.getCurrentPurchaseLevel()
        return purchased == .proSubscription || purchased == .proLifetime
    }//: userIsAProUser
    
    var userIsAPaidSupporter: Bool {
        let subLevel = settings.getCurrentPurchaseLevel()
        return subLevel == .proSubscription || subLevel == .basicUnlock || subLevel == .proLifetime
    }//: userIsASubscriber
    
    // MARK: - RECORD ZONE HANDLING
    
    private func doAllZonesExistInDB() async -> Result<(Bool, [CKRecordZone]), Error> {
        var allZones: [CKRecordZone] = []
        do {
            allZones = try await cloudDB.allRecordZones()
            if allZones.contains(certZone) && allZones.contains(audioZone) {
                return Result.success((true, allZones))
            } else {
                NSLog(">>> The allRecordZones method did not throw an error but the returned array did not contain all of the zones that it should have.")
                NSLog(">>> Instead of finding both the cert and audio zones, only found: \(allZones.map(\.zoneID.zoneName))")
                return Result.success((false, allZones))
            }//: IF (contains)
        } catch {
            NSLog(">>> CloudMediaBrain error: doZonesExistInDB")
            NSLog(">>> the allRecordZones() method threw an error while trying to fetch all zones within the user's private iCloud database.")
            NSLog(">>> Error: \(error.localizedDescription)")
            return Result.failure(error)
        }//: DO-CATCH
    }//: doAllZonesExistInDB()
    
    private func createZone(_ zoneToSave: CKRecordZone) async -> Bool {
        do {
            _ = try await cloudDB.save(zoneToSave)
            return true
        } catch {
            NSLog(">>> CloudMediaBrain error: createZone")
            NSLog(">>> Unable to save the record zone to the database becuase: \(error.localizedDescription)")
            NSLog(">>> The zone that was supposed to be saved was: \(zoneToSave)")
            return false
        }//: DO-CATCH
    }//: createZone()
    
    private func initialZoneSetup() async {
        let zonesToCreate: [CKRecordZone] = [certZone, audioZone]
        let zoneCheckResult = await doAllZonesExistInDB()
        switch zoneCheckResult {
        case .success(let (zonesExist, savedZones)):
            if zonesExist {
                NSLog(">>> CloudMediaBrain: initialZoneSetup() - No need to create any new zones because the zones already exist.")
                zonesCreated = true
                return
            } else {
                let missingZones = zonesToCreate.filter {savedZones.contains($0) == false}
                let zonesToAdd: Int = missingZones.count
                var zonesAddedOk: Int = 0
                for zone in missingZones {
                    let creationSuccess = await createZone(zone)
                    if creationSuccess {
                        NSLog(">>> CloudMediaBrain: initialZoneSetup() - Successfully created a new zone: \(zone)")
                        zonesAddedOk += 1
                    } else {
                        NSLog(">>> CloudMediaBrain: initialZoneSetup() - Failed to create a new zone: \(zone)")
                        await MainActor.run {
                            userErrorMessage = "Encountered an error while trying to configure iCloud for media file storage for this app. Please check your internet connection and iCloud account settings. Notify the developer if this error continues to occur."
                        }//: MAIN ACTOR
                    }//: IF ELSE (creationSuccess)
                }//: LOOP
                if zonesAddedOk == zonesToAdd {
                    zonesCreated = true
                }
            }//: IF ELSE (zonesExist)
        case .failure(let error):
            NSLog(">>> CloudMediaBrain: initialZoneSetup() - Encountered an error while checking the zones in the database: \(error.localizedDescription)")
            await MainActor.run {
                userErrorMessage = "Encountered an error while trying to configure iCloud for media file storage for this app. Please check your internet connection and iCloud account settings. Notify the developer if this error continues to occur."
            }//: MAIN ACTOR
        }//: SWITCH
    }//: initialZoneSetup()
    
    private func needsZoneVerification(interval: TimeInterval = 60 * 60 * 24) -> Bool {
        guard let lastCheck = settings.zoneVerificationDate else { return true }
        return Date().timeIntervalSince(lastCheck) > interval
    }//: needsZoneVerification
    
    private func setupAndVerifyZones() async {
        await initialZoneSetup()
        if zonesCreated {
            settings.zonesCreated = true
            settings.zoneVerificationDate = Date()
            settings.encodeCurrentState()
        }//: IF (zonesCreated)
    }//: verifyAndCreateZones()
    
    // MARK: - SAVING
    
    private func createCKRecord(for objType: MediaClass, with model: MediaModel) -> CKRecord {
        let recType = model.getRecTypeName()
        let mediaName = model.getMediaTypeName()
        let assignedObjString = model.createAssignedObjIdString()
        
        let recAsset = CKAsset(fileURL: model.mediaDataSavedAt)
        var originalTranscription: CKAsset? = nil
        var zoneToUse: CKRecordZone.ID
        
        switch objType {
        case .certificate:
            zoneToUse = certZone.zoneID
        case .audioReflection:
            zoneToUse = audioZone.zoneID
            originalTranscription = CKAsset(fileURL: model.transcriptionSavedAt)
        }//: SWITCH
        
        let recID = CKRecord.ID(zoneID: zoneToUse)
        
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
    
    private func saveRecToICloud(record: CKRecord) async -> Bool {
        guard settings.zonesCreated else {
            NSLog(">>> CloudMediaBrain error: saveRecToICloud(record) - Zones not yet created")
            await setupAndVerifyZones()
            return false
        }//: GUARD
        
        do {
            _ = try await cloudDB.save(record)
            return true
        } catch {
            NSLog(">>> CloudMediaBrain error: saveRecToICloud(record) error")
            NSLog(">>> Error: \(error.localizedDescription)")
            await MainActor.run {
                userErrorMessage = "Encountered a problem while trying to upload the file to iCloud. Check your network connection, iCloud settings, & iCloud storage, and try uploading again later. Contact the developer if this issue persists."
            }//: MAIN ACTOR
            return false
        }//: DO-CATCH
    }//: saveRecToICloud(record)
    
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
               case .success(let success):
                   let certRec = createCKRecord(for: .certificate, with: model)
                   if await saveRecToICloud(record: certRec) {
                       return Result.success(certRec.recordID)
                   } else {
                       userErrorMessage = CloudSyncError.cloudSaveError(.certificate).localizedDescription
                       return Result.failure(CloudSyncError.cloudSaveError(.certificate))
                   }//: IF AWAIT
               case .failure(let error):
                   userErrorMessage = error.localizedDescription
                   return Result.failure(error)
               }//: SWITCH (smartSyncEligibility)
               
       case .failure(let error):
           userErrorMessage = error.localizedDescription
           return Result.failure(error)
       }//: SWITCH (firstCheck)
    }//: smartSyncCECertificate
    
    func manualCertUpload(
        for certInfo: CertificateInfo,
        with model: MediaModel
    ) async -> Result<CKRecord.ID, Error> {
        guard userIsAPaidSupporter else { return Result.failure(CloudSyncError.paidUpgradeNeeded)}
        
        if settings.getCurrentPurchaseLevel() == .basicUnlock {
            let certSyncEligibility = certInfo.isCertEligibleForSmartSync(syncWindow: 0)
            switch certSyncEligibility {
            case .success(_):
            case .failure(let error):
                return Result.failure(error)
            }//: SWITCH
        }//: IF (basicUnlock)
        
        let firstCheck = canUserUtilizeCloudSyncFor(mediaType: .certificate)
        switch firstCheck {
        case .success(_):
            let newRec = createCKRecord(for: .certificate, with: model)
            if await saveRecToICloud(record: newRec) {
                return Result.success(newRec.recordID)
            } else {
                userErrorMessage = CloudSyncError.cloudSaveError(.certificate).localizedDescription
                return Result.failure(CloudSyncError.cloudSaveError(.certificate))
            }//: IF AWAIT
        case .failure(let error):
            userErrorMessage = error.localizedDescription
            return Result.failure(error)
        }//: SWITCH
    }//: manualCertUpload(with)
    
    func syncAudioReflection(using model: MediaModel) async -> Result<CKRecord.ID, Error> {
        guard userIsAProUser else { return Result.failure(CloudSyncError.proLevelPurchaseNeeded) }
        
        let preliminaryCheck = canUserUtilizeCloudSyncFor(mediaType: .audioReflection)
        switch preliminaryCheck {
        case .success(_):
            let newRec = createCKRecord(for: .audioReflection, with: model)
            if await saveRecToICloud(record: newRec) {
                return Result.success(newRec.recordID)
            } else {
                userErrorMessage = CloudSyncError.cloudSaveError(.audioReflection).localizedDescription
                return Result.failure(CloudSyncError.cloudSaveError(.audioReflection))
            }//: IF AWAIT
        case .failure(let error):
            userErrorMessage = error.localizedDescription
            return Result.failure(error)
        }//: SWITCH
    }//: syncAudioReflection()
    
    // MARK: - CHANGING
    
    // MARK: - DELETING
    
    func deleteUploadedMedia(
        for record: CKRecord.ID,
        with model: MediaModel
    ) async -> Result<Bool, CloudSyncError> {
        let mediaType = model.ckRecType
        var recToUpdate: CKRecord
        do {
           recToUpdate = try await cloudDB.record(for: record)
           removeAssetValuesFromRecord(recToUpdate, for: mediaType)
           return Result.success(true)
        } catch {
            if let searchedRec = await searchZoneForRecordMatching(using: model) {
                removeAssetValuesFromRecord(searchedRec, for: mediaType)
                return Result.success(true)
            } else {
                return Result.failure(
                    CloudSyncError.mediaDeletionError("After two search attempts, the iCloud record for the \(mediaType.rawValue) you are trying to delete could not be found due to: \(error.localizedDescription).")
                )//: failure
            }//: IF LET
        }//: DO-CATCH
    }//: deleteUploadedMedia(with)
    
    func deleteEntireRecord(
        for object: CKRecord.ID,
        using model: MediaModel
    ) async -> Result<Bool, CloudSyncError> {
        var recToDelete: CKRecord
        
        // Make sure the record can be found
        do {
            recToDelete = try await cloudDB.record(for: object)
        } catch {
            if let searchedRec = await searchZoneForRecordMatching(using: model) {
                recToDelete = searchedRec
            } else {
                return Result.failure(
                    CloudSyncError.mediaDeletionError("Unable to locate the iCloud record for the \(model.ckRecType.rawValue) you are trying to delete.")
                    )//: failure
            }//: IF LET (searchedRec)
        }//: DO-CATCH
        
        // Delete the entire record
        let recID = recToDelete.recordID
        do {
            _ = try await cloudDB.deleteRecord(withID: recID)
            return Result.success(true)
        } catch {
            return Result.failure(
                CloudSyncError.mediaDeletionError("Error deleting the iCloud file: \(error.localizedDescription)")
            )//: failure
        }//: DO-CATCH
    }//: deleteEntireRecord(for)
    
    
    private func removeAssetValuesFromRecord(_ record: CKRecord, for objType: CkRecordType) {
        switch objType {
        case .certificate:
            record[String.mediaDataKey] = nil
            record[String.mediaKey] = "" as CKRecordValue
        case .audioReflection:
            record[String.mediaDataKey] = nil
            record[String.originalAudioTranscriptionKey] = "" as CKRecordValue
        }//: SWITCH
    }//: removeAssetValuesFromRecord
    
    // MARK: - DOWNLOADING
    
    func downloadOnlineMediaFile(
        for object: CKRecord.ID,
        using model: MediaModel
    ) async -> Result<URL, Error> {
        var mediaRecord: CKRecord
        do {
            mediaRecord = try await cloudDB.record(for: object)
        } catch {
            if let searchedRec = await searchZoneForRecordMatching(using: model) {
                mediaRecord = searchedRec
            } else {
                return Result.failure(CloudSyncError.cloudRecordNotFound(model.designatedClass))
            }//: IF LET (searchedRec)
        }//: DO-CATCH
        
        if let mediaAsset = mediaRecord[String.mediaDataKey] as? CKAsset, let tempURL = mediaAsset.fileURL {
            do {
                _ = try FileManager().moveItem(at: tempURL, to: model.mediaDataSavedAt)
                return Result.success(model.mediaDataSavedAt)
            } catch {
                NSLog(">>> CloudMediaBrain error: downloadOnlineMediaFile")
                NSLog(">>> The FileManger moveItem method threw an error while trying to move the CKAsset binary from \(tempURL.absoluteString) to \(model.mediaDataSavedAt.absoluteString).")
                return Result.failure(CloudSyncError.mediaDownloadFailed)
            }//: DO-CATCH
        } else {
            NSLog(">>> CloudMediaBrain error: downloadOnlineMediaFile")
            NSLog(">>> Either there was no binary data assigned to the mediaDataKey or the fileURL getter for the CKAsset returned a nil value.")
            return Result.failure(CloudSyncError.mediaDownloadFailed)
        }//: IF LET (mediaAsset as? CKAsset)
    }//: downloadOnlineMediaFile(using)
    
    func restoreOriginalAudioTranscription(using model: MediaModel) async -> (Bool, String?) {
        guard model.designatedClass == .audioReflection else { return (false, nil) }
        
        let matchingString = model.createAssignedObjIdString()
        let predicate: NSPredicate = NSPredicate(format: "\(String.assignedObjectKey) == %@", matchingString)
        let query: CKQuery = CKQuery(recordType: model.getRecTypeName(), predicate: predicate)
        
        let searchZone: CKRecordZone.ID = ((model.ckRecType == .certificate) ? certZone : audioZone).zoneID
        
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 1
        operation.desiredKeys = [String.originalAudioTranscriptionKey]
        operation.zoneID = searchZone
        
        var recordIsFound: (result: Bool, transcript: String?)
        
        operation.recordMatchedBlock = { recID, result in
            switch result {
            case .success(let record):
                if let retrievedTranscript = record[String.originalAudioTranscriptionKey] as? String {
                    recordIsFound = (true, retrievedTranscript)
                } else {
                    recordIsFound = (false, nil)
                }//: IF LET
            case .failure:
                recordIsFound = (result: false, transcript: nil)
            }//: SWITCH
        }//: recordMatchedBlock
        
        
        operation.queryResultBlock = { result in
            Task{@MainActor in
                switch result {
                case .success(_):
                    return recordIsFound
                case .failure(let error):
                    self.userErrorMessage = "Error encountered while trying to find the iCloud record containing the original audio transcription: \(error.localizedDescription)"
                    return recordIsFound
                }//: SWITCH
            }//:TASK
        }//: queryResultBlock
        
        cloudDB.add(operation)
    }//: restoreOriginalAudioTranscription(for, using)
    
    // MARK: - HELPERS
    
    private func canUserUtilizeCloudSyncFor(mediaType: MediaClass) -> Result<Bool, Error> {
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
    
    // MARK: - QUERY
    
    private func searchZoneForRecordMatching(using model: MediaModel) async -> CKRecord? {
        let matchingString = model.createAssignedObjIdString()
        let predicate: NSPredicate = NSPredicate(format: "\(String.assignedObjectKey) == %@", matchingString)
        let query: CKQuery = CKQuery(recordType: model.getRecTypeName(), predicate: predicate)
        
        let searchZone: CKRecordZone.ID = ((model.ckRecType == .certificate) ? certZone : audioZone).zoneID
        
        do {
            let searchResult = (try await cloudDB.records(matching: query, inZoneWith: searchZone, desiredKeys: nil, resultsLimit: 1)).matchResults
            
            if let foundRecord = searchResult.first {
                let searchRecordResult = foundRecord.1
                switch searchRecordResult {
                case .success(let record):
                    return record
                case .failure(let error):
                    NSLog(">>> CloudMediaBrain error: searchZoneForRecordMathing(using)")
                    NSLog(">>> The Cloud Kit query was able to find the matching CKRecord but could not read it  becuase: \(error.localizedDescription)")
                    return nil
                }//: SWITCH
            } else {
                NSLog(">>> CloudMediaBrain error: searchZoneForRecordMathing(using)")
                NSLog(">>> The Cloud Kit query was unable to retrieve any matching records after the search.")
                return nil
            }//: IF ELSE
        } catch {
            NSLog(">>> CloudMediaBrain error: searchZoneForRecordMathing(using)")
            NSLog(">>> The Cloud Kit query was unable to find the matching CKRecord due to: \(error.localizedDescription)")
            return nil
        }//: DO - CATCH
    }//: searchZoneForRecordMatching(objID)
    
    
    // MARK: - INIT
    
    init(dataController: DataController) {
        self.dataController = dataController
        
        if userIsAPaidSupporter && iCloudIsAccessible {
            Task{
                if !settings.zonesCreated || needsZoneVerification() {
                    await setupAndVerifyZones()
                }//: IF (zonesCreated OR needsZoneVerification)
            }//: TASK
        } else {
            if iCloudIsAccessible == false {
                userErrorMessage = settings.iCloudState.userMessage
            }//:IF
        }//: IF ELSE
    }//: INIT
    
    
}//: CloudMediaBrain
