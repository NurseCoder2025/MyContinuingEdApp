//
//  CertCoordinatorManager.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/31/26.
//

import CloudKit
import CoreData
import Foundation
import UIKit

final class CertCoordinatorManager: ObservableObject {
    // MARK: - PROPERTIES
    @Published var coordinatorAccess = CertificateCoordinatorActor()
    
    let fileExtension: String = .certFileExtension
    private let fileSystem = FileManager()
    
    private let dataController: DataController
    private let certBrain: CertificateBrain
    
    // MARK: - COMPUTED PROPERTIES
    
    /// Computed property in CertificateBrain that sets the URL for the top-level directory into which the
    /// certificate coordinator JSON file will be saved to.
    ///
    /// If the storageAvailability is .local, the user's ubiquitiy container's URL can be obtained, AND
    /// if the user wishes to save CE certificates in iCloud, then the following
    /// will be appended to it:  ApplicationSupport/[String's cloucCertCoordinatorFile static property].
    /// Otherwise, the URL will be set to the .localCertCoordinatorsFolder property of String.
    ///
    /// - Note: Even if all 3 conditions are met for creating an iCloud URL, if the user's iCloud storage
    /// has been maxed out, then ultimately the methods that call this property will end up throwing
    /// an error.  However, in the catch blocks of those methods the FileIOError enum case
    /// "saveLocationUnavailable" will be set for the handlingError published property of the CertificateBrain
    /// class along with a custom error message that will advise the user to check both their iCloud settings
    /// and storage capacity remaining.
    var allCoordinatorsListURL: URL {
        if dataController.prefersCertificatesInICloud,
           certBrain.storageAvailability == .cloud,
           let cloudDrive = certBrain.cloudCertsFolderURL {
            let coordinatorURL = cloudDrive.appending(path: "ApplicationSupport", directoryHint: .isDirectory).appending(path: String.certCoordinatorListFile)
            return coordinatorURL
        } else {
            return URL.localCertCoordinatorsListFile
        }
    }//: allCoordinatorsListURL
    
    /// Private computed property in Certificate Brain that returns the iCloud-based URL for the
    /// coordinator JSON file IF it can be obtained.  Nil if not.
    ///
    /// The path for the file is: .\ApplicationSupport\[String.cloudCertCoordinatorFile] for
    /// whatever ubiquity container is associated with the current Apple Account.
    private var coordinatorCloudStoredListURL: URL? {
        if let cloudDrive = dataController.userCloudDriveURL {
            let coordinatorURL = cloudDrive.appending(path: "ApplicationSupport", directoryHint: .isDirectory).appending(path: String.certCoordinatorListFile, directoryHint: .notDirectory)
            return coordinatorURL
        } else {
            return nil
        }
    }//: coordinatorCloudStoredListURL
    
    var currentCoordinators: Set<CertificateCoordinator> {
        var coordinators: Set<CertificateCoordinator> = []
        Task{
            coordinators = await coordinatorAccess.allCoordinators
        }//: TASK
        return coordinators
    }//: currentCoordinators
    
    // MARK: - METHODS
    
    // MARK: Coordinator Creation (individual)
    
    /// Private method that creates and returns a CertificateCoordinator object as part of the new CE certificate document creation and saving.
    /// - Parameter metaData: CertificateMetadata object for the certificate
    /// - Returns: CertificateCoordinator with the local URL that the data is saved to first along with the meta data
    ///
    /// - Note: If saving the certificate document to iCloud, the save method will handle that process as Apple recommends first saving the data
    /// to local disk prior to saving to iCloud.  Once the file is moved, the coordinator's file url property can be updated.
    func createCertificateCoordinator(with metaData: CertificateMetadata, fileAt location: URL) -> CertificateCoordinator {
        let versionInfo = MediaFileVersion(fileAt: location, version: 1.0)
        let savedAt = (try? fileSystem.identifyFileURLLocation(for: location)) ?? SaveLocation.unknown
        
        // Replacing the initial CertificateMetadata object which has a MediaFileVersion with a temporary
        // URL assigned to the fileURL property with the actual URL that is being used to save the
        // certificate to.
        var metaDataToUpdate = metaData
        metaDataToUpdate.fileVersion = versionInfo
        
        return CertificateCoordinator(file: location, whereSaved: savedAt, metaData: metaDataToUpdate)
    }//: createCertificateCoordinator()
    
    // MARK: Coordinator for CE
    func getCoordinatorFor(activity: CeActivity) async -> CertificateCoordinator? {
        guard activity.activityID != nil else { return nil }
        var identifiedCoordinator: CertificateCoordinator? = nil
       
        if await coordinatorAccess.noCoordinators() {
            await decodeCoordinatorList()
        }//: IF
        
        let coordinators = await coordinatorAccess.allCoordinators
       
        let matchingCoordinator = coordinators.first(where: {
            $0.assignedObjectID == activity.activityID
        })
        identifiedCoordinator = matchingCoordinator
        
        return identifiedCoordinator
    }//: getCoordinatorFor(activity)

