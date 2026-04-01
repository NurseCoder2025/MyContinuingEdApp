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
    
    private let certBrain: CertificateBrain
    private let coordManager: CertCoordinatorManager
    private let utility: CertUtility
    private let fileSystem = FileManager()
    
    // MARK: - METHODS
    
    /// Method for moving locally-saved CE certificate(s) for a specific CE activity to the user's iCloud Drive
    /// - Parameter activity: CeActivity for which the certificate was assigned to
    func moveCertToCloud(for activity: CeActivity) async {
        if coordManager.currentCoordinators.isEmpty {
            await coordManager.decodeCoordinatorList()
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
                    
                    await coordManager.coordinatorAccess.removeCoordinator(coordinator)
                    await coordManager.coordinatorAccess.insertCoordinator(newCoordinator)
                    await coordManager.encodeCoordinatorList()
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
    
    // MARK: - INIT
    
    init(
        certBrain: CertificateBrain,
        coordManager: CertCoordinatorManager,
        utility: CertUtility
    ) {
        self.certBrain = certBrain
        self.coordManager = coordManager
        self.utility = utility
    }//: INIT
    
    // MARK: - DEINIT
    
}//: CLASS
