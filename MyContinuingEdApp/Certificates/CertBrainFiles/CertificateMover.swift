//
//  CertificateMover.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/31/26.
//

import CloudKit
import Foundation
import UIKit

final class CertificateMover: ObservableObject {
    // MARK: - PROPERTIES
    
    private let fileExtension: String = .certFileExtension
    
    private let dataController: DataController
    private let certBrain: CertificateBrain
    private let coordManager: CertCoordinatorManager
    private let utility: CertUtility
    private let fileSystem = FileManager()
    
    // MARK: - Individual Certificates
    
    /// Method for moving locally-saved CE certificate(s) for a specific CE activity to the user's iCloud Drive
    /// - Parameter activity: CeActivity for which the certificate was assigned to
    func moveCertToCloud(for activity: CeActivity) async {
        if coordManager.currentCoordinators.isEmpty {
            coordManager.decodeCoordinatorList()
        }
        // 1. Get matching CertificateCoordinator object
        let coordinators = coordManager.currentCoordinators
        guard let assignedCoordinator = coordinators.first(where: { coordinator in
            coordinator.assignedObjectID == activity.activityID
        }) else {
            await MainActor.run {
                certBrain.handlingError = .unableToMove
                certBrain.errorMessage = "Unable to move certificate because the location on disk was not found."
            }//: MAIN ACTOR
            NSLog(">>>Error finding certificate coordinator for CE activity \(activity.ceTitle) while attempting to move the certificate to iCloud.")
            return
        }//: GUARD
        
        // 2. Get the URLs for all locally saved CertificateDocuments
        let allLocals = (try? fileSystem.getAllSavedMediaFileURLs(from: URL.documentsDirectory, with: fileExtension)) ?? [URL]()
        guard allLocals.isNotEmpty else {
            await MainActor.run {
                certBrain.handlingError = .unableToMove
                certBrain.errorMessage = "There are no locally saved certificates to move to iCloud."
            }//: MAIN ACTOR
            return
        }//: GUARD
        
        // 3. Find the locally saved CertificateDocument matching the CeActivity argument (via the
        // coordinator's assignedObjectId property), create a URL for the user's iCloud Drive container
        // and move the file to that new URL.
        guard let _ = allLocals.first(where: {$0 == assignedCoordinator.fileURL}),
              let _ = certBrain.cloudCertsFolderURL,
            let certMeta = assignedCoordinator.mediaMetadata as? CertificateMetadata
        else {
            await MainActor.run {
                certBrain.handlingError = .unableToMove
                certBrain.errorMessage = "Unable to move the locally saved certificate because either the certificate data could not be located on disk, there was an issue connecting to iCloud, or the file's metadata could not be accessed."
            }//: MAIN ACTOR
            NSLog(">>>Error while attempting to move a CE certificate to iCloud due to either no coordinator object with the local URL in it's fileURL property, an inaccessible URL for the user's iCloud container, or error in downcasting the CertificateMetadata object from the coordinator object.")
            return
        }//: GUARD
        
            let moveToURL = utility.createDocURL(with: certMeta, for: .cloud)
            
            Task.detached {
                do {
                    try await self.moveSavedCertificate(using: assignedCoordinator, to: moveToURL, nowAt: .cloud)
                } catch {
                    NSLog(">>>Error in moving certificate to iCloud. Keeping certificate on local device.")
                }//: DO-CATCH
            }//: TASK
     
    }//: moveCertToCloud
    
    func moveSavedCertificate(
        using coordinator: CertificateCoordinator,
        to newLocation: URL,
        nowAt: SaveLocation
    ) async throws {
        let originalLocation = coordinator.fileURL
        if let certMeta = coordinator.mediaMetadata as? CertificateMetadata {
            do {
                try self.fileSystem.setUbiquitous(
                    (nowAt == .cloud) ? true : false,
                    itemAt: originalLocation,
                    destinationURL: newLocation
                )//: setUbiquitous
                
                // Creating a new CertificateCoordinator object to replace the old one
                // because the object is a struct and can't be modified
                let newSaveLocation = (try? fileSystem.identifyFileURLLocation(for: newLocation)) ?? .local
                let newVersion = MediaFileVersion(fileAt: newLocation, version: 1.0)
                let assignedActivityID = certMeta.assignedObjectId
                let mediaType = certMeta.mediaAs
                let newMetadata = CertificateMetadata(forCeId: assignedActivityID, as: mediaType, fileVersion: newVersion)
                
                let newCoordinator = CertificateCoordinator(file: newLocation, whereSaved: newSaveLocation, metaData: newMetadata)
                
                coordManager.currentCoordinators.remove(coordinator)
                coordManager.currentCoordinators.insert(newCoordinator)
                coordManager.encodeCoordinatorList()
            } catch {
                await MainActor.run {
                    certBrain.handlingError = .unableToMove
                }//: MAIN ACTOR
                switch nowAt {
                case .local:
                    await MainActor.run {
                        certBrain.errorMessage = "Unable to move certificate to local device."
                    }//: MAIN ACTOR
                    NSLog(">>>Error while trying to move a certificate saved in iCloud to the local device. From \(originalLocation) to \(newLocation)")
                    throw certBrain.handlingError
                case .cloud:
                    await MainActor.run {
                        certBrain.errorMessage = "Unable to move certificate to iCloud."
                    }//: MAIN ACTOR
                    NSLog(">>>Error while trying to move a local certificate to the user's iCloud container. From \(originalLocation) to iCloud: \(newLocation)")
                    throw certBrain.handlingError
                case .unknown:
                    await MainActor.run {
                        certBrain.errorMessage = "Unable to move certificate to new location on disk."
                    }//: MAIN ACTOR
                    NSLog(">>> Invalid SaveLocation value (unknown) passed in as an argument to the moveSavedCertificate(using, to, nowAt) method.")
                    throw certBrain.handlingError
                }//: SWITCH
                
            }//: DO - CATCH
        } else {
            await MainActor.run {
                certBrain.handlingError = .unableToMove
                certBrain.errorMessage = "Unable to move the specified certificate file as the metadata indicates it is actually not a CE certificate."
            }//: MAIN ACTOR
            throw certBrain.handlingError
        }//: IF ELSE
    }//: moveSavedCertificate(from: to:)
    