    // MARK: SYNC LIST

        /// Private method that ensures the JSON file containing all CertificateCoordinator objects is in sync with all files saved both locally and on
        /// iCloud.
        ///
        /// The method first looks for the JSON file on iCloud, and if it exists then those values are decoded to the allCoordinators property.  It then
        /// checks the user's cloud sync preference for certificates and if it is for local storage only, then the JSON file is moved to the local device.
        /// If the file is not on iCloud or it does not contain any data, then the local directory for the JSON file will be checked and, again, if the user's
        /// certificate storage preference is set to iCloud then the file will be moved to iCloud if possible.
        ///
        /// If there are values in the allCoordinators property after the initial file check and decoding, then the method will update it by comparing the
        /// existing set in allCoordinators with the coordinators set returned by the private method getCoordinatorsForAllFiles().  Any new coordinators
        /// will be added to the allCoordinators set.
        ///
        /// If no values are in allCoordinators, then the getCoordinatorsForAllFliles method is called to create coordinator objects for any CE certificates
        /// saved both on iCloud (if available) and on the local device.  Thoe objects are then used to set the value of allCoordinators and it is then
        /// encoded to disk, using the URL returned from the allCoordinatorsListURL computed property.
        ///
        /// Upon completion, this method also creates a custom notification using the String constant certCoordinatorListSyncCompleted and posts it
        /// to the NotificationCenter so that registered observers can take follow-up actions.
        func syncCoordinatorList() async {
            // Find & retrieve previously saved list, if available
            if let cloudList = coordinatorCloudStoredListURL, let _ = try? Data(contentsOf: cloudList) {
                await decodeCoordinatorList(from: cloudList)
                if dataController.prefersCertificatesInICloud == false {
                    moveCertCoordListTo(location: .local)
                }//: IF (!prefersCertificatesInICloud)
            } else {
                let localList = URL.localCertCoordinatorsListFile
                if let _ = try? Data(contentsOf: localList) {
                    await decodeCoordinatorList(from: localList)
                    if dataController.prefersCertificatesInICloud {
                        moveCertCoordListTo(location: .cloud)
                    } //: IF LET
                }//: IF LET
            }//: IF ELSE
            
            let coordinators = await coordinatorAccess.allCoordinators
            if await coordinatorAccess.doesAllCoordinatorsHaveValues() {
                let currentCoordinators = await createCoordinatorsForAllCertFiles()
                let coordinatorsToRemove = coordinators.subtracting(currentCoordinators)
                let coordinatorsToAdd = currentCoordinators.subtracting(coordinators)
                if coordinatorsToAdd.isNotEmpty {
                    let updatedList = coordinators.union(coordinatorsToAdd)
                    await coordinatorAccess.setAllCoordinatorsValues(with: updatedList)
                }
                if coordinatorsToRemove.isNotEmpty {
                    let updatedList = coordinators.subtracting(coordinatorsToRemove)
                    await coordinatorAccess.setAllCoordinatorsValues(with: updatedList)
                }
                await encodeCoordinatorList()
            } else {
                // If no previously saved list, get new coordinator objects,
                // assign them to the allCoordinators list and then write that
                // list to file in the appropriate location.
                let newCoordinators = await createCoordinatorsForAllCertFiles()
                // TODO: Perform on MainActor??
                await coordinatorAccess.setAllCoordinatorsValues(with: newCoordinators)
                await encodeCoordinatorList()
            }//: IF - ELSE
            
            // Removing all values from the allCloudCoordinators property in
            // coordinatorAccess since they are no longer needed now that all
            // coordinators have been created
            await coordinatorAccess.removeAllCloudCoordinators()
            
            let completedNotice = Notification.Name(.certCoordinatorListSyncCompleted)
            NotificationCenter.default.post(name: completedNotice, object: nil)
        }//: syncCoordinatorList()

    // MARK: LIST HELPERS

        /// Private async method that encodes the all CertificateCoordinator objects into a JSON file and
        /// then writes the file to the url set by the allCoordinatorsListURL computed property.
        /// - Parameters:
        ///     - location: OPTIONAL URL value if a location other than what is computed by the
        ///     allCoordinatorsListURL property is needed
        ///
        /// - Important: This method uses the CertificateCoordinatorActor in order to prevent data races.
        /// The method must be async for this reason, but runs the error handling block on the main actor.
        func encodeCoordinatorList(to location: URL? = nil) async {
            let certCoordinators = await coordinatorAccess.allCoordinators
            let encoder = JSONEncoder()
            let encodedList = try? encoder.encode(certCoordinators)
            if let data = encodedList {
                do {
                    try data.write(to: location ?? allCoordinatorsListURL)
                } catch {
                    await MainActor.run {
                        certBrain.handlingError = .writeFailed
                        certBrain.errorMessage = "Encountered an error writing the file that keeps track of where ce certficicates are saved to."
                        NSLog(">>> CertificateCoordinator encoding error:")
                        NSLog(certBrain.errorMessage)
                    }//: MainActor.run
                }//: DO CATCH
            }//: IF LET
        }//: encodeCoorsinatorList()
        
