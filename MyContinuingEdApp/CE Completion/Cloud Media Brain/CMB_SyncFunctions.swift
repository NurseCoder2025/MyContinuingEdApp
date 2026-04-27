//
//  CMB_SyncFunctions.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/27/26.
//

import CloudKit
import Foundation

extension CloudMediaBrain {
    
    // MARK: - COORDINATING MEDIA CHANGES
    
    func syncLocalMediaFiles() async {
        NSLog(">>> CloudMediaBrain: Fetching all CKRecord changes in iCloud...")
        await fetchCloudDbChanges()
    }//: syncLocalMediaFiles()
    
    // MARK: - FETCHING CHANGES
    
    private func fetchCloudDbChanges() async {
        let mediaBrain = CloudMediaBrain.shared
        let settings = AppSettingsCache.shared
        
        guard settings.iCloudState.iCloudIsAvailable, settings.zonesCreated else { return }
        
        let previousToken = settings.loadDatabaseToken()
        
        do {
            let allDbChanges = try await mediaBrain.cloudDB.databaseChanges(since: previousToken)
            let changeCount = allDbChanges.modifications.count + allDbChanges.deletions.count
            NSLog(">>> DataController | fetchCloudDbChanges: Received \(changeCount) total change notifications.")
            // This loop handles record zones that have changes (within their records)
            for modification in allDbChanges.modifications {
                let zone = modification.zoneID
                await processZoneChanges(forZone: zone)
            }//: LOOP
            
            // This loop handles record zones that have been deleted
            for deletion in allDbChanges.deletions {
                let zone = deletion.zoneID
                await handleZoneDeleted(with: zone)
            }//: LOOP
            
            let newDbToken = allDbChanges.changeToken
            settings.saveDatabaseToken(newDbToken)
            
        } catch {
            NSLog(">>> DataController | fetchCloudDbChanges")
            NSLog(">>> Error: \(error.localizedDescription)")
        }//: DO-CATCH
    }//: fetchCloudDbChanges()
    
