//
//  CertificateController.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/10/26.
//

import CloudKit
import CoreData
import Foundation
import UIKit


final class CertificateBrain: ObservableObject {
    // MARK: - PROPERTIES
   
    private var coordinatorAccess = CertificateCoordinatorActor()
    let fileExtension: String = "cert"
    
    // Error handling properties
     var errorMessage: String = ""
     var handlingError: FileIOError = .noError
    
    // Loaded certificate properties
    var loadedCertificates: [Certificate] = []
    
    /// Published property for holding a PDF/Image (Certificate) object for a specific
    /// CeActivity as obtained by the loadSavedCertificate(for) method.
    var selectedCertificate: Certificate?
    
    var dataController: DataController
    private let fileSystem = FileManager()
    
    let certQuery = NSMetadataQuery()
   
    
    // MARK: - FILE STORAGE
    
    /// Computed property in CertificateBrain that indicates whether local or iCloud storage is to
    /// be used for the purpose of creating URLs for certificate media files.
    ///
    /// - Note: The data type is the StorageToUse enum and its value depends on
    /// the useLocalStorage computed property of the iCloudAvailability enum.
    var storageAvailability: StorageToUse {
        switch dataController.iCloudAvailability.useLocalStorage {
        case true:
            return .local
        case false:
            return .cloud
        }//: SWITCH
    }//: currentStorageChoice
    
    // MARK: Top-Level Folder URL
    
    /// Computed property in CertificateBrain that sets the URL for the top-level directory into which all
    /// CE certificates are to be saved to in iCloud: "Documents/Certificates".  Nil is returned if the url
    /// for the app's directory in the user's iCloud drive account cannot be made.
    var cloudCertsFolderURL: URL? {
        if let existingURL = dataController.userCloudDriveURL, dataController.prefersCertificatesInICloud,
            storageAvailability == .cloud {
            let customCloudURL = URL(
                filePath: "Documents/Certificates",
                directoryHint: .isDirectory,
                relativeTo: existingURL
            )
            return customCloudURL
        } else {
            return nil
        }
    }//: cloudCertsURL
    
    // MARK: - COORDINATOR LIST
    