        /// Private method that decodes and reads the CertificateCoordinator objects contained within the
        /// JSON file saved at the url set by the allCoordinatorsListURL computed property.
        /// - Parameters:
        ///     - location: OPTIONAL URL if a different location from the one produced by the
        ///     allCoordinatorsListURL property is needed
        ///
        /// - Note: This method assigns the value of the decoded JSON file to the allCoordinators property if there is
        /// anything there and it can be decoded.  If not, then no changes will be made to the allCoordinators property.
        ///
        /// The reason for the optional location argument is due to the fact that if it remains nil then the method will use the
        /// computed property allCoordinatorsListURL to set the URL from which to decode the JSON file.  Depending on the
        /// method this function is being called in, a specific location URL may need to be passed in, so this method can handle
        /// any situation.
        func decodeCoordinatorList(from location: URL? = nil) async {
            var certCoordinators: Set<CertificateCoordinator> = []
            let decoder = JSONDecoder()
            if let specifiedLocation = location, let data = try? Data(contentsOf: specifiedLocation) {
                certCoordinators = (try? decoder.decode(Set<CertificateCoordinator>.self, from: data)) ?? []
            } else {
                if let data = try? Data(contentsOf: allCoordinatorsListURL) {
                    certCoordinators = (try? decoder.decode(Set<CertificateCoordinator>.self, from: data)) ?? []
                }//: IF LET
            }//: IF - ELSE
            
            await coordinatorAccess.setAllCoordinatorsValues(with: certCoordinators)
          
        }//: decodeCoordinatorList()
        
        /// Private method which moves the certificate coordinator JSON file from local storage to the app's
        /// ubiquity container in iCloud.
        /// - Parameters:
        ///     - location: SaveLocation enum value indicating whether the list should be moved to iCloud or
        ///     local device
        ///
        /// - Dependencies:
        ///     - URL.localCertCoordinatorsFolder static property
        ///     - cloudCertsFolderURL computed property
        ///     - allCoordinatorsListURL computed property
        func moveCertCoordListTo(location: SaveLocation) {
            switch location {
            case .local:
                guard let cloudList = coordinatorCloudStoredListURL,
                    let _ = try? Data(contentsOf: cloudList) else {
                    certBrain.handlingError = .unableToMove
                    certBrain.errorMessage = "Unable to transfer certificate related data to your device."
                    NSLog(">>>Conditions needed to move the certificate coordinator list to a local device were not met, so moveCertCoordListTo method returned. Possible causes include a nil value for the coordinatorCloudStoredListURL and/or no actual data from the URL.")
                    return
                    }//: GUARD
                
            // Moving coordinator list from iCloud to local device
               Task.detached {
                    do {
                        try self.fileSystem.setUbiquitous(
                            false, itemAt: cloudList,
                            destinationURL: URL.localCertCoordinatorsListFile
                        )
                    } catch {
                        self.certBrain.handlingError = .unableToMove
                        self.certBrain.errorMessage = "Encountered an error when trying to move certificate related data from iCloud to the local device."
                        NSLog(">>>Error: localMoveTask for moving the certificate coordinator list from iCloud to a local device failed becuase the setUbiquitous method threw an error.")
                    }//: DO - CATCH
                }//: TASK
                
                
            case .cloud:
                let savedCoordList = try? Data(contentsOf: URL.localCertCoordinatorsListFile)
                guard let _ = savedCoordList,
                    dataController.iCloudAvailability.useLocalStorage == false,
                      let _ = certBrain.cloudCertsFolderURL
                else {
                    certBrain.handlingError = .unableToMove
                    certBrain.errorMessage = "Unable to transfer certificate related data to iCloud."
                    NSLog(">>>Conditions needed to move the certificate coordinator list to iCloud were not met, so moveCertCoordListTo method returned. Possible causes include a nil value for the coordinatorCloudStoredListURL and/or no actual data from the URL.")
                    return
                }//: GUARD
                
                    // Moving coordinator list to iCloud
                    Task.detached {
                        do {
                            try self.fileSystem.setUbiquitous(
                                true,
                                itemAt: URL.localCertCoordinatorsListFile,
                                destinationURL: self.allCoordinatorsListURL
                            )
                        } catch {
                            self.certBrain.handlingError = .unableToMove
                            self.certBrain.errorMessage = "Encountered an error when trying to move certificate related data from the local device to iCloud."
                            NSLog(">>>Error: setUbiquitous method threw an error when trying to move certificate related data from the local device to iCloud.")
                        }
                    }//: TASK (detached)
            case .unknown:
                certBrain.handlingError = .unableToMove
                certBrain.errorMessage = "Unable to move certificate related data to a different location on disk."
                NSLog(">>> Invalid SaveLocation enum value passed into the moveCertCoordListTo(location) method. The 'unknown' value was used instead of cloud or local.")
            }//: SWITCH
           
        }//: moveLocalCoordListToICloud()
        