    private func processZoneChanges(forZone zone: CKRecordZone.ID) async {
        let isCertZone = (zone.zoneName == String.certificateZoneId)
        let isAudioZone = (zone.zoneName == String.audioReflectionZoneId)
        guard isCertZone || isAudioZone else { return }
        
        let mediaBrain = CloudMediaBrain.shared
        let settings = AppSettingsCache.shared
        let database = mediaBrain.cloudDB
        let mediaList = MasterMediaList.shared
        
        let zoneToken = settings.loadZoneToken(forZone: zone)
        
        // Zone Configuration for CKFetchRecordZoneChangesOperation
        let zoneConfig = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
        zoneConfig.previousServerChangeToken = zoneToken
        
        // CKFetchRecordZoneChangesOperation
        var addedRecords: [CKRecord] = []
        var recsToManuallyDownload: [CKRecord.ID] = []
        var deletedRecords: [CKRecord.ID] = []
        
        let changeOperation = CKFetchRecordZoneChangesOperation()
        changeOperation.recordZoneIDs = [zone]
        changeOperation.configurationsByRecordZoneID = [zone: zoneConfig]
        // MARK: Adding New Media
        changeOperation.recordWasChangedBlock = { record, result in
            switch result {
            case .success(let foundRec):
                addedRecords.append(foundRec)
                Task{
                    _ = await self.addNewLocalMediaFile(usingRec: foundRec)
                }//: TASK
            case .failure(_):
                recsToManuallyDownload.append(record)
                mediaList.addMediaRecWithError(fromRec: record, message: "You will need to manually download the file from iCloud at your convenience.", downloadFlag: true)
                mediaList.saveList()
            }//: SWITCH
        }//: recordWasChangedBlock
        // MARK: Deleting Media
        changeOperation.recordWithIDWasDeletedBlock = { recordID, recType in
            Task{
                let deletionResult = await self.deleteLocallySavedMediaFile(using: recordID)
                if deletionResult {
                    deletedRecords.append(recordID)
                }//: IF (deletionResult)
            }//: TASK
        }//: recordWithIDWasDeletedBlock
        changeOperation.recordZoneChangeTokensUpdatedBlock = { zone, newToken, zData in
            if let updatedToken = newToken {
                settings.saveZoneToken(updatedToken, to: zone)
            }//: IF LET
        }//: recordZoneChangeTokensUpdatedBlock
    
        NSLog(">>> DataController | processZoneChanges")
        NSLog(">>> Total added records: \(addedRecords.count)")
        NSLog(">>> Total deleted records: \(deletedRecords.count)")
        NSLog(">>> Records needing manual download: \(recsToManuallyDownload.count)")
       database.add(changeOperation)
    }//: processZoneChanges
    
    
    // MARK: - SAVING
    private func addNewLocalMediaFile(
        usingRec record: CKRecord
    ) async -> Bool {
        let mediaList = MasterMediaList.shared
        
        // IF the file already exists on the local device, per the
        // MasterMediaList, then do not proceed to transfer the
        // downloaded file to permanent storage
        guard mediaList.doesNOThaveRecord(withID: record.recordID) else { return true } //: GUARD
        
        let mediaBrain = CloudMediaBrain.shared
        let cloudDB = mediaBrain.cloudDB
        let settings = AppSettingsCache.shared
        
        var finalResult: [Bool] = []
        
        let recType = record.recordType
        let logMediaName = createMediaTypeStringForMessages(basedOn: recType)
       
        let retrievedPath = mediaBrain.retrievePathFromID(recID: record.recordID)
        let permanentStore = URL.documentsDirectory.appending(path: retrievedPath, directoryHint: .notDirectory)
        
        let assetKey: String = String.mediaDataKey
        if recType == CkRecordType.certificate.rawValue {
            guard settings.shouldAutoDownloadMedia(forType: .certificate) else {
                mediaList.addMediaRecWithError(fromRec: record.recordID, message: "You need to manually download the certificate from iCloud at your convenience as auto-downloading is currently turned off.", downloadFlag: true)
                mediaList.saveList()
                return true
            }//: GUARD
            if let certData = record[assetKey] as? CKAsset {
                let assetSaveResult = await moveAssetToLocalStorage(
                    asset: certData,
                    type: CKAssetType.certificate,
                    toLoc: permanentStore,
                    recAssociated: record
                )//: moveAssetToLocalStorage
                finalResult.append(assetSaveResult)
            }//: IF LET (certData)
        } else if recType == CkRecordType.audioReflection.rawValue {
            guard settings.shouldAutoDownloadMedia(forType: .audioReflection) else {
                mediaList.addMediaRecWithError(fromRec: record.recordID, message: "You need to manually download the audio reflection file from iCloud at your convenience as auto-downloading is currently turned off.", downloadFlag: true)
                mediaList.saveList()
                return true
            }//: GUARD
            if let audioData = record[assetKey] as? CKAsset {
                let audioSaveResult = await moveAssetToLocalStorage(
                    asset: audioData,
                    type: CKAssetType.audioReflection,
                    toLoc: permanentStore,
                    recAssociated: record
                )//: moveAssetToLocalStorage
                finalResult.append(audioSaveResult)
            }//: IF LET (audioData)
        }//: IF LET (recType)
        
        let allResultsTrue = finalResult.allSatisfy({$0==true})
        return allResultsTrue
    }//: addNewLocalMediaFile()
    
    private func moveAssetToLocalStorage(
        asset: CKAsset,
        type: CKAssetType,
        toLoc location: URL,
        recAssociated record: CKRecord
    ) async -> Bool {
        let mediaList = MasterMediaList.shared
        let recID = record.recordID
        let recType = record.recordType
        let assetName: String = type.rawValue
        
        if let tempURL = asset.fileURL {
            do {
                _ = try FileManager.default.moveItem(at: tempURL, to: location)
                mediaList.addMediaRecord(fromRec: recID, savedAt: location)
                mediaList.saveList()
               return true
            } catch CocoaError.fileNoSuchFile{
                NSLog(">>> DataController error | addNewLocalMediaFile")
                NSLog(">>> The \(assetName) file that should have been downloade from iCloud to the temporary URL \(tempURL.absoluteString) does not exist.")
                let mediaNameForError = createMediaTypeStringForMessages(basedOn: recType)
                mediaList.addMediaRecWithError(fromRec: record.recordID, message: "The \(mediaNameForError) file that should have been downloaded to the device does not exist where it was expected to be found. Please try manually downloading again.")
                mediaList.saveList()
                return false
            } catch CocoaError.fileWriteOutOfSpace {
                NSLog(">>> DataController error | addNewLocalMediaFile")
                NSLog(">>> The device does not have enough free space to save the \(assetName) file.")
                let mediaNameForError = createMediaTypeStringForMessages(basedOn: recType)
                mediaList.addMediaRecWithError(fromRec: record.recordID, message: "Your device's storage capacity is currently full so the app was unable to download the \(mediaNameForError) file. Please free up space and try to manually download again.")
                mediaList.saveList()
                return false
            } catch {
                NSLog(">>> DataController error | addNewLocalMediaFile")
                NSLog(">>> The moveItem method threw an error unrelated to the downloaded \(assetName) file being missing or the user's device being full: \(error.localizedDescription)")
                let mediaNameForError = createMediaTypeStringForMessages(basedOn: recType)
                mediaList.addMediaRecWithError(fromRec: record.recordID, message: "A technical error was encountered while trying to save the \(mediaNameForError) file. Please try manually downloading again.")
                mediaList.saveList()
                return false
            }//: DO - CATCH
        } else {
            NSLog(">>> DataController error | addNewLocalMediaFile")
            NSLog(">>> The CKRecord that was added to the database and fetched by this method either had a nil value for the mediaDataKey, a value that could not be cast as a CKAsset, or the fileURL property was nil.")
            NSLog(">>> The mediaDataKey was: \(String(describing: record.recordID.recordName))")
            let mediaNameForError = createMediaTypeStringForMessages(basedOn: recType)
            mediaList.addMediaRecWithError(fromRec: record.recordID, message: "A technical error was encountered while trying to save the \(mediaNameForError) file. Please try manually downloading again.")
            mediaList.saveList()
            return false
        }//: IF LET (existingAsset)
    }//: moveAssetToLocalStorage(asset, type)
    
