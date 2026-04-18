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
    
    private let settings = AppSettingsCache.shared
    private let fileSystem = FileManager.default
    
    private let cloudDB: CKDatabase = CKContainer.default().privateCloudDatabase
    private let certZone = CKRecordZone(zoneName: String.certificateZoneId)
    private let audioZone = CKRecordZone(zoneName: String.audioReflectionZoneId)
    
    private(set) var zonesCreated: Bool = false
    @Published var userErrorMessage: String = ""
    
    // MARK: - OBJECT SINGELTON
    static let shared = CloudMediaBrain()
    
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
    
    private func doAllZonesExistInDB(retryCount: Int = 0) async -> Result<(Bool, [CKRecordZone]), Error> {
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
        } catch let webError as CKError {
            if shouldRetry(error: webError, currentRetry: retryCount) {
                let delay = calculateRetryBackoff(retryCount: retryCount, error: webError)
                NSLog(">>> CloudMediaBrain: doAllZonesExistInDB retrying...")
                NSLog(">>> Retrying in \(delay) seconds...(attempt \(retryCount + 1)/3)")
                try? await Task.sleep(for: .seconds(0.01))
                return await doAllZonesExistInDB(retryCount: retryCount + 1)
            } else {
                NSLog(">>> CloudMediaBrain error: doZonesExistInDB")
                NSLog(">>> the allRecordZones() method threw an error while trying to fetch all zones within the user's private iCloud database, even after 3 additional attempts.")
                NSLog(">>> Error: \(webError.localizedDescription)")
                return Result.failure(webError)
            }//: IF ELSE
        } catch {
            NSLog(">>> CloudMediaBrain error: doZonesExistInDB")
            NSLog(">>> the allRecordZones() method threw an error while trying to fetch all zones within the user's private iCloud database.")
            NSLog(">>> Error: \(error.localizedDescription)")
            return Result.failure(error)
        }//: DO - CATCH
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
                let missingZones = zonesToCreate.filter {savedZones.doesNOTContain($0)}
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
                } else {
                    NSLog(">>> CloudMediaBrain: initialZoneSetup() - Failed to create all of the new zones. Zones that were not created: \(missingZones)")
                    await MainActor.run {
                        userErrorMessage = "Failed to properly configure your iCloud drive for this app to save and sync media files due to a technical, iCloud side error. Open this app later to see if issue gets resolved."
                    }//: MAIN ACTOR
                }//: IF ELSE (zonesAddedOk == zonesToAdd)
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
    
    // MARK: - RECORD SEARCHING
    
    func findMatchingRecordWith(
        recId: CKRecord.ID,
        recType: MediaClass,
        using model: MediaModel? = nil,
        withKeys: [String] = [],
        retryCount: Int = 0
    ) async -> CKRecord? {
        guard iCloudIsAccessible else { return nil }
        var matchingRecord: CKRecord? = nil
        do {
            // Option for pulling part of the record but not the whole thing
            if withKeys.isNotEmpty {
                let searchResult = try await cloudDB.records(for: [recId], desiredKeys: withKeys)
                if let resultForId = searchResult[recId] {
                    switch resultForId {
                    case .success(let record):
                        matchingRecord = record
                    case .failure(let error):
                        logRecordCantBeFound(for: recId, with: error)
                    }//: SWITCH
                } else {
                    logRecordCantBeFound(for: recId, with: CloudSyncError.cloudRecordNotFound(recType))
                }//: IF LET ELSE (resultForId)
            } else {
                // Retrieving the entire record, which will download any associated CKAssets
                matchingRecord = try await cloudDB.record(for: recId)
            }//: IF ELSE (withKeys.isNotEmpty)
        } catch let webError as CKError {
          if shouldRetry(error: webError, currentRetry: retryCount) {
                let delay = calculateRetryBackoff(retryCount: retryCount, error: webError)
                _ = try? await Task.sleep(for: .seconds(0.01))
              if let modelToUse = model {
                  return await findMatchingRecordWith(
                    recId: recId,
                    recType: recType,
                    using: modelToUse,
                    withKeys: withKeys,
                    retryCount: retryCount + 1
                  )//: findMatchingRecordWith
              } else {
                  return await findMatchingRecordWith(
                    recId: recId,
                    recType: recType,
                    withKeys: withKeys,
                    retryCount: retryCount + 1
                  )//: findMatchingRecordWith
              }//: IF LET ELSE (modelToUse)
          } else {
              if let objModel = model {
                  matchingRecord = await searchZoneForRecordMatching(using: objModel)
              } else {
                  logRecordCantBeFound(for: recId, with: CloudSyncError.cloudRecordNotFound(recType))
              }//: IF LET (objModel)
          }//: IF ELSE (shouldRetry)
        } catch {
            if let objModel = model {
                matchingRecord = await searchZoneForRecordMatching(using: objModel)
            } else {
                logRecordCantBeFound(for: recId, with: CloudSyncError.cloudRecordNotFound(recType))
            }//: IF LET (objModel)
        }//: DO - CATCH
        
        return matchingRecord
    }//: findMatchingRecordWith(recId:)
    
    private func logRecordCantBeFound(
        for record: CKRecord.ID,
        with error: Error,
        methodName: String = "findMatchingRecordWith"
    ) {
        NSLog("Unable to find the matching record for \(record.recordName)")
        NSLog(">>> CloudMediaBrain error: \(methodName): \(error.localizedDescription)")
    }//: logRecordCantBeFound(with error)
    
    private func searchZoneForRecordMatching(
        using model: MediaModel,
        retryCount: Int = 0
    ) async -> CKRecord? {
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
        } catch let webError as CKError {
            if shouldRetry(error: webError, currentRetry: retryCount) {
                let delay = calculateRetryBackoff(retryCount: retryCount, error: webError)
                NSLog(">>> CloudMediaBrain: searchZoneForRecordMatching")
                NSLog(">>> Retrying record search after \(delay) seconds (\(retryCount + 1)/3")
                try? await Task.sleep(for: .seconds(0.01))
                return await searchZoneForRecordMatching(using: model, retryCount: retryCount + 1)
            } else {
                NSLog(">>> CloudMediaBrain error: searchZoneForRecordMathing(using)")
                NSLog(">>> The Cloud Kit query was unable to find the matching CKRecord due to: \(webError.localizedDescription)")
                return nil
            }//: IF (shouldRetry)
        } catch {
            NSLog(">>> CloudMediaBrain error: searchZoneForRecordMathing(using)")
            NSLog(">>> The Cloud Kit query was unable to find the matching CKRecord due to: \(error.localizedDescription)")
            return nil
        }//: DO - CATCH
    }//: searchZoneForRecordMatching(objID)
    
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
        record[String.recordTimeStampKey] = Date() as CKRecordValue
        
        // For audio reflections, store the original transcription as a CKAsset
        if let savedTranscription = originalTranscription {
            record[String.originalAudioTranscriptionKey] = savedTranscription
        }//: IF LET (savedTranscription)
        
        return record
    }//: createCKRecord(for)
    
    private func saveRecToICloud(record: CKRecord, retryCount: Int = 0) async -> Bool {
        guard settings.zonesCreated else {
            NSLog(">>> CloudMediaBrain error: saveRecToICloud(record) - Zones not yet created")
            await setupAndVerifyZones()
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
    
    func updateMediaFileWithNewData(
        for record: CKRecord.ID,
        using model: MediaModel
    ) async -> Bool {
        guard iCloudIsAccessible else {
            await MainActor.run {
                userErrorMessage = settings.iCloudState.userMessage
            }//: MAIN ACTOR
            return false
        }//: GUARD
        let mediaDesignation = model.designatedClass
        
        if let matchedRecord = await findMatchingRecordWith(recId: record, recType: mediaDesignation) {
           let updateResult = await updateRecordWithNewDataAndSave(matchedRecord, using: model)
            if updateResult {
                return true
            } else {
                NSLog(">>> CloudMediaBrain error: updateMediaFileWithNewData")
                NSLog(">>> The CKRecord that needed to be updated was found but changes could not be saved to iCloud. An error message will be displayed to the user.")
                return false
            }//: IF (updateResult)
        } else {
            NSLog(">>> CloudMediaBrain error: updateMediaFileWithNewData")
            NSLog(">>> The CKRecord that needed to be updated could not be found with the given id.")
            return false
        }//: IF LET ELSE (matchedRecord)
    }//: updateMediaFileWithNewData(using)
    
    
    private func updateRecordWithNewDataAndSave(
        _ record: CKRecord,
        using model: MediaModel
    ) async -> Bool {
        let newMediaType = model.getMediaTypeName()
        let newAsset = CKAsset(fileURL: model.mediaDataSavedAt)
        record[String.mediaDataKey] = newAsset
        record[String.mediaKey] = newMediaType
        if model.designatedClass == .audioReflection {
            let transcriptAsset: CKAsset = CKAsset(fileURL: model.transcriptionSavedAt)
            record[String.originalAudioTranscriptionKey] = transcriptAsset
        }//: IF
        
        let saveUpdatedRecResult = await saveRecToICloud(record: record)
        if saveUpdatedRecResult {
            return true
        } else {
            await MainActor.run {
                userErrorMessage = "Unable to save the \(model.designatedClass.rawValue) file after deleting the original file from iCloud. Please check your network connection and try again."
            }//: MAIN ACTOR
            return false
        }//: IF ELSE
    }//: updateRecordWithNewDataAndSave(_ record)
    
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
    
    // MARK: - DOWNLOADING
    
    func downloadOnlineMediaFile(
        for object: CKRecord.ID,
        using model: MediaModel
    ) async -> Result<URL, Error> {
        guard iCloudIsAccessible else {
            await MainActor.run {
                userErrorMessage = settings.iCloudState.userMessage
            }//: MAIN ACTOR
            return Result.failure(CloudSyncError.cloudUnavailable)
        }//: GUARD
        
        var mediaRecord: CKRecord
        
        do {
            mediaRecord = try await cloudDB.record(for: object)
        } catch let webError as CKError {
                if let foundRec = await repeatRecordSearchAfterError(
                    error: webError,
                    for: object
                ) {
                    mediaRecord = foundRec
                } else {
                    if let searchedRec = await searchZoneForRecordMatching(using: model) {
                        mediaRecord = searchedRec
                    } else {
                        return Result.failure(CloudSyncError.cloudRecordNotFound(model.designatedClass))
                    }//: IF LET (searchedRec)
                }//: IF LET ELSE
        } catch {
            if let searchedRec = await searchZoneForRecordMatching(using: model) {
                mediaRecord = searchedRec
            } else {
                return Result.failure(CloudSyncError.cloudRecordNotFound(model.designatedClass))
            }//: IF LET (searchedRec)
        }//: DO - CATCH
        
        if let mediaAsset = mediaRecord[String.mediaDataKey] as? CKAsset,
            let tempURL = mediaAsset.fileURL {
            do {
                if fileSystem.fileExists(atPath: model.mediaDataSavedAt.path) {
                    try fileSystem.removeItem(at: model.mediaDataSavedAt)
                }//: IF (fileExists)
                
                try fileSystem.moveItem(at: tempURL, to: model.mediaDataSavedAt)
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
        guard iCloudIsAccessible else {
            await MainActor.run {
                userErrorMessage = settings.iCloudState.userMessage
            }//: MAIN ACTOR
            return (false, nil)
        }//: GUARD
        guard model.designatedClass == .audioReflection else { return (false, nil) }
        
        let matchingString = model.createAssignedObjIdString()
        let predicate: NSPredicate = NSPredicate(format: "\(String.assignedObjectKey) == %@", matchingString)
        let query: CKQuery = CKQuery(recordType: model.getRecTypeName(), predicate: predicate)
        
        let searchZone: CKRecordZone.ID = ((model.ckRecType == .certificate) ? certZone : audioZone).zoneID
        
        do {
            let searchResults = try await cloudDB.records(
                matching: query,
                inZoneWith: searchZone,
                desiredKeys: [String.originalAudioTranscriptionKey],
                resultsLimit: 1
            )//: searchResults
            
            if let matchedRec = searchResults.matchResults.first {
                switch matchedRec.1 {
                case .success(let recFound):
                    if let transcriptAsset = recFound[String.originalAudioTranscriptionKey] as? CKAsset, let tempURL = transcriptAsset.fileURL,
                        let transcript = try? String(contentsOf: tempURL, encoding: .utf8) {
                        return (true, transcript)
                    } else {
                        return (false, nil)
                    }//: IF ELSE
                case .failure(let error):
                    await MainActor.run {
                        userErrorMessage = "Failed to retrieve the original transcription from iCloud: \(error.localizedDescription)"
                    }//: MAIN ACTOR
                    return (false, nil)
                }//: SWITCH
            } else {
                return (false, nil)
            }//: IF LET (searchResults.matchResults.first)
        } catch {
            await MainActor.run {
                userErrorMessage = "Error searching for the original transcription: \(error.localizedDescription)"
            }//: MAIN ACTOR
            return (false, nil)
        }//: DO-CATCH
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
    
    
    // MARK: - QUERY SUBSCRIPTIONS
    
    // MARK: CREATING QUERY SUBS
    private func createMediaCreationQuerySubscription(
    for mediaClass: MediaClass,
    retryCount: Int = 0
    ) async -> (Bool, CKQuerySubscription?) {
        let subscription = createQuerySubscriptionConfig(for: mediaClass, purpose: .addingFile)
        
        do {
            _ = try await cloudDB.save(subscription)
            NSLog(">>> CloudMediaBrain: successfully saved new subscription: \(subscription.subscriptionID)")
            return (true, subscription)
        } catch let webError as CKError {
            return await retrySavingQuerySubscription(
                error: webError,
                for: mediaClass,
                toRetry: createMediaCreationQuerySubscription,
                subInfo: subscription
            )//: retrySavingQuerySubscription
        } catch {
            return handleNonWebErrorQuerySubSetup(
                methodName: "createMediaCreationQuerySubscription",
                for: subscription.subscriptionID,
                using: error
            )//: handleNonWebErrorQuerySubSetup()
        }//: DO - CATCH
    }//: createMediaCreationQuerySubscription(for, retryCount)
    
    private func createMediaFileChangeQuerySubscription(
        for mediaClass: MediaClass,
        retryCount: Int = 0
    ) async -> (Bool, CKQuerySubscription?) {
        let subscription = createQuerySubscriptionConfig(for: mediaClass, purpose: .changingFile)
        
        do {
            _ = try await cloudDB.save(subscription)
            NSLog(">>> CloudMediaBrain: successfully saved new subscription: \(subscription.subscriptionID)")
            return (true, subscription)
         } catch let webError as CKError {
            return await retrySavingQuerySubscription(
                error: webError,
                for: mediaClass,
                toRetry: createMediaFileChangeQuerySubscription,
                retryCount: retryCount,
                subInfo: subscription
            )//: retrySavingQuerySubscription
        } catch {
            return handleNonWebErrorQuerySubSetup(
                methodName: "createMediaFileChangeQuerySubscription",
                for: subscription.subscriptionID,
                using: error
            )//: handleNonWebErrorQuerySubSetup()
        }//: DO - CATCH
    }//: createMediaFileChangeQuerySubscription()
    
    private func createMediaFileDeletionQuerySubscription(
        for mediaClass: MediaClass,
        retryCount: Int = 0
    ) async -> (Bool, CKQuerySubscription?) {
        let subscription = createQuerySubscriptionConfig(for: mediaClass, purpose: .deletingFile)
        
        do {
            _ = try await cloudDB.save(subscription)
            NSLog(">>> CloudMediaBrain: successfully saved new subscription: \(subscription.subscriptionID)")
            return (true, subscription)
        } catch let webError as CKError {
            return await retrySavingQuerySubscription(
                error: webError,
                for: mediaClass,
                toRetry: createMediaFileDeletionQuerySubscription,
                subInfo: subscription
            )//: retrySavingQuerySubscription()
        } catch {
            return handleNonWebErrorQuerySubSetup(
                methodName: "createMediaFileDeletionQuerySubscription",
                for: subscription.subscriptionID,
                using: error
            )//: handleNonWebErrorQuerySubSetup()
        }//: DO - CATCH
    }//: createMediaFileDeletionQuerySubscription()
    
    private func setupMediaFileSubscriptions() async -> Result<(allCreated:Bool, subsCreated:[CKQuerySubscription]), Error> {
        // Certificate-related query subscriptions:
        let certAddedSubCreated = await createMediaCreationQuerySubscription(for: .certificate)
        let certChangedSubCreated = await createMediaFileChangeQuerySubscription(
            for: MediaClass.certificate
        )//: certChangedSubCreated
        let certDeletedSubCreated = await createMediaFileDeletionQuerySubscription(for: .certificate)
        
        // Audio reflection-related query subscriptions:
        let audioAddedSubCreated = await createMediaCreationQuerySubscription(for: .audioReflection)
        let audioChangedSubCreated = await createMediaFileChangeQuerySubscription(
            for: MediaClass.audioReflection
        )//: audioChangedSubCreated
        let audioDeletedSubCreated = await createMediaFileDeletionQuerySubscription(for: .audioReflection)
        
        var setupResults: [(Bool, CKQuerySubscription?)] = [
            certAddedSubCreated, certChangedSubCreated, certDeletedSubCreated,
            audioAddedSubCreated, audioChangedSubCreated, audioDeletedSubCreated
        ]
        var createdSubscriptions: [CKQuerySubscription] = []
        
        createdSubscriptions = setupResults.compactMap({$0.1})
        
        if createdSubscriptions.isNotEmpty {
            if createdSubscriptions.count == 6 {
                return Result.success((true, createdSubscriptions))
            } else {
                return Result.success((false, createdSubscriptions))
            }//: IF (.count == 6)
        } else {
            return Result.failure(CloudSyncError.querySubscriptionNotCreated)
        }//: IF (isNotEmpty)
    }//: setupMediaFileSubscriptions()
    
    private func retrySettingUpMissingSubscriptions(
        excluding existingSubs: [CKQuerySubscription],
        retryCount: Int = 0
    ) async -> Bool {
        guard existingSubs.isNotEmpty && existingSubs.count < 6 else { return false }
        
        let certAddSub = createQuerySubscriptionConfig(for: .certificate, purpose: .addingFile)
        let audioAddSub = createQuerySubscriptionConfig(for: .audioReflection, purpose: .addingFile)
        let certChangeSub = createQuerySubscriptionConfig(for: .certificate, purpose: .changingFile)
        let audioChangeSub = createQuerySubscriptionConfig(for: .audioReflection, purpose: .changingFile)
        let certDeleteSub = createQuerySubscriptionConfig(for: .certificate, purpose: .deletingFile)
        let audioDeleteSub = createQuerySubscriptionConfig(for: .audioReflection, purpose: .deletingFile)
        
        let allNeededSubs = [
            certAddSub, certChangeSub, certDeleteSub,
            audioAddSub, audioChangeSub, audioDeleteSub
        ]
        
        let subsToAdd = (allNeededSubs.count - existingSubs.count)
        var subsAdded: Int = 0
        
        let missingSubs = allNeededSubs.filter {!existingSubs.contains($0)}
        
        for subscription in missingSubs {
            do {
                _ = try await cloudDB.save(subscription)
                NSLog(">>> CloudMediaBrain: successfully saved new subscription: \(subscription.subscriptionID)")
                subsAdded += 1
            } catch let webError as CKError {
                if shouldRetry(error: webError, currentRetry: retryCount) {
                    let delay = calculateRetryBackoff(retryCount: retryCount, error: webError)
                    NSLog(">>> CloudMediaBrain: retrying setupMediaFileSubscriptions() in \(delay) seconds...(attempt #\(retryCount + 1)/3")
                    return await retrySettingUpMissingSubscriptions(excluding: existingSubs, retryCount: retryCount + 1)
                } else {
                    NSLog(">>> CloudMediaBrain error: retrySettingUpMissingSubscriptions")
                    NSLog(">>> Failed to save the newly created subscription, \(subscription.subscriptionID) to iCloud after making 3 attempts.")
                    NSLog(">>> Error: \(webError.localizedDescription)")
                }//: IF (shouldRetry)
            } catch {
                NSLog(">>> CloudMediaBrain error: retrySettingUpMissingSubscriptions")
                NSLog(">>> Failed to save the newly created subscription, \(subscription.subscriptionID) to iCloud, and unable to make any additional attempts.")
                NSLog(">>> Error: \(error.localizedDescription)")
            }//: DO - CATCH
        }//: LOOP
        return subsAdded == subsToAdd
    }//: retrySettingUpMissingSubscriptions
    
    
    private func handleMediaFileSubscriptionSetup() async {
        guard !settings.appHasQuerySubscriptions else { return }
        guard iCloudIsAccessible && userIsAPaidSupporter else { return }
        
        let setupResults = await setupMediaFileSubscriptions()
        switch setupResults {
        case .success(let outcome):
            if outcome.allCreated {
                settings.appHasQuerySubscriptions = true
                settings.encodeCurrentState()
            } else {
                let retryResult = await retrySettingUpMissingSubscriptions(excluding: outcome.subsCreated)
                if retryResult {
                    settings.appHasQuerySubscriptions = true
                    settings.encodeCurrentState()
                } else {
                    NSLog(">>> CloudMediaBrain error: handleMediaFileSubscriptionSetup")
                    NSLog(">>> Error: Failed to set up all necessary subscriptions.")
                    NSLog(">>> Subscriptions not saved: \(outcome.subsCreated.count)")
                    await MainActor.run {
                        userErrorMessage = "Encountered an error setting up iCloud sync for this device. While  you can still add and delete media files like certificates and audio reflections, be aware that such changes may not sync across to your other devices until the app can get iCloud sync setup correctly. Future attempts at fixing this will be made."
                    }//: MAIN ACTOR
                }//: IF (retryResult)
            }//: IF
        case .failure(let error):
            NSLog(">>> CloudMediaBrain error: handleMediaFileSubscriptionSetup")
            NSLog(">>> Error: Failed to set up all necessary subscriptions.")
            NSLog("Error: \(error.localizedDescription)")
            await MainActor.run {
                userErrorMessage = "Encountered an error setting up iCloud sync for this device. While  you can still add and delete media files like certificates and audio reflections, be aware that such changes may not sync across to your other devices until the app can get iCloud sync setup correctly. Future attempts at fixing this will be made."
            }//: MAIN ACTOR
        }//: SWITCH
    }//: handleMediaFileSubscriptionSetup()
    
    
    // MARK: - QUERY SUBSCRIPTION HELPERS
    
    private func createQuerySubscriptionConfig(
        for mediaType: MediaClass,
        purpose: QuerySubscriptionPurpose
    ) -> CKQuerySubscription {
        let predicate = NSPredicate(value: true)
        var queryZoneID: CKRecordZone.ID
        var subID: String = ""
        var subRecType: String = ""
        
        switch mediaType {
        case .certificate:
            switch purpose {
            case .addingFile:
                subID = String.certAddedQuerySubID
            case .changingFile:
                subID = String.certChangedQuerySubID
            case .deletingFile:
                subID = String.certDeletedQuerySubID
            }//: SWITCH
            queryZoneID = certZone.zoneID
            subRecType = CkRecordType.certificate.rawValue
        case .audioReflection:
            switch purpose {
            case .addingFile:
                subID = String.audioAddedQuerySubID
            case .changingFile:
                subID = String.audioChangedQuerySubID
            case .deletingFile:
                subID = String.audioDeletedQuerySubID
            }//: SWITCH
            queryZoneID = audioZone.zoneID
            subRecType = CkRecordType.audioReflection.rawValue
        }//: SWITCH
        
        var subOption: CKQuerySubscription.Options
        switch purpose {
        case .addingFile:
            subOption = .firesOnRecordCreation
        case .changingFile:
            subOption = .firesOnRecordUpdate
        case .deletingFile:
            subOption = .firesOnRecordDeletion
        }//: SWITCH
        
        let subscription = CKQuerySubscription(
            recordType: subRecType,
            predicate: predicate,
            subscriptionID: subID,
            options: subOption
        )//: subscription
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        
        subscription.notificationInfo = notificationInfo
        subscription.zoneID = queryZoneID
        
        return subscription
    }//: createQuerySubscriptionConfig(for)
    
    private func retrySavingQuerySubscription(
        error webError: CKError,
        for medClass: MediaClass,
        toRetry: (MediaClass, Int) async -> (Bool, CKQuerySubscription?),
        retryCount: Int = 0,
        subInfo: CKQuerySubscription
    ) async -> (Bool, CKQuerySubscription?){
        if shouldRetry(error: webError, currentRetry: retryCount) {
            let delay = calculateRetryBackoff(retryCount: retryCount, error: webError)
            NSLog(">>> CloudMediaBrain: retrySavingQuerySubscription in \(delay) seconds...(attempt #\(retryCount + 1)/3")
            return await toRetry(medClass, retryCount + 1)
        } else {
            NSLog(">>> CloudMediaBrain error: retrySavingQuerySubscription")
            NSLog(">>> Failed to save the newly created subscription, \(subInfo.subscriptionID) to iCloud after making 3 attempts.")
            NSLog(">>> Error: \(webError.localizedDescription)")
            return (false, nil)
        }//: IF (shouldRetry)
    }//: retrySavingQuerySubscription(error, toRetry)
    
    private func handleNonWebErrorQuerySubSetup(
        methodName: String,
        for subID: CKQuerySubscription.ID,
        using error: Error
    ) -> (Bool, CKQuerySubscription?){
        NSLog(">>> CloudMediaBrain error: \(methodName)")
        NSLog(">>> Failed to save the newly created subscription, \(subID) to iCloud, and unable to make any additional attempts.")
        NSLog(">>> Error: \(error.localizedDescription)")
        return (false, nil)
    }//: handleNonWebErrorQuerySubSetup
    
    // MARK: - RETRY LOGIC
    
    private func shouldRetry(error: CKError, currentRetry: Int) -> Bool {
        guard currentRetry < 3 else { return false }
        
        switch error.code {
        case .networkFailure, .networkUnavailable, .serviceUnavailable, .requestRateLimited:
            return true
        case .zoneBusy, .serverResponseLost:
            return true
        default:
            return false
        }//: SWITCH
    }//: shouldRetry(error, currentRetry)
    
    private func calculateRetryBackoff(retryCount: Int, error: CKError) -> TimeInterval {
        // Returning the recommended retry time value if the specific CKError
        // provides for that
        if let retryAfter = error.retryAfterSeconds {
            return retryAfter
        }//: IF LET (retryAfter)
        
        // Return an exponential backoff every 2 seconds
        return pow(2.0, Double(retryCount))
    }//: calculateRetryBackoff
    
    
    private func repeatRecordSearchAfterError(
        error: CKError,
        for objectID: CKRecord.ID,
        with secDelay: Double = 0.01
    ) async -> CKRecord? {
        var mediaRecord: CKRecord? = nil
        for attempt in 0...2 {
            if shouldRetry(error: error, currentRetry: attempt) {
                let delay = calculateRetryBackoff(retryCount: attempt, error: error)
                NSLog(">>> CloudMediaBrain: downloadOnlineMediaFile")
                NSLog(">>> Retrying download after \(delay) seconds (attempt \(attempt + 1)/3")
                try? await Task.sleep(for: .seconds(secDelay))
                do {
                    mediaRecord = try await cloudDB.record(for: objectID)
                } catch {
                    NSLog(">>> Failed record(for) method | attempt #\(attempt)")
                }//: DO-CATCH
            }//: IF (shouldRetry)
        }//: LOOP
        return mediaRecord
    }//: repeatRecordSearchAfterError(error, for, with)
    
    // MARK: - INIT
    
    private init() {
        if userIsAPaidSupporter && iCloudIsAccessible {
            Task{
                if !settings.zonesCreated || needsZoneVerification() {
                    await setupAndVerifyZones()
                }//: IF (zonesCreated OR needsZoneVerification)
                await handleMediaFileSubscriptionSetup()
            }//: TASK
        } else {
            if iCloudIsAccessible == false {
                userErrorMessage = settings.iCloudState.userMessage
            }//:IF
        }//: IF ELSE
    }//: INIT
    
}//: CloudMediaBrain
