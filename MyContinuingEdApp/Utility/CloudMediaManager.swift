//
//  CloudMediaManager.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/2/26.
//

import CloudKit
import Foundation

@MainActor
class CloudMediaManager<forMedia>: ObservableObject where forMedia: MediaModel {
    // MARK: - PROPERTIES
    @Published var mediaFiles: Set<forMedia> = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    private let database = CKContainer(identifier: String.appContainerName).privateCloudDatabase
    
    // MARK: - METHODS
    
    func createNewCKRecord(
        recordType: String,
        at path: String,
        as type: MediaType,
        location: SaveLocation,
        forVersion appVersion: Double,
        for objectID: UUID,
        dataAt: URL
    ) -> CKRecord {
        let newRecord: CKRecord = CKRecord(recordType: recordType)
        newRecord["relativePath"] = path
        newRecord["mediaType"] = type.rawValue
        newRecord["saveLocation"] = location.rawValue
        newRecord["appVersion"] = appVersion
        newRecord["assignedObjectId"] = objectID
        
        let savedAsset = CKAsset(fileURL: dataAt)
        newRecord["mediaData"] = savedAsset
        return newRecord
    }//: createNewCKRecord()
    
    func deleteMediaItem(type: MediaType, for objectId: UUID) async {
        let matchingItem = mediaFiles.first(where: { $0.assignedObjectId == objectId })
        guard let itemToDelete = matchingItem else { return }
        
        do {
            try await database.deleteRecord(withID: itemToDelete.cloudRecord.recordID)
            mediaFiles.remove(itemToDelete)
        } catch {
            var mediaBeingDeleted: String = ""
            switch type {
            case .audio:
                mediaBeingDeleted = "audio reflection"
            default:
                mediaBeingDeleted = "certificate"
            }//: SWITCH
            self.errorMessage = "Error deleting the selected \(mediaBeingDeleted). Please try again."
            NSLog(">>> Error deleting the CKRecord for the selected \(mediaBeingDeleted). Error: \(error.localizedDescription)")
        }//: DO-CATCH
    }//: deleteMediaItem()
    
    
    // MARK: - INIT
    
}//: CLASS