    // MARK: - DELETING
    private func deleteLocallySavedMediaFile(using record: CKRecord.ID) async -> Bool {
        let mediaList = MasterMediaList.shared
        let mediaBrain = CloudMediaBrain.shared
        let fileSystem = FileManager.default
        
        guard mediaList.hasRecord(withID: record) else { return false }
        
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
            NSLog(">>> Will make another deletion attempt using the Master List file.")
            return await attemptMediaDeleteUsingMasterList(for: record)
        }//: DO-CATCH
    }//: deleteLocallySavedMediaFile()
    
    private func attemptMediaDeleteUsingMasterList(for record: CKRecord.ID) async -> Bool {
        let mediaList = MasterMediaList.shared
        if let mediaRecord = mediaList.getLocalMediaRecord(using: record),
        let dataAtLocation: URL = mediaRecord.mediaURL {
            do {
                _ = try FileManager.default.removeItem(at: dataAtLocation)
                mediaList.removeMediaRecord(withID: record)
                mediaList.saveList()
                return true
            } catch {
                mediaList.updateMediaRecWithError(
                    fromRec: record,
                    message: "The file could either not be located at or deleted from the following path: \(mediaRecord.mediaURL?.absoluteString ?? "N/A"). You may need to use the Finder or Files app to manually find the file and remove it off the local device yourself.",
                    deleteFlag: true
                )//: updateMediaRecWithError
                mediaList.saveList()
                NSLog(">>> DataController error | attemptMediaDeleteUsingMasterList")
                NSLog(">>> The file system failed to delete the media file using the Master List URL value (\(dataAtLocation.absoluteString)).")
                NSLog(">>> Deletion error details: \(error.localizedDescription).")
                return false
            }//: DO-CATCH
        } else {
            return false
        }//: IF LET (mediaRecord)
        
        
    }//: attemptMediaDeleteUsingMasterList()
    
    // MARK: - ZONE HANDLING
    
    private func handleZoneDeleted(with zoneId: CKRecordZone.ID) async {
        NSLog(">>> DataController | handleZoneDeleted")
        NSLog(">>> Zone deleted: \(zoneId.zoneName)")
        
        let settings = AppSettingsCache.shared
        let name = zoneId.zoneName
        
        // clearing out the zone token
        if name == String.certificateZoneId {
            settings.certZoneToken = nil
        } else if name == String.audioReflectionZoneId {
            settings.audioZoneToken = nil
        }//: IF ELSE
        
        settings.zonesCreated = false
        settings.zoneVerificationDate = nil
        settings.encodeCurrentState()
        
        Task{@MainActor in
            criticalCloudAlertNotice = "The app has been notified that a specific section of your iCloud drive configured for storing CE-related files such as certificates and audio reflections has been deleted. The app will recreate an empty section so new files can be added to it, but be aware that whatever files were in that secion will no longer sync across your devices until they are re-uploaded."
        }//: TASK
    }//: handleZoneDeleted(with)
    
    
}//: EXTENSION

// MARK: - SYNC HELPERS
extension CloudMediaBrain {
    
    private func createMediaTypeStringForMessages(
        basedOn type: CKRecord.RecordType
    ) -> String {
        if type == String.certRecType {
           return "certificate"
        } else if type == String.audioRecType {
           return "audio reflection"
        } else {
            return "media"
        }//: IF ELSE
    }//: createMediaTypeStringForMessage()
    
}//: EXTENSION