        // MARK: COMPUTED PROPERTIES
    
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
                    storageAvailability == .cloud,
                    let cloudDrive = cloudCertsFolderURL {
                    let coordinatorURL = URL(
                        filePath: "ApplicationSupport/\(String.certCoordinatorListFile)",
                        directoryHint: .notDirectory,
                        relativeTo: cloudDrive
                     )
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
                    let coordinatorURL = URL(
                        filePath: "ApplicationSupport/\(String.certCoordinatorListFile)",
                        directoryHint: .notDirectory,
                        relativeTo: cloudDrive
                     )
                    return coordinatorURL
                } else {
                    return nil
                }
            }//: coordinatorCloudStoredListURL
    
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
            private func syncCoordinatorList() async {
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
                    let currentCoordinators = await getCoordinatorsForAllFiles()
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
                    let newCoordinators = await getCoordinatorsForAllFiles()
                    // TODO: Perform on MainActor
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
            private func encodeCoordinatorList(to location: URL? = nil) async {
                let certCoordinators = await coordinatorAccess.allCoordinators
                guard certCoordinators.isNotEmpty else { return }
                let encoder = JSONEncoder()
                let encodedList = try? encoder.encode(certCoordinators)
                if let data = encodedList {
                    do {
                        try data.write(to: location ?? allCoordinatorsListURL)
                    } catch {
                        await MainActor.run {
                            handlingError = .writeFailed
                            errorMessage = "Encountered an error writing the file that keeps track of where ce certficicates are saved to."
                            NSLog(">>> CertificateCoordinator encoding error:")
                            NSLog(errorMessage)
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
            private func decodeCoordinatorList(from location: URL? = nil) async {
                var certCoordinators = await coordinatorAccess.allCoordinators
                guard certCoordinators.isEmpty else { return }
                let decoder = JSONDecoder()
                if let specifiedLocation = location, let data = try? Data(contentsOf: specifiedLocation) {
                    certCoordinators = (try? decoder.decode(Set<CertificateCoordinator>.self, from: data)) ?? []
                } else {
                    if let data = try? Data(contentsOf: allCoordinatorsListURL) {
                        certCoordinators = (try? decoder.decode(Set<CertificateCoordinator>.self, from: data)) ?? []
                    }//: IF LET
                }//: IF - ELSE
                
                if certCoordinators.isNotEmpty {
                    await coordinatorAccess.setAllCoordinatorsValues(with: certCoordinators)
                }//: IF
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
            private func moveCertCoordListTo(location: SaveLocation) {
                switch location {
                case .local:
                    guard let cloudList = coordinatorCloudStoredListURL,
                        let _ = try? Data(contentsOf: cloudList) else {
                        handlingError = .unableToMove
                        errorMessage = "Unable to transfer certificate related data to your device."
                        NSLog(">>>Conditions needed to move the certificate coordinator list to a local device were not met, so moveCertCoordListTo method returned. Possible causes include a nil value for the coordinatorCloudStoredListURL and/or no actual data from the URL.")
                        return
                        }//: GUARD
                    
                    let localMoveTask: Task<Void, Never> = Task.detached {
                        do {
                            try self.fileSystem.setUbiquitous(
                                false, itemAt: cloudList,
                                destinationURL: URL.localCertCoordinatorsListFile
                            )
                        } catch {
                            self.handlingError = .unableToMove
                            self.errorMessage = "Encountered an error when trying to move certificate related data from iCloud to the local device."
                            NSLog(">>>Error: localMoveTask for moving the certificate coordinator list from iCloud to a local device failed becuase the setUbiquitous method threw an error.")
                        }//: DO - CATCH
                    }//: TASK
                    
                    if localMoveTask.isCancelled {
                        handlingError = .unableToMove
                        errorMessage = "Encountered an error while trying to move certificate related data to the local device. The operation was cancelled."
                        NSLog(">>>Error: localMoveTask for moving the certificate coordinator list from iCloud to a local device was cancelled.")
                    }//: isCancelled
                    
                case .cloud:
                    let savedCoordList = try? Data(contentsOf: URL.localCertCoordinatorsListFile)
                    guard let _ = savedCoordList,
                        dataController.iCloudAvailability.useLocalStorage == false,
                       let _ = cloudCertsFolderURL
                    else {
                        handlingError = .unableToMove
                        errorMessage = "Unable to transfer certificate related data to iCloud."
                        NSLog(">>>Conditions needed to move the certificate coordinator list to iCloud were not met, so moveCertCoordListTo method returned. Possible causes include a nil value for the coordinatorCloudStoredListURL and/or no actual data from the URL.")
                        return
                    }//: GUARD
                    
                        let cloudMoveTask: Task<Void, Never> = Task.detached {
                            do {
                                try self.fileSystem.setUbiquitous(
                                    true,
                                    itemAt: URL.localCertCoordinatorsListFile,
                                    destinationURL: self.allCoordinatorsListURL
                                )
                            } catch {
                                self.handlingError = .unableToMove
                                self.errorMessage = "Encountered an error when trying to move certificate related data from the local device to iCloud."
                                NSLog(">>>Error: setUbiquitous method threw an error when trying to move certificate related data from the local device to iCloud.")
                            }
                        }//: TASK (detached)
                    
                    if cloudMoveTask.isCancelled {
                        handlingError = .unableToMove
                        errorMessage = "Unable to transfer certificate related data to iCloud."
                        NSLog(">>>CertificateCoordinator JSON file could not be moved to iCloud because the task in moveCertCoordListTo(location) was cancelled.")
                    }//: isCancelled
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
            private func getCoordinatorsForAllFiles() async -> Set<CertificateCoordinator>{
                var createdCoordinators: Set<CertificateCoordinator> = []
                var problemFiles: [URL] = []
                let localFiles = getAllSavedCertificateURLs(from: URL.localCertificatesFolder)
              
                // Iterating through all locally saved certificates to create new coordinators
                // for each
                for file in localFiles {
                    var pulledMetadata = await extractMetadataFromDoc(at: file)
                    if pulledMetadata.isExampleOnly == false {
                        pulledMetadata.markSavedOnDevice()
                        let newCoordinator = CertificateCoordinator(
                            file: file,
                            metaData: pulledMetadata,
                            version: MediaFileVersion(fileAt: file, version: 1.0)
                        )
                        createdCoordinators.insert(newCoordinator)
                    } else {
                        problemFiles.append(file)
                    }
                }//: LOOP
                
                if problemFiles.isNotEmpty {
                    for prob in problemFiles {
                        NSLog(">>>Error: Found a file that was not a valid certificate: \(prob.lastPathComponent)")
                        NSLog(">>>Full url: \(prob.absoluteString)")
                    }//: LOOP
                    await MainActor.run {
                        handlingError = .syncError
                        errorMessage = "It appears that not all of the files contained with the Certificates folder were actual certificate files (.cert). Please use the Files app or Finder to check and move any non-certificate files out of the folder."
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
            private func getCoordinatorsForFiles(savedAt: SaveLocation) async -> Set<CertificateCoordinator> {
                let coordinators = await coordinatorAccess.allCoordinators
                if await coordinatorAccess.isAllCoordinatorsEmpty() { await decodeCoordinatorList() }
            
                    var fileCoordinators: Set<CertificateCoordinator> = []
                    
                    switch savedAt {
                    case .local:
                        fileCoordinators = coordinators.filter {
                            if let certMeta = $0.mediaMetadata as? CertificateMetadata, certMeta.whereSaved == .local,
                                certMeta.isExampleOnly == false
                            {
                                return true
                            } else {
                                return false
                            }
                        }//: filter (closure)
                    case .cloud:
                        fileCoordinators = coordinators.filter {
                            if let certMeta = $0.mediaMetadata as? CertificateMetadata, certMeta.whereSaved == .cloud,
                                certMeta.isExampleOnly == false
                            {
                                return true
                            } else {
                                return false
                            }
                        }//: filter (closure)
                    }//: SWITCH
                    
                    return fileCoordinators
                }//: getCoordinatorsForLocalFiles
    
    
     // MARK: - Saving Certificates
    
    /// Method for creating and saving CE Certificates in the app.
    /// - Parameters:
    ///   - activity: CeActivity object for which a CE certificate was earned
    ///   - data: raw, binary certificate data (either image or pdf)
    ///   - dataType: MediaType enum indicating what the binary data is representing, either an image or pdf
    ///
    ///   This method first creates and saves the CertificateDocument to local storage, but if iCloud is available and the user wishes
    ///   to utilize it, then the document file is moved to iCloud.  If an issue arises with saving to iCloud because the iCloud url can't
    ///   be obtained, then the method updates the CertificateBrain's handlingError and errorMessage published properties so the user
    ///   can be alerted.
    func addNewCeCertificate(for activity: CeActivity, with data: Data, dataType: MediaType) async throws {
        let saveCompletedNotification = Notification.Name(.certSaveCompletedNotification)
        // 1. Create metadata using activity
        let certMetaData = createCertificateMetadata(forCE: activity, saveTo: .local, fileType: dataType)
        
        // 2. Create the local url for saving
        let localURL = createDocURL(with: certMetaData, for: .local)
        
        // 3. Create the coordinator object with url and metadata
        if await coordinatorAccess.isAllCoordinatorsEmpty() { await decodeCoordinatorList() }
        var newCoordinator = createCertificateCoordinator(with: certMetaData, fileAt: localURL)
        
        // 4. Create a new CertificateDocument instance with the url, meta data, and data
        let newCertDoc = await CertificateDocument(
            certURL: localURL,
            metaData: certMetaData,
            withData: data
        )
        
        // 5. Save CertificateDocument to disk locally
        await newCertDoc.save(to: localURL, for: .forCreating)
        
        // 6. If the user wishes to save media files to iCloud and iCloud is available, move
        // file to iCloud/UserUbqiquityURL/Documents/Certificates
        guard dataController.prefersCertificatesInICloud,
              storageAvailability == .cloud,
              let _ = cloudCertsFolderURL else {
            if dataController.prefersCertificatesInICloud {
                await MainActor.run {
                    // In this situation, the user wants to save certificates
                    // to iCloud but can't do so for one of several possible
                    // reasons, including a completely full drive, iCloud
                    // Drive turned off, etc.
                    handlingError = .saveLocationUnavailable
                    errorMessage = "The app is currently set to save CE certificates to iCloud, but, unfortunately, iCloud cannot be used at this time. Please check your iCloud/iCloud drive settings as well as how much available free space is on the drive for your account. The certificate was saved locally to the device."
                }//: MAIN ACTOR
                await coordinatorAccess.insertCoordinator(newCoordinator)
                await encodeCoordinatorList()
                throw handlingError
            } else {
                // In this situation, the user has indicated that CE certificates are to be saved to
                // the local device only via the control in Settings
                await coordinatorAccess.insertCoordinator(newCoordinator)
                await encodeCoordinatorList()
            }//: IF - ELSE
                return
            }//: GUARD
        
            let iCloudURL = createDocURL(with: certMetaData, for: .cloud)
            
                do {
                   try self.fileSystem.setUbiquitous(true, itemAt: localURL, destinationURL: iCloudURL)
                    newCoordinator.fileURL = iCloudURL
                    await coordinatorAccess.insertCoordinator(newCoordinator)
                    await encodeCoordinatorList()
                    await MainActor.run {
                        NotificationCenter.default.post(name: saveCompletedNotification, object: nil)
                    }//: MAIN ACTOR
                } catch {
                    await MainActor.run {
                        handlingError = .saveLocationUnavailable
                        errorMessage = "Attempted to save the certificate to iCloud but was unable to do so. Please check your iCloud/iCloud drive settings as well as how much available free space is on the drive for your account. The certificate was saved locally to the device."
                    }//: MAIN ACTOR
                    await coordinatorAccess.insertCoordinator(newCoordinator)
                    await encodeCoordinatorList()
                    throw handlingError
                }//: DOC
    }//: addNewCeCertificate()
    
        // MARK: SAVE HELPERS
    
            /// Private function that creates the URL for a given CertificateDocument object to be saved to.
            /// - Parameters:
            ///     - metaData: CertificateMetadata object that has the assignedObjectId for the CeActivity the
            /// certificate was earned for
            ///     - saveLocale: SaveLocation enum indicating whether the URL to be created is for local storage or iCloud
            /// - Returns: URL (non-optional) for saving the CertificateDocument object to the specified url location
            ///
            ///- Important: If creating a CertificateDocument for the first time, please use the .local SaveLocation value FIRST
            /// to save the data locally, and then call this method a second time for moving it to iCloud.  If the URL for the iCloud ubiquity container
            /// remains nil at the time this function is called, then be aware that a local url will be created.
            ///
            /// The way the URL is created by this function can be broken down into three main possible formats:
            ///     - Matching CeActivity without a title (unlikely but possible):  .\Certificates\CE Certificate_01/01/2026.cert
            ///     - Matching CeActivity: .\Certificates\CE_activity's_title_trimmed\CE Certificate_01/01/2026.cert
            ///     - No matching CeActivity: .\Certificates\CE Certificate_saved_at_01/01/2026 at 12:00 PM.cert
            ///
            /// The parent directory for the URL created is either the documents directory for local devices, or if using iCloud, the iCloud ubiquity
            /// container URL (as stored in the DataController's userCloudDriveURL property) along with the Documents folder for that URL.
            private func createDocURL(with metaData: CertificateMetadata, for saveLocale: SaveLocation) -> URL {
                var baseFileName: String = ""
                let topFolderURL: URL
                
                switch saveLocale {
                case .local:
                    topFolderURL = URL.localCertificatesFolder
                case .cloud:
                    if let cloudURL = cloudCertsFolderURL {
                        topFolderURL = cloudURL
                    } else {
                        topFolderURL = URL.localCertificatesFolder
                    }
                }//: SWITCH
                
                if let assignedActivity = matchCertificateWithActivity(using: metaData) {
                    let completionDate = assignedActivity.ceActivityCompletedDate
                    baseFileName = "CE Certificate_\(completionDate.formatted(date: .numeric, time: .omitted))"
                    
                    // If there is a matching CeActivity, but there is no title for it for whatever reason
                    // don't create a folder for the activity, but instead just save the certificate in the
                    // Certificates folder (topFolderURL) with the completion date of the activity.
                    guard assignedActivity.ceTitle.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 else {
                            let finalURLPart = "\(baseFileName).\(fileExtension)"
                            let fullURL = topFolderURL.appending(path: finalURLPart, directoryHint: .notDirectory)
                            return fullURL
                        }//: GUARD
                    
                    // Creating a folder with the activity's name IF a matching one was found
                    let activityFolderName = assignedActivity.ceTitle.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "_")
                    let activityFolderURL = topFolderURL.appending(path: activityFolderName, directoryHint: .isDirectory)
                    
                    let finalURLPart = "\(baseFileName).\(fileExtension)"
                    let finalURL = activityFolderURL.appending(path: finalURLPart, directoryHint: .notDirectory)
                    return finalURL
                } else {
                    let saveTime: Date = Date.now
                    let baseFileName = "CE Certificate_saved at_\(saveTime.formatted(date: .numeric, time: .shortened))"
                    let finalURLPart = "\(baseFileName).\(fileExtension)"
                    let fullURL = topFolderURL.appending(path: finalURLPart, directoryHint: .notDirectory)
                    return fullURL
                }
            }//: createDocURL
            
            /// Method for creating CertificateMetadata objects based on the CeActivity object for which the certificate was earned.
            /// - Parameters:
            ///   - activity: CeActivity object marked as completed by the user for which they want to add a certificate
            ///   - location: SaveLocation enum value indicating whether to save the certificate locally or in iCloud
            ///   - fileType: MediaType enum indicating whether the certificate data the metadata is for is an image or PDF
            /// - Returns: CertificateMetadata object with properties set
            ///
            /// - Note: If the CeActivity argument happens to not have an activityID property set, then this method will create
            /// a new UUID value, assign it to the object, and then call the DataController's save method to save the context prior
            /// to creating and returning the new CertificateMetadata object.
            private func createCertificateMetadata(
                forCE activity: CeActivity,
                saveTo location: SaveLocation,
                fileType: MediaType
            ) -> CertificateMetadata {
                if let assignedID = activity.activityID {
                    return CertificateMetadata(saved: location, forCeId: assignedID, as: fileType)
                } else {
                    let newID = UUID()
                    activity.activityID = newID
                    dataController.save()
                    
                    return CertificateMetadata(saved: location, forCeId: newID, as: fileType)
                }//: IF - ELSE
            }//: CertificateMetadata()
            
            /// Private method that creates and returns a CertificateCoordinator object as part of the new CE certificate document creation and saving.
            /// - Parameter metaData: CertificateMetadata object for the certificate
            /// - Returns: CertificateCoordinator with the local URL that the data is saved to first along with the meta data
            ///
            /// - Note: If saving the certificate document to iCloud, the save method will handle that process as Apple recommends first saving the data
            /// to local disk prior to saving to iCloud.  Once the file is moved, the coordinator's file url property can be updated.
            private func createCertificateCoordinator(with metaData: CertificateMetadata, fileAt location: URL) -> CertificateCoordinator {
                let versionInfo = MediaFileVersion(fileAt: location, version: 1.0)
                return CertificateCoordinator(file: location, metaData: metaData, version: versionInfo)
            }//: createCertificateCoordinator()
            
            /// Private method that does the work of finding the CeActivity stored in CoreData that the user is saving
            /// a CE certificate object for.
            /// - Parameter metaData: CertificateMetaData object, which has the ID for the CeActivity
            /// - Returns: the CeActivity entity matching the assignedObjectID property in CertificateMetaData
            private func matchCertificateWithActivity(using metaData: CertificateMetadata) -> CeActivity? {
                let idToMatch = metaData.assignedObjectId
                let context = dataController.container.viewContext
                
                let activityFetch = CeActivity.fetchRequest()
                activityFetch.sortDescriptors = [NSSortDescriptor(key: "activityTitle", ascending: true)]
                activityFetch.predicate = NSPredicate(format: "activityID == %@", idToMatch as CVarArg)
                
                let fetchedActivities = (try? context.fetch(activityFetch)) ?? []
                guard fetchedActivities.count == 1 else { return nil }
                
                if let matchedActivity: CeActivity = fetchedActivities.first {
                    return matchedActivity
                } else {
                    return nil
                }
            }//: matchCertificatewithActivity
        
            
    // MARK: - Deleting Certificates
    
    /// Method for permanately deleting a saved CE certificate for a completed CeActivity.
    /// - Parameter activity: CeActivity object that has a CE certificate the user wishes to remove
    ///
    /// This method uses the CertificateBrain's allCoordinators property for finding the url of the certificate data to
    /// remove. If a matching coordinator object cannot be returned or if the removeItem(at) method throws an error, the user
    /// will be presented with a custom error message letting them know that they may need to delete the certificate
    /// data manually (based on the class handlingError and errorMessage values).
    func deleteCertificate(for activity: CeActivity) async throws {
        let deleteNotification = Notification.Name(.certDeletionCompletedNotification)
        
        if await coordinatorAccess.isAllCoordinatorsEmpty() { await decodeCoordinatorList() }
        
        let coordinators = await coordinatorAccess.allCoordinators
        guard let certCoordinator = coordinators.first(where: { coordinator in
            coordinator.assignedObjectID == activity.activityID
        }) else {
            await MainActor.run {
                handlingError = .unableToDelete
                errorMessage = "Unable to delete the certificate as the app was unable to locate where the data was saved. Try using the Files app or Finder to manually remove the file."
            }//: MAIN ACTOR
            NSLog(">>>Error while attempting to delete CE certificate due to a missing coordinator for the specified activity.  Activity: \(activity.ceTitle)")
            throw handlingError
        }//: GUARD
        
        do {
            try fileSystem.removeItem(at: certCoordinator.fileURL)
            await coordinatorAccess.removeCoordinator(certCoordinator)
            await encodeCoordinatorList()
            NotificationCenter.default.post(name: deleteNotification, object: nil)
        } catch {
            await MainActor.run {
                handlingError = .unableToDelete
                errorMessage = "Unable to delete the certificate at the specified save location. You may need to manually delete it using the Files app or Finder."
            }//: MAIN ACTOR
            NSLog(">>>Error while attempting to delete a CE certificate at \(certCoordinator.fileURL).")
            throw handlingError
        }//: DO-CATCH
        
    }//: deleteCertificate(for)
   
    // MARK: - LOADING CERTIFICATES
    
    /// Method for opening an existing CE certificate file that has been saved and storing the image or PDF data for use in
    /// the user interface via the selectedCertificate published property.
    /// - Parameter activity: CeActivity object for which a CE certificate was assigned to
    ///
    /// - Important: This method relies on the mediaAs property within the certificate's metadata file (which is also
    /// saved to the respective coordinator object) to determine which of the two computed properties in CertificateData to
    /// call: fullCertificate (for the PDF) or certImageThumbnail (for images). The result of either computed property is what is
    /// assigned to the selectedCertificate property in the CertificateBrain class.
    func loadSavedCertificate(for activity: CeActivity) async throws {
        let loadCompletedNotification = Notification.Name(.certLoadingDoneNotification)
        if await coordinatorAccess.isAllCoordinatorsEmpty() { await decodeCoordinatorList() }
        let coordinators = await coordinatorAccess.allCoordinators
        guard let certCoordinator = coordinators.first(where: { coordinator in
            coordinator.assignedObjectID == activity.activityID
        }) else {
            await MainActor.run {
                handlingError = .loadingError
                errorMessage = "Unable to load the certificate data because the app was unable to locate where the data was saved to."
            }//: MAIN ACTOR
            NSLog(">>>Certificate Coordinator error: Unable to find the coordinator for the CE activity \(activity.ceTitle)")
            throw handlingError
        }//: GUARD
        
        let savedCert = await CertificateDocument(certURL: certCoordinator.fileURL)
        if await savedCert.open() {
            if let certMeta = certCoordinator.mediaMetadata as? CertificateMetadata {
                let certData = await savedCert.certBinaryData
                switch certMeta.mediaAs {
                case .image:
                    if let thumbImage = certData.certImageThumbnail {
                        await MainActor.run {
                            selectedCertificate = thumbImage
                            NotificationCenter.default.post(name: loadCompletedNotification, object: nil)
                        }//: MAIN ACTOR
                    } else {
                        await MainActor.run {
                            handlingError = .loadingError
                            errorMessage = "Unable to create the thumbnail image for the certificate assigned to this activity."
                        }//: MAIN ACTOR
                        NSLog(">>>Error creating thumbnail image for the certificate saved at \(certCoordinator.fileURL)")
                        throw handlingError
                    }//: IF ELSE
                case .pdf:
                    if let pdfData = certData.fullCertificate {
                        await MainActor.run {
                            selectedCertificate = pdfData
                             NotificationCenter.default.post(name: loadCompletedNotification, object: nil)
                        }//: MAIN ACTOR
                    } else {
                        await MainActor.run {
                            handlingError = .loadingError
                            errorMessage = "Unable to load the PDF data for the certificate assigned to this activity."
                        }//: MAIN ACTOR
                        NSLog(">>>Error loading PDF data for the certificate saved at \(certCoordinator.fileURL)")
                        throw handlingError
                    }//: IF ELSE
                case .audio:
                    return
                }//: SWITCH
            } else {
                await MainActor.run {
                    handlingError = .loadingError
                    errorMessage = "Unable to read the metadata for the certificate file which is needed to display the image or PDF."
                }//: MAIN ACTOR
                NSLog(">>>Error reading CertificateMetadata for the certificate saved at \(certCoordinator.fileURL)")
                throw handlingError
            }//: IF - ELSE
        } else {
            await MainActor.run {
                handlingError = .loadingError
                errorMessage = "Unable to load the certificate data from the saved file location."
            }//: MAIN ACTOR
            NSLog(">>>Error opening CertificateDocument at \(certCoordinator.fileURL)")
            throw handlingError
        }//: IF - ELSE (open)
        
        await savedCert.close()
    }//: loadSavedCertificate
    
    
    /// CertificateBrain method for retrieving the raw binary data for a saved CE certificate that is associated
    /// with a specific CE activity.
    /// - Parameter activity: CeActivity with a cooresponding CE certificate (as determined by the coordinator)
    /// - Returns: Data object if the certificate was found and the raw data read, nil if not
    func getSavedCertData(for activity: CeActivity) async throws -> Data? {
        var dataToReturn: Data?
        if await coordinatorAccess.isAllCoordinatorsEmpty() { await decodeCoordinatorList() }
        let coordinators = await coordinatorAccess.allCoordinators
        guard let certCoordinator = coordinators.first(where: { coordinator in
            coordinator.assignedObjectID == activity.activityID
        }) else {
            await MainActor.run {
                handlingError = .loadingError
                errorMessage = "Unable to load the certificate data because the app was unable to locate where the data was saved to."
            }//: MAIN ACTOR
            NSLog(">>>Certificate Coordinator error: Unable to find the coordinator for the CE activity \(activity.ceTitle)")
            throw handlingError
        }//: GUARD
        
        let savedCert = await CertificateDocument(certURL: certCoordinator.fileURL)
        if await savedCert.open() {
            let docData = await savedCert.certBinaryData
            if let rawData = docData.certData {
                dataToReturn = rawData
            } else {
                await MainActor.run {
                    handlingError = .loadingError
                    errorMessage = "Unable to read the binary data saved for the CE certificate."
                }//: MAIN ACTOR
                NSLog(">>>Error reading the raw data from the saved certificate for the CE activity \(activity.ceTitle)")
                NSLog(">>>The  certData property of the CertificateDocument object was nil.")
                throw handlingError
            }//: IF ELSE
        } else {
            NSLog(">>>Certificate Coordinator error: Unable to open the certificate for the CE activity \(activity.ceTitle)")
            await MainActor.run {
                handlingError = .loadingError
                errorMessage = "Unable to get the certificate data because the app was unable to open the saved file."
            }//: MAIN ACTOR
            throw handlingError
        }//: IF ELSE
       
        await savedCert.close()
        return dataToReturn
    }//: loadSavedCertData(for)
   
    // MARK: - MOVING FILES
    
    /// Method for moving locally-saved CE certificate(s) for a specific CE activity to the user's iCloud Drive
    /// - Parameter activity: CeActivity for which the certificate was assigned to
    func moveCertToCloud(for activity: CeActivity) async {
        if await coordinatorAccess.isAllCoordinatorsEmpty() { await decodeCoordinatorList() }
        // 1. Get matching CertificateCoordinator object
        let coordinators = await coordinatorAccess.allCoordinators
        guard let assignedCoordinator = coordinators.first(where: { coordinator in
            coordinator.assignedObjectID == activity.activityID
        }) else {
            await MainActor.run {
                handlingError = .unableToMove
                errorMessage = "Unable to move certificate because the location on disk was not found."
            }//: MAIN ACTOR
            NSLog(">>>Error finding certificate coordinator for CE activity \(activity.ceTitle) while attempting to move the certificate to iCloud.")
            return
        }//: GUARD
        
        // 2. Get the URLs for all locally saved CertificateDocuments
        let allLocals = getAllSavedCertificateURLs(from: URL.localCertificatesFolder)
        guard allLocals.isNotEmpty else {
            await MainActor.run {
                handlingError = .unableToMove
                errorMessage = "There are no locally saved certificates to move to iCloud."
            }//: MAIN ACTOR
            return
        }//: GUARD
        
        // 3. Find the locally saved CertificateDocument matching the CeActivity argument (via the
        // coordinator's assignedObjectId property), create a URL for the user's iCloud Drive container
        // and move the file to that new URL.
        guard let _ = allLocals.first(where: {$0 == assignedCoordinator.fileURL}),
            let _ = cloudCertsFolderURL,
            let certMeta = assignedCoordinator.mediaMetadata as? CertificateMetadata
        else {
            await MainActor.run {
                handlingError = .unableToMove
                errorMessage = "Unable to move the locally saved certificate because either the certificate data could not be located on disk, there was an issue connecting to iCloud, or the file's metadata could not be accessed."
            }//: MAIN ACTOR
            NSLog(">>>Error while attempting to move a CE certificate to iCloud due to either no coordinator object with the local URL in it's fileURL property, an inaccessible URL for the user's iCloud container, or error in downcasting the CertificateMetadata object from the coordinator object.")
            return
        }//: GUARD
        
            let moveToURL = createDocURL(with: certMeta, for: .cloud)
            
            let _: Task<Void, Never> = Task.detached {
                await self.moveSavedCertificate(using: assignedCoordinator, to: moveToURL, nowAt: .cloud)
            }//: TASK
     
    }//: moveCertToCloud
    
        // MARK: MOVE HELPERS
    
            /// Private method for obtaining all of the file URLs for any and all CertificateDocuments that have been saved at a specified location (url).
            /// - Parameters:
            ///     - location: the URL for the directory that is to be searched
            /// - Returns: An array of URLs that correspond to saved certificates within the location argument
            ///
            /// - Important: This method only returns the URLs for individual CertificateDocument files.  If the URLs
            /// for sub-directories are needed, a separate method will be needed.  Also, the file extension MUST be "cert" in order for the URL to be added
            /// to the returned array.
            ///
            /// The methodology employed by this method goes by the general file structure envisioned for this app, which is thus:  Within the Documents
            /// folder for the app (either local or iCloud), there should be a Certificates folder and within that subfolders for every certificate saved that has
            /// a matching CeActivity with a non-nil activityTitle property.  However, in the rare event a CeActivity does not have a title, then certificates for
            /// those activities are to be saved in the top level of the Certificates folder.
            ///
            /// Based on that structure, the method first searches the Certificates folder for any "cert" files and adds those URLs to the array that will be
            /// returned. Next, it then iterates through all sub-folders in Certificates and retrieves the individual file URLs from each of them and adds those
            /// to the array.
            ///
            /// - Note: All URLs are created by the createDocURL(with metaData, for saveLocale) private method, which will place all certificates inside of
            /// a folder with the name of the CeActivity assigned to it within the respective ./Certificates folder, but if a CeActivity happens to have a blank title,
            /// then any assigned certificates will be placed in the ./Certificates directory.
            private func getAllSavedCertificateURLs(from location: URL) -> [URL] {
                var foundURLs: [URL] = []
                
                // Checking for any saved certificates in the top-level Certificates folder
                // These would be any that are assigned to a CeActivity that has a nil activityTitle property value.
                let topLevelCerts = (
                    try? fileSystem.contentsOfDirectory(
                        at: location,
                        includingPropertiesForKeys: [.isRegularFileKey],
                        options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]
                    )) ?? []
                if topLevelCerts.isNotEmpty {
                    topLevelCerts.forEach { cert in
                        if cert.pathExtension == fileExtension {
                            foundURLs.append(cert)
                        }
                    }//: forEach(topLevelCerts)
                }//: IF
                
                // Going through all sub-directories, which is the activity name
                let subDirectories = (
                    try? fileSystem.contentsOfDirectory(
                        at: location,
                        includingPropertiesForKeys: [.isDirectoryKey],
                        options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]
                    )) ?? []
                
                guard subDirectories.isNotEmpty else { return foundURLs }
                
                subDirectories.forEach { file in
                    // TODO: Check whether the correct property key was used as the argument
                    if file.hasDirectoryPath {
                        let certsInFile = (
                            try? fileSystem.contentsOfDirectory(
                                at: file,
                                includingPropertiesForKeys: [.isRegularFileKey],
                                options: .skipsHiddenFiles
                            )) ?? []
                        
                        if certsInFile.count > 0 {
                            certsInFile.forEach { cert in
                                if cert.pathExtension == fileExtension {
                                    foundURLs.append(cert)
                                }
                            }//: forEach (certsInFile)
                        }//: IF
                    }//: IF (hasDirectoryPath)
                }//: forEach (localDirectories)
                
                return foundURLs
            }//: getAllLocallySavedCertURLS()
    
            private func moveSavedCertificate(
                using coordinator: CertificateCoordinator,
                to newLocation: URL,
                nowAt: SaveLocation
            ) async {
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
                            let newVersion = MediaFileVersion(fileAt: newLocation, version: 1.0)
                            let assignedActivityID = certMeta.assignedObjectId
                            let mediaType = certMeta.mediaAs
                            let newMetaObject = CertificateMetadata(saved: nowAt, forCeId: assignedActivityID, as: mediaType)
                            
                            let newCoordinator = CertificateCoordinator(file: newLocation, metaData: newMetaObject, version: newVersion)
                            
                            await coordinatorAccess.removeCoordinator(coordinator)
                            await coordinatorAccess.insertCoordinator(newCoordinator)
                            
                        } catch {
                            await MainActor.run {
                                handlingError = .unableToMove
                            }//: MAIN ACTOR
                            switch nowAt {
                            case .local:
                                await MainActor.run {
                                    errorMessage = "Unable to move certificate to local device."
                                }//: MAIN ACTOR
                                NSLog(">>>Error while trying to move a certificate saved in iCloud to the local device. From \(originalLocation) to \(newLocation)")
                            case .cloud:
                                await MainActor.run {
                                    errorMessage = "Unable to move certificate to iCloud."
                                }//: MAIN ACTOR
                                NSLog(">>>Error while trying to move a local certificate to the user's iCloud container. From \(originalLocation) to iCloud: \(newLocation)")
                            }//: SWITCH
                            
                        }//: DO - CATCH
                    
                } else {
                    await MainActor.run {
                        handlingError = .unableToMove
                        errorMessage = "Unable to move the specified certificate file as the metadata indicates it is actually not a CE certificate."
                    }//: MAIN ACTOR
                }//: IF ELSE
            }//: moveSavedCertificate(from: to:)
        
    // MARK: - iCloud Query
    
    /// Private method that initalizes the process for searching for all CE certificate objects saved in the user's iCloud container for the app.
    ///
    /// This method does the following:
    ///     - Sets the properties for the search using the NSMetadataQuery class instance
    ///     - Creates the two required observers for the search
    ///     - Starts the query
    ///
    /// Upon search completion, the observer receiving the query completion notification will then run the private cloudCertSearchFinished
    /// method, which will update the allCloudCoordinators property with whatever objects it was able to find.
    private func startICloudCertSearch() {
        let searchPredicate = NSPredicate(format: "%K LIKE '*.cert'", NSMetadataItemFSNameKey)
        let cloudSearchScope = NSMetadataQueryUbiquitousDocumentsScope
        
        NotificationCenter.default.addObserver(
            forName: .NSMetadataQueryDidUpdate,
            object: certQuery,
            queue: .main,
            using: certificatesChanged
        )//: OBSERVER
        
        NotificationCenter.default.addObserver(
            forName: .NSMetadataQueryDidFinishGathering,
            object: certQuery,
            queue: .main,
            using: cloudCertSearchFinished
        )//: OBSERVER
        
        certQuery.predicate = searchPredicate
        certQuery.searchScopes = [cloudSearchScope]
        certQuery.start()
        
    }//: locateAllCertificatesInCloud()
    
        // MARK: QUERY OBSERVER METHODS
    
        /// Observer method that simply logs whenever a batch of query results is completed and the notification is sent by
        /// the system.
        /// - Parameter notification: Notification from observer (in this case, NSMetadataQueryDidUpdate)
        private func certificatesChanged(_ notification: Notification) {
            NSLog(">>> Certificates list updated")
        }//: certificatesChanged
    
        private func cloudCertSearchFinished(_ notification: Notification) {
            let finishTask: Task<Void, Never> = Task.detached {
                await self.cloudCertSearchEndedHandler()
            }//: TASK
            
            if finishTask.isCancelled {
                handlingError = .syncError
                errorMessage = "Failed to locate certificates in iCloud"
                NSLog(">>>Error: cloudCertSearchEndedHandler cancelled")
            }//: isCancelled
        }//: cloudCertSearchFinished
        
        /// Private observer method that fills the allCloudCoordinators property with CertificateCoordinator objects whenever the
        /// certQuery observer gets notified that the query has been completed.
        ///
        /// - Note: This method is called by the cloudCertSearchFinished(notification) method in the observer object within a
        /// Task due to the observer requiring a synchronous method.
        ///
        /// Upon completion:
        ///     - The query observers created in startICloudCertSearch() are removed in this method.
        ///     - The set of certificate coordinators made for all cloud-based URLs are assigned to the
        ///     allCloudCoordinators property
        ///     - The coordinator JSON file is then updated with the syncCoordinatorList method
        private func cloudCertSearchEndedHandler() async {
            certQuery.stop()
            
            var cloudCoordinators = Set<CertificateCoordinator>()
            var problemFiles: [URL] = []
            
            let foundCertCount = certQuery.resultCount
            for item in 0..<foundCertCount {
                let resultItem = certQuery.result(at: item)
                if let certResult = resultItem as? NSMetadataItem,
                   let certURL = certResult.value(forAttribute: .resultURL) as? URL  {
                    var itemMeta = await extractMetadataFromDoc(at: certURL)
                    if itemMeta.isExampleOnly == false {
                        itemMeta.markSavedOniCloud()
                        let coordinator = createCertificateCoordinator(with: itemMeta, fileAt: certURL)
                        cloudCoordinators.insert(coordinator)
                    } else {
                        problemFiles.append(certURL)
                        NSLog(">>>Unable to read iCloud based certificate metadata at \(certURL.absoluteString)")
                        continue
                    }//: IF ELSE
                }//: IF LET (as NSMetadataItem)
            }//: LOOP
            
            if problemFiles.isNotEmpty {
                await MainActor.run {
                    handlingError = .syncError
                    errorMessage = "It appears that not every certificate file saved in iCloud was readable. Please manually inspect the Certificates folder and remove any non-certificate (.cert) files. All readable ones will be synced."
                }//: MAIN ACTOR
                let totalCount = cloudCoordinators.count + problemFiles.count
                NSLog(">>>Out of the \(totalCount) files found on iCloud, \(problemFiles.count) could not be read due to metadata being unreadable.")
            }//: IF (isNotEmpty)
            
            await coordinatorAccess.setAllCloudCoordinatorsValues(with: cloudCoordinators)
            
            // Removing observers
            NotificationCenter.default.removeObserver(
                self,
                name: .NSMetadataQueryDidUpdate,
                object: certQuery
            )
            
            NotificationCenter.default.removeObserver(
                self,
                name: .NSMetadataQueryDidFinishGathering,
                object: certQuery
            )
            
            await syncCoordinatorList()
            
        }//: cloudCertSearchEndedHandler
    
    
    // MARK: - iCloud STATUS CHANGE
    
    /// Private selector method used in the .NSUbiquityIdentityDidChange observer for the CertificateBrain class that
    /// calls the startICloudCertSearch method to begin the process that will upate the allCloudCoordinators property for
    /// whatever certificate objects are available.
    /// - Parameter notification: Notification object that is generated when the ubiquity idenity value changes
    ///
    /// - Note: By calling startICloudCertSearch, additional observers are created within that method that will run
    /// the completion method (cloudCertSearchFinished) when the completion notification is received by them.
    /// This method will then create a new set of coordinator objects for all certificates found on iCloud and assign them
    /// to the allCloudCoordinators property.  This ensures that the JSON file isn't updated and written to disk until
    /// all cloud coordinator objects have been created and added to the allCoordinators set.
    @objc private func handleICloudStatusChange(_ notification: Notification) {
        startICloudCertSearch()
    }//: moveLocalCoordListToiCloudUpon()
    
    // MARK: - CLOUD PREFERENCE CHANGE
    
    /// Private selector method called whenever the user changes the preference for saving certificate data in iCloud.
    /// - Parameter notification: Notifcation object with the name contained in the String
    /// constant .cloudStoragePreferenceChanged
    ///
    /// This method creates a new observer that listens for a notification with the name from the String constant
    /// .certCoordinatorListSyncCompleted, which is sent by the syncCertFilesStorage method when it is done
    @objc private func cloudPreferenceChanged(_ notification: Notification) {
        
        // Removing any potentially pre-existing observers
        let notificationToRemove = Notification.Name(.certCoordinatorListSyncCompleted)
        NotificationCenter.default.removeObserver(self, name: notificationToRemove, object: nil)
        
        // Creating observer that will recieve notification when the coordinator list JSON
        // file has been updated and saved, following the completion of the startICloudCertSearch
        // and cloudCertSearchFinished methods.  Since it is unknown how long it will take
        // to query iCloud for saved certificate objects, using a coordinator to ensure that
        // the movement of files doesn't begin until after all coordinator objects are
        // updated.
        let syncCompleted = Notification.Name(.certCoordinatorListSyncCompleted)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMovingCertFilesUpon(_:)),
            name: syncCompleted,
            object: nil
        )
        
        // After moving the files to whatever location the user prefers, update the
        // cloud coordinator objects and allCoordinators property to reflect the
        // file movement. Once this method is done, the cloudCertSearchFinished method
        // will be called which will do the property updating along with saving the
        // allCoordinators property values to disk.
        startICloudCertSearch()
        
    }//: cloudPreferenceChange()
    
        // MARK: CHANGE COMPLETION
    
        /// Private selector method that calls and runs the moveCertFiles method on background threads so not as to
        /// cause hangs in the UI as the process can take time and work.
        /// - Parameter notification: Notification with the name of the String constant .certCoordinatorListSyncCompleted
        @objc private func handleMovingCertFilesUpon(_ notification: Notification) {
            Task.detached { [weak self] in
                await self?.moveCertFiles()
            }//: TASK
        }//: handleMovingCertFilesUpon(notification)
    
        /// Private method that uses certificate coordinator objects to move the files they represent from either the device to iCloud
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
        private func moveCertFiles() async {
            let allLocalCerts = await getCoordinatorsForFiles(savedAt: .local)
            let allCloudCerts = await getCoordinatorsForFiles(savedAt: .cloud)
            
            switch dataController.prefersCertificatesInICloud {
            case true:
                guard allLocalCerts.isNotEmpty else { return }
                for cert in allLocalCerts {
                    if let certMeta = cert.mediaMetadata as? CertificateMetadata {
                        let moveToURL = createDocURL(with: certMeta, for: .cloud)
                        await moveSavedCertificate(using: cert, to: moveToURL, nowAt: .cloud)
                    }//: IF LET
                }//: LOOP
            case false:
                guard allCloudCerts.isNotEmpty else { return }
                for cert in allCloudCerts {
                    if let certMeta = cert.mediaMetadata as? CertificateMetadata {
                        let moveToURL = createDocURL(with: certMeta, for: .local)
                        await moveSavedCertificate(using: cert, to: moveToURL, nowAt: .local)
                    }//: IF LET
                }//: LOOP
            }//: SWITCH
            
            let notificationToRemove = Notification.Name(.certCoordinatorListSyncCompleted)
            NotificationCenter.default.removeObserver(self, name: notificationToRemove, object: nil)
        }//: moveCertFiles
    
    // MARK: - HELPER METHODS (private)
    
    private func extractMetadataFromDoc(at url: URL) async -> CertificateMetadata {
        var extractedMetaData: CertificateMetadata = CertificateMetadata.example
        let savedCertDoc = await CertificateDocument(certURL: url)
        if await savedCertDoc.open() {
            extractedMetaData = await savedCertDoc.certMetaData
        }//: closure
        await savedCertDoc.close()
        
        // Logging to help track why metadata reading failed
        if extractedMetaData.isExampleOnly {
            NSLog(">>>Error extracting certificate metadata. Returning example object instead.")
            NSLog(">>>Issue came at the following CertificateDocument URL: \(url.absoluteString)")
        }//: IF (isExampleOnly)
        
        return extractedMetaData
    }//: extractMetadataFromDoc
    
    // MARK: - PREVIEW
    #if DEBUG
    static var preview: CertificateBrain = {
        let dcPreview = DataController.preview
        let cbPreview = CertificateBrain(dataController: dcPreview)
        return cbPreview
    }()
    #endif
    // MARK: - INIT
    
    /// Initializer for the CertificateController class.
    /// - Parameter dataController: DataController instance passed in from the environment
    ///
    /// Upon initialization, the class first decodes the masterCertificateList.json file and places all values into the allCertificates set.
    /// Then, it schedules a task for running the updateCertificateData method, which will look for any new binary files saved to the
    /// local and iCloud Certificates folder and then create corresponding CECertificate model objects for them and add them to the
    /// allCertificates set.  This will ensure that the locally-saved list will stay in-sync with whatever is on the user's iCloud and on the
    /// local device.
    init(dataController: DataController) {
        self.dataController = dataController
      
        startICloudCertSearch()
        
        // MARK: - OBSERVERS
        // **DO NOT Remove These Observers**
        
        // Observer for any Apple Account change (logging in/out)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleICloudStatusChange(_:)),
            name: .NSUbiquityIdentityDidChange,
            object: nil
        )
        
        // Custom observer for when the cloud storage preference setting is
        // changed by the user.
        let certificateStoragePrefChange = Notification.Name(.cloudStoragePreferenceChanged)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cloudPreferenceChanged(_:)),
            name: certificateStoragePrefChange,
            object: nil
        )
        
        
    }//: INIT
    
    // MARK: - DEINIT
    deinit {
        NotificationCenter.default.removeObserver(self)
        
    }//: DEINIT
}//: CertificateController
