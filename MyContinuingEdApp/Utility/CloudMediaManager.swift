//
//  CloudMediaManager.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/2/26.
//

import CoreData
import CloudKit
import Foundation
import SwiftUI

@MainActor
class CloudMediaManager<forMedia>: ObservableObject where forMedia: MediaModel {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    
    @Published var mediaFiles: Set<forMedia> = []
    @Published var mediaFileToLoad: (any MediaModel)? = nil
    
    @Published var isLoading: Bool = false
    @Published var loadingError: Bool = false
    @Published var errorMessage: String = ""
    @Published var loadingErrorMessage: String = ""
    
    var recordResultCount: Int = 0
    var fileHandlingError: FileIOError = .noError
    
    // TODO: Make sure the database property points to the right container!!
    let database = CKContainer(identifier: String.appContainerName).privateCloudDatabase
    
    
    
    let fileSystem = FileManager()
    let nc = NotificationCenter.default
    
    // MARK: - UNIVERSAL METHODS
    
    func createNewCKRecord(
        recordType: CkRecordType,
        forModel: any MediaModel,
        dataAt: URL
    ) -> CKRecord {
        let recordTypeText = recordType.rawValue
        let recordIdentifier: String = UUID().uuidString
        var recordZone: CKRecordZone
        switch recordType {
        case .certificate:
            recordZone = CKRecordZone(zoneName: String.certificateZoneId)
        case .audioReflection:
            recordZone = CKRecordZone(zoneName: String.audioReflectionZoneId)
        }//: SWITCH
        let newRecordId = CKRecord.ID(recordName: recordIdentifier, zoneID: recordZone.zoneID)
        
        let newRecord = CKRecord(recordType: recordTypeText, recordID: newRecordId)
        newRecord[.relPathKey] = forModel.relativePath
        newRecord[.mediaKey] = forModel.mediaType
        newRecord[.locationKey] = forModel.saveLocation
        newRecord[.versionKey] = forModel.appVersion
        newRecord[.assignedObjectKey] = forModel.assignedObjectId
        // This key-value pair is needed for CKQuery predicats
        newRecord[.objectIdStringKey] = forModel.objectIdString
        
        let savedAsset = CKAsset(fileURL: dataAt)
        newRecord[.mediaDataKey] = savedAsset
        
        
        
        return newRecord
    }//: createNewCKRecord()
    
    func deleteMediaItem(cat: MediaClass, for objectId: UUID) async throws {
        let matchingItem = mediaFiles.first(where: {$0.assignedObjectId == objectId})//: matchingItem(first)
        guard let itemToDelete = matchingItem,
              let savedRecord = itemToDelete.cloudRecord else {
            NSLog(">>> CloudMediaManager error: deleteMediaItem()")
            NSLog(">>> No matching CKRecord found for the media being deleted, so the delete request was not sent to iCloud.")
            errorMessage = "No matching record for the file you selected was found in iCloud."
            fileHandlingError = .fileMissing
            throw fileHandlingError
        }//: GUARD
        
        var basePathToUse: URL
        switch cat {
        case .certificate:
            basePathToUse = URL.localCertificatesFolder
        case .audioReflection:
            basePathToUse = URL.localAudioReflectionsFolder
        }//: SWITCH
        
        do {
            try await database.deleteRecord(withID: savedRecord.recordID)
            let assetLocation = itemToDelete.resolveURL(basePath: basePathToUse)
            try fileSystem.removeItem(at: assetLocation)
            mediaFiles.remove(itemToDelete)
        } catch {
            var mediaBeingDeleted: String = ""
            switch cat {
            case .audioReflection:
                mediaBeingDeleted = "audio reflection"
            default:
                mediaBeingDeleted = "certificate"
            }//: SWITCH
            self.errorMessage = "Error deleting the selected \(mediaBeingDeleted). Please try again."
            NSLog(">>> Error deleting the CKRecord for the selected \(mediaBeingDeleted). Error: \(error.localizedDescription)")
        }//: DO-CATCH
    }//: deleteMediaItem()
    
    /// Helper method for obtaining the fileURL property from a CKAsset object in order to move,
    /// delete, or perform some other file writing operation on it.
    /// - Parameter record: CKRecord object containing the CKAsset object
    /// - Returns: URL if value is present and CKAsset key has a corresponding value
    func getCurrentURLForMediaFile(from record: CKRecord) -> URL? {
        if let assetRecord: CKAsset = record[.mediaDataKey] as? CKAsset, let localFile: URL = assetRecord.fileURL {
           return localFile
        } else {
            return nil
        }//: IF ELSE
    }//: getCurrentURLForMediaFile()
    
    
    // MARK: - ERROR METHODS
    
    /// Helper method for all objects descended from the CloudMediaManager class that creates
    /// NSLog statements with details concerning an error encountered while trying to load a media
    /// file via CKQuery and CKRecord.
    /// - Parameters:
    ///   - error: Error type thrown by the applicable method
    ///   - item: CKRecord.ID representing the CKRecord being loaded
    ///   - customMessage: String representing the specific wording about the error that should
    ///   be displayed to the user. If the default empty string is passed in, then a general statement will
    ///   be displayed ("Unable to load saved media files from iCloud"
    ///   - methodName: Name of the method in which the loading error occurred (to be included in
    ///   a NSLog statement)
    ///   - methodClass: Name of the class in which the loading error occurred (also part of the
    ///   NSLog statement)
    ///
    /// - Note: The methodClass parameter has a default value of "Some Media Manager" that should
    /// be replaced with whatever class is calling this method.
    func createLoadFailureLogsAndMessage(
        dueTo error: (any Error)? = nil,
        for item: CKRecord.ID,
        with customMessage: String = "",
        in methodName: String,
        methodClass: String = "Some Media Manager"
    ) {
        NSLog(">>> \(methodClass) error: \(methodName)")
        NSLog(">>> Unable to read one of the CKRecord entities. Record: \(item.recordName)")
        if let existingError = error {
            NSLog(">>> Error: \(existingError.localizedDescription)")
        }//: IF LET
        loadingErrorMessage = customMessage.isEmpty ? "Unable to load saved media files from iCloud." : customMessage
    }//: createLoadFailureAlerts()
    
    
    // MARK: - INIT
    
    init() {
        let certZone = CKRecordZone(zoneName: String.certificateZoneId)
        let reflectionZone = CKRecordZone(zoneName: String.audioReflectionZoneId)
        
        let zoneInit = CKModifyRecordZonesOperation(recordZonesToSave: [certZone, reflectionZone], recordZoneIDsToDelete: nil)
        
        zoneInit.qualityOfService = .default
        zoneInit.perRecordZoneSaveBlock = { _, _ in }
        zoneInit.perRecordZoneDeleteBlock = { _, _ in }
        zoneInit.completionBlock = {
            NSLog("Successfully initialized CKRecordZones.")
        }//: completionBlock
        
        database.add(zoneInit)
    }//: INIT
    
}//: CLASS
