//
//  DataController-CloudKit.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/15/26.
//

import CloudKit
import CoreData
import Foundation

extension DataController {
    
    // MARK: - MEDIA Notification HANDLING
    
    @objc func deleteLocalMediaFileUpon(_ notification: Notification) {
        let prelminCheckResult = okToHandleCKQueryRemoteNotification(for: notification, with: .cloudKitRecordDeleted)

        switch prelminCheckResult {
        case .success(let values):
            let recordID = values.recordId
            let subType = values.subInfo
            
            // MARK: Certificate Deletion
            if subType == String.certDeletedQuerySubID {
                if let matchedCertInfo = findCoreDateEntityForSpecifiedRecord(
                    savedObj: CertificateInfo.self,
                    havingId: recordID,
                    using: "certCKRecordID"
                ), matchedCertInfo.removeLocalFile {
                    let basePathToUse: URL = URL.localCertificatesFolder
                    if let certSavedAt: URL = matchedCertInfo.resolveURL(basePath: basePathToUse) {
                        Task {
                            do {
                                _ = try FileManager.default.removeItem(at: certSavedAt)
                                matchedCertInfo.removeLocalFile = false
                                save()
                            } catch {
                                NSLog(">>> DataController error: deleteLocalMediaFileUpon(notification) - failed to delete file at: \(certSavedAt.path)")
                            }//: DO-CATCH
                        }//: TASK
                    }//: IF LET (certSavedAt)
                }//: IF LET (fetchResults.first)
            } else if subType == String.audioDeletedQuerySubID {
                // TODO: Add code for deleting an audio reflection...
            }//: IF ELSE
            case .failure(let error):
                NSLog(">>> DataController error: deleteLocalMediaFileUpon(notification)")
                NSLog(">>> A user's device received the remote notification that a remotely stored media file was deleted by the user but the notification argument either did not match the expected name or meet the preconditions set in the okToHandleCKQueryRemotNotification method.")
                NSLog(">>> Error: \(error.localizedDescription)")
            }//: SWITCH
    }//: deleteLocalMediaFileUpon(notification)
    
    // MARK: - SUB METHODS
    
    private func deleteLocallySavedMediaFile() {
        
    }//: deleteLocallySavedMediaFile()
    
    
    // MARK: - HELPERS
    
    private func okToHandleCKQueryRemoteNotification(
        for notification: Notification,
        with name: Notification.Name
    ) -> Result<(notice: CKQueryNotification, recordId: CKRecord.ID, subInfo: CKQuerySubscription.ID), CloudKitQuerySubError> {
        guard notification.name == name else {
            return Result.failure(CloudKitQuerySubError.wrongNotificationName)
        }//: GUARD (notification.name)
        
        guard let noticeData = notification.userInfo?[String.userInfoNotificationKey] as? CKQueryNotification else { return Result.failure(CloudKitQuerySubError.queryNotificationNotFound)
        }//: GUARD LET
        
        guard let recordID = noticeData.recordID else {
            return Result.failure(CloudKitQuerySubError.recordIDNotFound)
        }//: GUARD LET (recordID)
        
        guard let subType = noticeData.subscriptionID else {
            return Result.failure(CloudKitQuerySubError.subscriptionIdNotFound)
        }//: GUARD LET
        
        return Result.success((notice: noticeData, recordId: recordID, subInfo: subType))
    }//: okToHandleCKQueryRemoteNotification(for)
    
    
    func findCoreDateEntityForSpecifiedRecord<T: NSManagedObject>(
        savedObj: T.Type,
        havingId recID: CKRecord.ID,
        using objIdField: String
    ) -> T? {
        let context = container.viewContext
        
        let coreDataObjectFetch = NSFetchRequest<T>(entityName: String(describing: savedObj))
        let matchingObjectPred: NSPredicate = NSPredicate(
            format: "\(objIdField) == %@",
            recID as NSObject
        )//: matchingCertInfoPred
        
        coreDataObjectFetch.predicate = matchingObjectPred
        let fetchResults = (try? context.fetch(coreDataObjectFetch)) ?? []
        guard fetchResults.count == 1 else { return nil }
        return fetchResults.first
    }//: findCoreDateEntityForSpecifiedRecord
    
    
}//: DATA CONTROLLER