        /// Private method in CertificateBrain that searches the local app sandbox (documentsDirectory/Certificates)
        /// and creates a new set of CertificateCoordinator objects for each which is then used to set the value
        /// of the allCoordinators property in the coordinatorAccess actor, along with any values in the allCloudCoordinators property.
        /// - Returns:
        ///     - Set of CertificateCoordinator objects for every valid URL in the app's certificates iCloud folder and local device folder
        ///
        /// - Important: The allCloudCoordinators property must be set before this method is called; otherwise, only
        /// coordinator objects for locally saved certificates will be returned.  The handling of allCloudCoordinators is handled by
        /// the private startICloudCertSearch method.
        func createCoordinatorsForAllCertFiles() async -> Set<CertificateCoordinator>{
            var createdCoordinators: Set<CertificateCoordinator> = []
            let localURL = URL.documentsDirectory
            var localFiles: [URL] = []
            var problemFiles: [URL] = []
            
            localFiles = (
                try? fileSystem.getAllSavedMediaFileURLs(
                    from: localURL,
                    with: fileExtension
                )) ?? []
          
            // Iterating through all locally saved certificates to create new coordinators
            // for each
            for file in localFiles {
                let certDoc = await CertificateDocument(certURL: file)
                if await certDoc.open() {
                    let certMeta = await certDoc.certMetaData
                    let newCoord = CertificateCoordinator(file: file, whereSaved: .local, metaData: certMeta)
                    createdCoordinators.insert(newCoord)
                    await certDoc.close()
                } else {
                    NSLog(">>>Error trying to open a CertificateDocument while iterating through all locally saved certificate files. The specific doc that failed to open is at this url: \(file.absoluteString)")
                    problemFiles.append(file)
                }//: IF await (open)
            }//: LOOP
            
            if problemFiles.isNotEmpty {
                await MainActor.run {
                    certBrain.handlingError = .syncError
                    certBrain.errorMessage = "It appears that not all of the files contained with the Certificates folder were actual certificate files (.cert). Please use the Files app or Finder to check and move any non-certificate files out of the folder."
                    }//: MAIN ACTOR
                NSLog(">>>Error encountered with pulling meta data from local files.  Out of the total number of files, \(localFiles.count), \(problemFiles.count) were not valid certificates.")
            }//: IF (isNotEmpty)
            
            
            let cloudFileCoordinators = await coordinatorAccess.allCloudCoordinators
            cloudFileCoordinators.forEach { coordinator in
                createdCoordinators.insert(coordinator)
            }//: closure
            
            return createdCoordinators
        }//: getCoordinatorsForAllFiles()

        /// Private  method that returns a Set of CertificateCoordinator objects that correspond to a URL that is at the save location as specified
        /// by the savedAt argument value.
        /// - Parameter savedAt: Either .local or .cloud enum value for SaveLocation enum type
        /// - Returns: Set of CertificateCoordinator objects which contain URLs that are at the specified location (device or iCloud)
        ///
        /// This method essentially filters the allCoordinators property using the mediaMetaData property of each coordinator object to retrieve
        /// the whereSaved property from the CertificateMetaData object contained within it.
        func getCoordinatorsForFiles(savedAt: SaveLocation) async -> Set<CertificateCoordinator> {
            if await coordinatorAccess.noCoordinators() { await decodeCoordinatorList() }
        
                var fileCoordinators: Set<CertificateCoordinator> = []
                
                switch savedAt {
                case .local:
                   fileCoordinators = await coordinatorAccess.getCoordinatorsForLocation(.local)
                case .cloud:
                    fileCoordinators = await coordinatorAccess.getCoordinatorsForLocation(.cloud)
                case .unknown:
                    NSLog(">>> Error getting coordinators for saved certificates because the 'unknown' SaveLocation enum type was passed into the getCoordiantorsForFailes(savedAt) method as an argument.")
                    return fileCoordinators
                }//: SWITCH
                
                return fileCoordinators
            }//: getCoordinatorsForFiles
    
    
    // MARK: - INIT
    init(dataController: DataController, certBrain: CertificateBrain) {
        self.dataController = dataController
        self.certBrain = certBrain
    }//: INIT
}//: CLASS