    // MARK: - All Certificates
    
    /// Method that uses certificate coordinator objects to move the files they represent from either the device to iCloud
    /// or vice-versa, depending on the user's cloud storage preference setting.
    /// - Parameter notification: Notification with the name of (String.certCoordinatorListSyncCompleted)
    ///
    /// - Important: This method should NOT be called until the querying of iCloud for any saved certificate objects has been
    /// completed, as indicated by the receipt of the certCoordinatorListSyncCompleted notification.  Otherwise, not all files
    /// may be transferred.
    ///
    /// This selector method calls the moveSavedCertificate(using: to: nowAt:) method to do the actual data transfer, but depends on
    /// the coordinator objects to determine which files are locally saved and which are saved on the cloud.  The
    /// DataController's prefersCertificatesInICloud computed property determines the movement of files.
    func moveAllCertFiles() async {
        let allLocalCerts = coordManager.currentCoordinators
        let allCloudCerts = coordManager.cloudCoordinators
        var unableToMoveCerts: [CertificateCoordinator] = []
        
        switch dataController.prefersCertificatesInICloud {
        case true:
            guard allLocalCerts.isNotEmpty else { return }
            for cert in allLocalCerts {
                if let certMeta = cert.mediaMetadata as? CertificateMetadata {
                    let moveToURL = utility.createDocURL(with: certMeta, for: .cloud)
                    do {
                        try await moveSavedCertificate(using: cert, to: moveToURL, nowAt: .cloud)
                    } catch {
                        unableToMoveCerts.append(cert)
                        NSLog(">>> CertificateMover error: moveCertFiles()")
                        NSLog(">>>Error while trying to move a local certificate to iCloud.")
                        NSLog(">>>The certificate is at: \(cert.fileURL.absoluteString)")
                    }//: DO-CATCH
                }//: IF LET
            }//: LOOP
        case false:
            guard allCloudCerts.isNotEmpty else { return }
            for cert in allCloudCerts {
                if let certMeta = cert.mediaMetadata as? CertificateMetadata {
                    let moveToURL = utility.createDocURL(with: certMeta, for: .local)
                    do {
                        try await moveSavedCertificate(using: cert, to: moveToURL, nowAt: .local)
                    } catch {
                        unableToMoveCerts.append(cert)
                        NSLog(">>> CertificateMover error: moveCertFiles()")
                        NSLog(">>>Error while trying to move an iCloud certificate to local device.")
                        NSLog(">>>The certificate is at: \(cert.fileURL.absoluteString)")
                    }//: DO-CATCH
                }//: IF LET
            }//: LOOP
        }//: SWITCH
        
        if unableToMoveCerts.isNotEmpty {
            await MainActor.run {
                certBrain.handlingError = .incompleteMove
                certBrain.errorMessage = "Unfortunately, not all files were successfully moved. Try again, but you may need to use the Files app or Finder to move them manually."
            }//: MAIN ACTOR
            let totalToMove = allLocalCerts.count + allCloudCerts.count
            NSLog(">>> CertificateMover error: moveCertFiles()")
            NSLog(">>>Error in moving certificates.  Out of the \(totalToMove) certificates that needed to be moved, \(unableToMoveCerts.count) were not.")
            NSLog(">>>See earlier entries for the specific files that weren't moved.")
        }//: IF (isNotEmpty)
        
        let notificationToRemove = Notification.Name(.certCoordinatorListSyncCompleted)
        NotificationCenter.default.removeObserver(self, name: notificationToRemove, object: nil)
    }//: moveAllCertFiles
    
    // MARK: - INIT
    
    init(
        dataController: DataController,
        certBrain: CertificateBrain,
        coordManager: CertCoordinatorManager,
        utility: CertUtility
    ) {
        self.dataController = dataController
        self.certBrain = certBrain
        self.coordManager = coordManager
        self.utility = utility
    }//: INIT
    
    // MARK: - DEINIT
    
}//: CLASS
