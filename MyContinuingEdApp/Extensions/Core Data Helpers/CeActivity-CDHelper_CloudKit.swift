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
        Task{@MainActor in
            self.isMarkedForDeletion = true
            self.deletionTimeStamp = Date()
            dataController.save()
        }//: TASK
        let deviceIsOnline = NetworkManager.shared.isConnected
       
        await deleteAssociatedCert(controller: dataController)
        
        // TODO: Add code for deleting associated audio reflections
        
    }//: prepareForDeletion(dataController)
    
    
    // MARK: - HELPERS
    
    private func deleteAssociatedCert(controller: DataController) async {
        if let certInfo = self.certificate, let certModel = certInfo.createMediaModelForCertInfo() {
            await deleteCertSavedOnCloud(certMetadata: certInfo, usingModel: certModel, with: controller)
        } else if let certInfo = self.certificate, certInfo.ckRecordID != nil {
            await deleteCertSavedOnCloud(certMetadata: certInfo, usingModel: nil, with: controller)
        } else {
            await deleteLocalCertFile(controller: controller)
        }//: IF LET (certInfo, certModel)
    }//: deleteAssociatedCerts(in)
    
    private func deleteLocalCertFile(controller: DataController) async {
        let fileSystem = FileManager.default
        if let certInfo = self.certificate, let localURL = certInfo.resolveURL(basePath: URL.documentsDirectory)  {
            do {
                _ = try fileSystem.removeItem(at: localURL)
                Task{@MainActor in
                    controller.delete(certInfo)
                }//: TASK
            } catch let diskError as CocoaError {
                let _ = fileSystem.handleCommonDiskErrors(
                    thrownError: diskError,
                    when: .deleting,
                    objectName: "CeActivity",
                    callingMethod: "deleteLocalCertFile"
                )//: handleCommonDiskErrors
            } catch {
                NSLog(">>>CeActivity | deleteAssociatedCert")
                NSLog(">>>The removeItem method threw an error when trying to delete the certificate saved at: \(localURL.absoluteString)")
                NSLog(">>> The error: \(error.localizedDescription)")
            }//: DO-CATCH
        }//: IF LET (certInfo, localURL)
    }//: deleteLocalMediaFile(at)
    
    private func deleteCertSavedOnCloud(
        certMetadata info: CertificateInfo,
        usingModel model: MediaModel?,
        with controller: DataController
    ) async {
        let deviceIsOnline = NetworkManager.shared.isConnected
        let cloudBrain = CloudMediaBrain.shared
        let masterList = MasterMediaList.shared
        
        let recID = info.certCloudRecordName
        if recID.recordName != String.mediaIdPlaceholder, deviceIsOnline, cloudBrain.iCloudIsAccessible {
                if let certModel = model {
                    let ckRecDeletionResult = await cloudBrain.deleteEntireRecord(for: recID, using: certModel)
                    switch ckRecDeletionResult {
                    case .success(_):
                        await deleteLocalCertFile(controller: controller)
                    case .failure(let error):
                        NSLog(">>> CeActivity method error: prepareForDeletion")
                        NSLog(">>> Unable to delete the CKRecord associated with the CeActivity '\(self.ceTitle)'")
                        NSLog("Details: \(error.localizedDescription)")
                    }//: SWITCH
                } else {
                    let ckRecDeletionResult = await cloudBrain.deleteCompleteCKRecordWithoutModel(for: recID, recordType: .certificate)
                    switch ckRecDeletionResult {
                    case .success(_):
                        await deleteLocalCertFile(controller: controller)
                    case .failure(let error):
                        NSLog(">>> CeActivity method error: prepareForDeletion")
                        NSLog(">>> Unable to delete the CKRecord associated with the CeActivity '\(self.ceTitle)'")
                        NSLog("Details: \(error.localizedDescription)")
                    }//: SWITCH
                }//: IF ELSE (model, certModel)
            // *********** CLOUD REMOVAL ******************
            } else if recID.recordName != String.mediaIdPlaceholder, !deviceIsOnline {
                masterList.updateMediaRecWithError(fromRec: recID, message: "Device was offline at the time of CE activity deletion", deleteFlag: true)
                masterList.saveList()
                await deleteLocalCertFile(controller: controller)
            } else if recID.recordName != String.mediaIdPlaceholder, !cloudBrain.iCloudIsAccessible {
                masterList.updateMediaRecWithError(fromRec: recID, message: "iCloud was unavailable at the time of CE activity deletion", deleteFlag: true)
                masterList.saveList()
                await deleteLocalCertFile(controller: controller)
            } else {
                await deleteLocalCertFile(controller: controller)
            }//: IF ELSE (recordName != .mediaIdPlaceholder)
    }//: deleteCertSavedOnCloud(info, usingModel)
    
}//: EXTENSION
