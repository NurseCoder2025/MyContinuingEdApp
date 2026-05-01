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
        var masterListType: CkRecordType = .certificate
        if mediaClass == .audioReflection { masterListType = .audioReflection }
        
        if let matchingRec = await findMatchingRecordWith(
            recId: object,
            recType: mediaClass,
            using: model
        ) {
           
            // Delete the entire record
            let recID = matchingRec.recordID
            do {
                _ = try await cloudDB.deleteRecord(withID: recID)
                removeMasterListEntry(forRecord: object)
                return Result.success(true)
            } catch {
                addOrUpdateMasterListEntryWithError(
                    forRecord: object,
                    type: masterListType,
                    errorText: "Unable to delete the media file on iCloud due to: \(error.localizedDescription). You may need to manually delete the file off of your other devices.",
                    setManDeletionFlag: true
                )//: addOrUpdateMasterListEntryWithError
                return Result.failure(
                    CloudSyncError.mediaDeletionError("Error deleting the iCloud file: \(error.localizedDescription)")
                )//: failure
            }//: DO-CATCH
        } else {
            addOrUpdateMasterListEntryWithError(
                forRecord: object,
                type: masterListType,
                errorText: "Unable to delete the media file on iCloud because it could not be found. You may need to manually remove the file from all other devices.", setManDeletionFlag: true
            )//: addOrUpdateMasterListEntryWithError
            return Result.failure(
                CloudSyncError.mediaDeletionError("Unable to locate the iCloud record for the \(model.ckRecType.rawValue) you are trying to delete.")
            )//: failure
        }//: IF LET ELSE (matchingRec)
    }//: deleteEntireRecord(for)
    
    func deleteCompleteCKRecordWithoutModel(
        for recId: CKRecord.ID,
        recordType type: CkRecordType,
        retryCount: Int = 0
    ) async -> Result<Bool, CloudSyncError> {
        guard iCloudIsAccessible && netManager.isConnected else { return Result.failure(CloudSyncError.cloudUnavailable)
        }//: GUARD
        
        do {
            _ = try await cloudDB.deleteRecord(withID: recId)
            removeMasterListEntry(forRecord: recId)
            return Result.success(true)
        } catch let webError as CKError {
            if shouldRetry(error: webError, currentRetry: retryCount) {
                let delay = calculateRetryBackoff(retryCount: retryCount, error: webError)
                _ = try? await Task.sleep(for: .seconds(delay))
                _ = await deleteCompleteCKRecordWithoutModel(for: recId, recordType: type, retryCount: retryCount + 1)
            } else {
                addOrUpdateMasterListEntryWithError(
                    forRecord: recId,
                    type: type,
                    errorText: "Unable to delete the media file on iCloud after multiple attempts due to an iCloud/network error: \(webError.localizedDescription). You may need to manually delete the file off of your other devices.",
                    setManDeletionFlag: true
                )//: addOrUpdateMasterListEntryWithError
                return Result.failure(
                    CloudSyncError.mediaDeletionError("Error deleting the iCloud file: \(webError.localizedDescription)")
                )//: failure
            }//: IF (shouldRetry)
        } catch {
            addOrUpdateMasterListEntryWithError(
                forRecord: recId,
                type: type,
                errorText: "Unable to delete the media file on iCloud due to: \(error.localizedDescription). You may need to manually delete the file off of your other devices.",
                setManDeletionFlag: true
            )//: addOrUpdateMasterListEntryWithError
            return Result.failure(
                CloudSyncError.mediaDeletionError("Error deleting the iCloud file: \(error.localizedDescription)")
            )//: failure
        }//: DO-CATCH
        
        
    }//: deleteCompleteCKRecordWithoutModel()
    
    func removeUploadedCerts(
        certs: [CertificateInfo]
    ) async {
        guard netManager.isConnected && iCloudIsAccessible else { return }
        
        var certsNotRemoved: Int = 0
        
        for cert in certs {
            let recId = cert.certCloudRecordName
            if let certModel = cert.createMediaModelForCertInfo() {
               let deleteResult = await deleteEntireRecord(for: recId, using: certModel)
                switch deleteResult {
                case .success:
                    cert.ckRecordID = nil
                    cert.uploadedToICloud = false
                case .failure:
                    certsNotRemoved += 1
                    let assignedCE = cert.getAssignedCeActivity()
                    let ceName = assignedCE?.ceTitle
                    
                    cert.autoRemoveOffCloud = true
                    NSLog(">>>CloudmediaBrain | removeUploadedCerts")
                    NSLog(">>>The iCloud CKRecord for \(ceName ?? "No Name") could not be deleted due to a network or other issue.")
                    NSLog(">>> The autoRemoveOffCloud flag in CertificateInfo has been set to true for programatic deletion at a future point.")
                }//: SWITCH
            }//: IF LET
        }//: LOOP
        
        NSLog(">>>CloudMediaBrain | removeUploadedCerts")
        NSLog(">>>A total of \(certsNotRemoved) certificates could not be deleted off of iCloud. Their respective autoRemoveOffCloud property has been set to true for future deletion.")
    }//: removeUploadedCerts()
    
    
    func deleteAllAudioFiles() async -> (outcome: Bool, notDeleted: [CKRecord.ID]){
        guard netManager.isConnected && iCloudIsAccessible else { return (false, []) } //: GUARD
        
        var totalCount: Int = 0
        var filesDeleted: Int = 0
        var filesUndeletable: Int = 0
        
        if let retrievedFiles = try? await getAllAudioRecords() {
            let foundFiles = retrievedFiles.found.map(\.recordID)
            let missingFiles = retrievedFiles.missing
            let allFiles = foundFiles + missingFiles
            
            totalCount = allFiles.count
            var unDeletedFiles: [CKRecord.ID] = []
            
            for file in allFiles {
                let deletionResult = await deleteCompleteCKRecordWithoutModel(for: file, recordType: .audioReflection)
                switch deletionResult {
                case .success(_):
                    filesDeleted += 1
                case .failure(let syncError):
                    filesUndeletable += 1
                    unDeletedFiles.append(file)
                    NSLog(">>>CloudMediaBrain | deleteAllAudioFiles")
                    NSLog(">>>Encountered an error while trying to delete all audio reflections off of iCloud. This may be due to a network or other technical error.")
                    NSLog(">>>Details: Record: \(file.recordName) | Error: \(syncError.localizedDescription)")
                    NSLog(">>> This error has been logged in the master file list so the individual file can be manually deleted later.")
                }//: SWITCH
            }//: LOOP
            
            if filesDeleted == totalCount {
                return (true, [])
            } else {
                return (false, unDeletedFiles)
            }//: IF ELSE (filesDeleted == totalCount)
        } else {
            NSLog(">>>CloudMediaBrain | deleteAllAudioFiles")
            NSLog(">>>The method could not delete any of the audio reflection files because of an error that caused the getAllAudioRecords method to throw an error.")
            return (false, [])
        }//: IF LET (retrievedFiles)
    }//: deleteAllAudioFiles()
    
    func deleteAllCertificateFilesOffICloud() async -> (outcome: Bool, notDeleted: [CKRecord.ID]){
        guard netManager.isConnected && iCloudIsAccessible else { return (false, []) } //: GUARD
        
        var totalCount: Int = 0
        var filesDeleted: Int = 0
        var filesUndeletable: Int = 0
        
        if let retrievedFiles = try? await getAllCertificateRecords() {
            let foundFiles = retrievedFiles.found.map(\.recordID)
            let missingFiles = retrievedFiles.missing
            let allFiles = foundFiles + missingFiles
            
            totalCount = allFiles.count
            var unDeletedFiles: [CKRecord.ID] = []
            
            for file in allFiles {
                let deletionResult = await deleteCompleteCKRecordWithoutModel(for: file, recordType: .certificate)
                switch deletionResult {
                case .success(_):
                    filesDeleted += 1
                case .failure(let syncError):
                    filesUndeletable += 1
                    unDeletedFiles.append(file)
                    NSLog(">>>CloudMediaBrain | deleteAllCertificatesOffICloud")
                    NSLog(">>>Encountered an error while trying to delete all CE certificates off of iCloud. This may be due to a network or other technical error.")
                    NSLog(">>>Details: Record: \(file.recordName) | Error: \(syncError.localizedDescription)")
                    NSLog(">>> This error has been logged in the master file list so the individual file can be manually deleted later.")
                }//: SWITCH
            }//: LOOP
            
            if filesDeleted == totalCount {
                return (true, [])
            } else {
                return (false, unDeletedFiles)
            }//: IF ELSE (filesDeleted == totalCount)
        } else {
            NSLog(">>>CloudMediaBrain | deleteAllCertificatesOffICloud")
            NSLog(">>>The method could not delete any of the CE certificate files because of an error that caused the getAllCertificates method to throw an error.")
            return (false, [])
        }//: IF LET (retrievedFiles)
    }//: deleteAllCertificateFilesOffICloud()
    
}//: EXTENSION
