//
//  CertificateSyncDelegate.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/18/26.
//

import CoreData
import Foundation

final class CeCertificateSyncDelegate: NSObject, NSFetchedResultsControllerDelegate {
    // MARK: - PROPERTIES
    private let coordinator: CoreDataCoordination
    private let noticeCenter = NotificationCenter.default
    
    // MARK: - METHODS
    
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        guard let certInfo = anObject as? CertificateInfo else { return }//: GUARD
        
        if (certInfo.removeLocalFile && type == .update) || type == .delete {
            Task {
               let deleteResult = await coordinator.deleteLocalFile(for: certInfo, fileClass: .certificate)
                
                switch deleteResult {
                case .success(let success):
                    noticeCenter.post(name: .localCertFileDeleted, object: nil)
                case .failure(let error):
                    if let filePath = certInfo.resolveURL(basePath: .localCertificatesFolder) {
                        noticeCenter.post(
                            name: .localMediaFileDeletionError,
                            object: nil,
                            userInfo: [
                                String.localMediaDeletionErrorKey: error,
                                String.localMediaFileLocKey: filePath
                            ]
                        )//: POST
                    }//: IF LET
                    NSLog(">>> CeCertificateSyncDelegate error: controller")
                    NSLog(">>> The local certificate file could not be deleted because of an error.")
                    NSLog("Error details: \(error.localizedDescription)")
                }//: SWITCH
            }//: TASK
        }//: IF
    
    }//: controller()
    
    // MARK: - INIT
    
    init(coordinator: CoreDataCoordination) {
        self.coordinator = coordinator
    }//: INIT
    
}//: CeCertificateSyncDelegate
