//
//  CMB_Downloading.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/27/26.
//

import CloudKit
import Foundation

extension CloudMediaBrain {
    
    // MARK: - DOWNLOADING
    
    func downloadOnlineMediaFile(
        for object: CKRecord.ID,
        using model: MediaModel? = nil
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
                    if let objModel = model {
                        if let searchedRec = await searchZoneForRecordMatching(using: objModel) {
                            mediaRecord = searchedRec
                        } else {
                            return Result.failure(CloudSyncError.cloudRecordNotFound(objModel.designatedClass))
                        }//: IF LET (searchedRec)
                    } else {
                        return Result.failure(CloudSyncError.genCloudRecNotFound)
                    }//: IF LET (objModel)
                } //: IF LET (foundRec)
        } catch {
            if let createdModel = model {
                if let searchedRec = await searchZoneForRecordMatching(using: createdModel) {
                    mediaRecord = searchedRec
                } else {
                    return Result.failure(CloudSyncError.cloudRecordNotFound(createdModel.designatedClass))
                }//: IF LET (searchedRec)
            } else {
                return Result.failure(error)
            }//: IF ELSE
        }//: DO - CATCH
        
        if let mediaAsset = mediaRecord[String.mediaDataKey] as? CKAsset,
            let tempURL = mediaAsset.fileURL {
            let pathToUse = retrievePathFromID(recID: object)
            let saveURL: URL = URL.documentsDirectory.appending(path: pathToUse, directoryHint: .notDirectory)
            
            do {
                if fileSystem.fileExists(atPath: saveURL.path) {
                    try fileSystem.removeItem(at: saveURL)
                }//: IF (fileExists)
                
                try fileSystem.moveItem(at: tempURL, to: saveURL)
                return Result.success(saveURL)
            } catch {
                NSLog(">>> CloudMediaBrain error: downloadOnlineMediaFile")
                NSLog(">>> The FileManger moveItem method threw an error while trying to move the CKAsset binary from \(tempURL.absoluteString) to \(saveURL.absoluteString).")
                return Result.failure(CloudSyncError.mediaDownloadFailed)
            }//: DO-CATCH
        } else {
            NSLog(">>> CloudMediaBrain error: downloadOnlineMediaFile")
            NSLog(">>> Either there was no binary data assigned to the mediaDataKey or the fileURL getter for the CKAsset returned a nil value.")
            return Result.failure(CloudSyncError.mediaDownloadFailed)
        }//: IF LET (mediaAsset as? CKAsset)
    }//: downloadOnlineMediaFile(using)
    
    func getOriginalAudioTranscription(
        for audioInfo: AudioInfo,
        using model: MediaModel
    ) async -> (Bool, String?) {
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
                    Task{@MainActor in
                        userErrorMessage = "Failed to retrieve the original transcription from iCloud: \(error.localizedDescription)"
                    }//: TASK
                    return (false, nil)
                }//: SWITCH
            } else {
                return (false, nil)
            }//: IF LET (searchResults.matchResults.first)
        } catch {
            Task{@MainActor in
                userErrorMessage = "Error searching for the original transcription: \(error.localizedDescription)"
            }//: TASK
            return (false, nil)
        }//: DO-CATCH
    }//: getOriginalAudioTranscription(for, using)
    
}//: EXTENSION
