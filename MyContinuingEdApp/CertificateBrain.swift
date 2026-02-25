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
   
    @Published var allCoordinators: Set<CertificateCoordinator> = []
    private var allCloudCoordinators: Set<CertificateCoordinator> = []
    let fileExtension: String = "cert"
    
    // Error handling properties
    @Published var errorMessage: String = ""
    @Published var handlingError: FileIOError = .noError
    
    // Loaded certificate properties
    @Published var loadedCertificates: [Certificate] = []
    @Published var selectedCertificate: Certificate?
    
    var dataController: DataController
    private let fileSystem = FileManager()
    
    let certQuery = NSMetadataQuery()
   
    
    // MARK: - COMPUTED PROPERTIES
    
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
    
    // MARK: - METHODS
    
    // Matching certificate with completed CE Activity
    
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
        
        let matchedActivity: CeActivity = fetchedActivities.first!
        return matchedActivity
    }//: matchCertificatewithActivity
    
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
        }//: forEach (localDirectories)
        
        return foundURLs
    }//: getAllLocallySavedCertURLS()
    
    
     // MARK: - Saving Certificates
    
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
    
    
    // Create the CertificateCoordinator using that url & CertificateMetadata object
    
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
    
    // Create the new CertificateDocument using the custom init
    
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
    func addNewCeCertificate(for activity: CeActivity, with data: Data, dataType: MediaType) {
        // 1. Create metadata using activity
        let certMetaData = createCertificateMetadata(forCE: activity, saveTo: .local, fileType: dataType)
        
        // 2. Create the local url for saving
        let localURL = createDocURL(with: certMetaData, for: .local)
        
        // 3. Create the coordinator object with url and metadata
        if allCoordinators.isEmpty { decodeCoordinatorList() }
        var newCoordinator = createCertificateCoordinator(with: certMetaData, fileAt: localURL)
        
        // 4. Create a new CertificateDocument instance with the url, meta data, and data
        let newCertDoc = CertificateDocument(certURL: localURL, metaData: certMetaData, withData: data)
        
        // 5. Save CertificateDocument to disk locally
        newCertDoc.save(to: localURL, for: .forCreating)
        
        // 6. If the user wishes to save media files to iCloud and iCloud is available, move
        // file to iCloud/UserUbqiquityURL/Documents/Certificates
        guard dataController.prefersCertificatesInICloud,
              storageAvailability == .cloud,
              let _ = cloudCertsFolderURL else {
            if dataController.prefersCertificatesInICloud {
                handlingError = .saveLocationUnavailable
                errorMessage = "The app is currently set to save CE certificates to iCloud, but, unfortunately, iCloud cannot be used at this time. Please check your iCloud/iCloud drive settings as well as how much available free space is on the drive for your account. The certificate was saved locally to the device."
                allCoordinators.insert(newCoordinator)
                encodeCoordinatorList()
            } else {
                // In this situation, the user has indicated that CE certificates are to be saved to
                // the local device only via the control in Settings
                allCoordinators.insert(newCoordinator)
                encodeCoordinatorList()
            }//: IF - ELSE
                return
            }//: GUARD
        
            let iCloudURL = createDocURL(with: certMetaData, for: .cloud)
            
            let _: Task<Void, Never> = Task.detached {
                do {
                   try self.fileSystem.setUbiquitous(true, itemAt: localURL, destinationURL: iCloudURL)
                    newCoordinator.fileURL = iCloudURL
                    self.allCoordinators.insert(newCoordinator)
                    self.encodeCoordinatorList()
                } catch {
                    self.handlingError = .saveLocationUnavailable
                    self.errorMessage = "Attempted to save the certificate to iCloud but was unable to do so. Please check your iCloud/iCloud drive settings as well as how much available free space is on the drive for your account. The certificate was saved locally to the device."
                    self.allCoordinators.insert(newCoordinator)
                    self.encodeCoordinatorList()
                }//: DOC
            }//: TASK
    }//: addNewCeCertificate()
   
   
    // MARK: - Deleting Certificates
    
    /// Method for permanately deleting a saved CE certificate for a completed CeActivity.
    /// - Parameter activity: CeActivity object that has a CE certificate the user wishes to remove
    ///
    /// This method uses the CertificateBrain's allCoordinators property for finding the url of the certificate data to
    /// remove. If a matching coordinator object cannot be returned or if the removeItem(at) method throws an error, the user
    /// will be presented with a custom error message letting them know that they may need to delete the certificate
    /// data manually (based on the class handlingError and errorMessage values).
    func deleteCertificate(for activity: CeActivity) {
        if allCoordinators.isEmpty { decodeCoordinatorList() }
        guard let certCoordinator = allCoordinators.first(where: { coordinator in
            coordinator.assignedObjectID == activity.activityID
        }) else {
            handlingError = .unableToDelete
            errorMessage = "Unable to delete the certificate as the app was unable to locate where the data was saved. Try using the Files app or Finder to manually remove the file."
            return
        }//: GUARD
        
        do {
            try fileSystem.removeItem(at: certCoordinator.fileURL)
            allCoordinators.remove(certCoordinator)
            encodeCoordinatorList()
        } catch {
            handlingError = .unableToDelete
            errorMessage = "Unable to delete the certificate at the specified save location. You may need to manually delete it using the Files app or Finder."
            return
        }
        
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
    func loadSavedCertificate(for activity: CeActivity) {
        if allCoordinators.isEmpty { decodeCoordinatorList() }
        guard let certCoordinator = allCoordinators.first(where: { coordinator in
            coordinator.assignedObjectID == activity.activityID
        }) else {
            handlingError = .loadingError
            errorMessage = "Unable to load the certificate data because the app was unable to locate where the data was saved to."
            return
        }//: GUARD
        
        let savedCert = CertificateDocument(certURL: certCoordinator.fileURL)
        savedCert.open { [weak self] (success) in
            guard success else {
                self?.handlingError = .loadingError
                self?.errorMessage = "Unable to load the certificate data from the saved file location."
                return
            }
            
            if let certMeta = certCoordinator.mediaMetadata as? CertificateMetadata {
                let certData = savedCert.certBinaryData
                switch certMeta.mediaAs {
                case .image:
                    if let thumbImage = certData.certImageThumbnail {
                        self?.selectedCertificate = thumbImage
                    } else {
                        self?.handlingError = .loadingError
                        self?.errorMessage = "Unable to create the thumbnail image for the certificate assigned to this activity."
                    }
                case .pdf:
                    if let pdfData = certData.fullCertificate {
                        self?.selectedCertificate = pdfData
                    } else {
                        self?.handlingError = .loadingError
                        self?.errorMessage = "Unable to load the PDF data for the certificate assigned to this activity."
                    }
                case .audio:
                    return
                }
            } else {
                self?.handlingError = .loadingError
                self?.errorMessage = "Unable to read the metadata for the certificate file which is needed to display the image or PDF."
            }//: IF - ELSE
        }//: open
        
        savedCert.close()
        allCoordinators = []
    }//: loadSavedCertificate
   
    
    // MARK: - MOVING FILES
    
    /// Method for moving locally-saved CE certificate(s) for a specific CE activity to the user's iCloud Drive
    /// - Parameter activity: CeActivity for which the certificate was assigned to
    func moveCertToCloud(for activity: CeActivity) {
        if allCoordinators.isEmpty { decodeCoordinatorList() }
        // 1. Get matching CertificateCoordinator object
        guard var assignedCoordinator = allCoordinators.first(where: { coordinator in
            coordinator.assignedObjectID == activity.activityID
        }) else {
            handlingError = .unableToMove
            errorMessage = "Unable to move certificate because the location on disk was not found."
            return
        }//: GUARD
        
        // 2. Get the URLs for all locally saved CertificateDocuments
        let allLocals = getAllSavedCertificateURLs(from: URL.localCertificatesFolder)
        guard allLocals.isNotEmpty else {
            handlingError = .unableToMove
            errorMessage = "There are no locally saved certificates to move to iCloud."
            return
        }//: GUARD
        
        // 3. Find the locally saved CertificateDocument matching the CeActivity argument (via the
        // coordinator's assignedObjectId property), create a URL for the user's iCloud Drive container
        // and move the file to that new URL.
        guard let localCertToMove = allLocals.first(where: {$0 == assignedCoordinator.fileURL}),
            let _ = cloudCertsFolderURL,
            var certMeta = assignedCoordinator.mediaMetadata as? CertificateMetadata
        else {
            handlingError = .unableToMove
            errorMessage = "Unable to move the locally saved certificate because either the certificate data could not be located on disk, there was an issue connecting to iCloud, or the file's metadata could not be accessed."
            return
        }//: GUARD
        
            let moveToURL = createDocURL(with: certMeta, for: .cloud)
            let _: Task<Void,Never> = Task.detached {
                do {
                    try self.fileSystem.setUbiquitous(
                        true,
                        itemAt: localCertToMove,
                        destinationURL: moveToURL
                    )
                    assignedCoordinator.fileURL = moveToURL
                    certMeta.whereSaved = .cloud
                    self.encodeCoordinatorList()
                } catch {
                    self.handlingError = .unableToMove
                    self.errorMessage = "Unable to move certificate to iCloud."
                }
            }//: TASK (detached)
     
    }//: moveCertToCloud
    
    
    // MARK: - STORAGE SYNC
    
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
    private func syncCoordinatorList() async {
        // Find & retrieve previously saved list, if available
        if let cloudList = coordinatorCloudStoredListURL, let _ = try? Data(contentsOf: cloudList) {
            decodeCoordinatorList(from: cloudList)
            if dataController.prefersCertificatesInICloud == false {
                do {
                    try fileSystem.setUbiquitous(
                        false, itemAt: cloudList,
                        destinationURL: URL.localCertCoordinatorsListFile
                    )
                } catch {
                    handlingError = .unableToMove
                    errorMessage = "Encountered an error when trying to move certificate related data from iCloud to the local device."
                }//: DO - CATCH
            }//: IF (!prefersCertificatesInICloud)
        } else {
            let localList = URL.localCertCoordinatorsListFile
            if let _ = try? Data(contentsOf: localList) {
                decodeCoordinatorList(from: localList)
                if dataController.prefersCertificatesInICloud, let cloudList = coordinatorCloudStoredListURL {
                    do {
                        try fileSystem.setUbiquitous(
                            true, itemAt: localList,
                            destinationURL: cloudList
                        )
                    } catch {
                        handlingError = .unableToMove
                        errorMessage = "Unable to transfer local certificate data to iCloud."
                    }//: DO - CATCH
                    
                } //: IF LET
            }//: IF LET
        }//: IF ELSE
        
        if allCoordinators.isNotEmpty {
            let currentCoordinators = await getCoordinatorsForAllFiles()
            let coordinatorsToAdd = currentCoordinators.subtracting(allCoordinators)
            if coordinatorsToAdd.isNotEmpty {
                let updatedList = allCoordinators.union(coordinatorsToAdd)
                allCoordinators = updatedList
            }
            encodeCoordinatorList()
        } else {
            // If no previously saved list, get new coordinator objects,
            // assign them to the allCoordinators list and then write that
            // list to file in the appropriate location.
            let newCoordinators = await getCoordinatorsForAllFiles()
            allCoordinators = newCoordinators
            encodeCoordinatorList()
        }//: IF - ELSE
    }//: syncCoordinatorList()
    
    
    
   
    // MARK: - COORDINATOR LIST
    
    /// Private method that encodes the allCoordinators set as a JSON file and then writes the file to
    /// the url set by the allCoordinatorsListURL computed property.  If successful, will then set the
    /// allCoordinators set to an empty value in order to free up memory.
    /// - Parameters:
    ///     - location: OPTIONAL URL value if a location other than what is computed by the
    ///     allCoordinatorsListURL property is needed
    private func encodeCoordinatorList(to location: URL? = nil) {
        let encoder = JSONEncoder()
        let encodedList = try? encoder.encode(allCoordinators)
        if let data = encodedList {
            do {
                if let specifiedURL = location {
                    try data.write(to: specifiedURL)
                    allCoordinators = []
                } else {
                    try data.write(to: allCoordinatorsListURL)
                    allCoordinators = []
                }
            } catch {
                handlingError = .writeFailed
                errorMessage = "Unable to save certificates due to an error writing the file that keeps track of where they are saved to."
                return
            }
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
    private func decodeCoordinatorList(from location: URL? = nil) {
        let decoder = JSONDecoder()
        if let specifiedLocation = location, let data = try? Data(contentsOf: specifiedLocation) {
            allCoordinators = (try? decoder.decode(Set<CertificateCoordinator>.self, from: data)) ?? []
        } else {
            if let data = try? Data(contentsOf: allCoordinatorsListURL) {
                allCoordinators = (try? decoder.decode(Set<CertificateCoordinator>.self, from: data)) ?? []
            }//: IF LET
        }//: IF - ELSE
    }//: decodeCoordinatorList()
    
    /// Private method which moves the certificate coordinator JSON file from local storage to the app's
    /// ubiquity container in iCloud.
    ///
    /// - Dependencies:
    ///     - URL.localCertCoordinatorsFolder static property
    ///     - cloudCertsFolderURL computed property
    ///     - allCoordinatorsListURL computed property
    private func moveLocalCoordListToICloud() {
        let savedCoordList = try? Data(contentsOf: URL.localCertCoordinatorsListFile)
        guard let _ = savedCoordList,
            dataController.iCloudAvailability.useLocalStorage == false,
           let _ = cloudCertsFolderURL
        else { return }
        
            let _: Task<Void, Never> = Task.detached {
                try? self.fileSystem.setUbiquitous(
                    true,
                    itemAt: URL.localCertCoordinatorsListFile,
                    destinationURL: self.allCoordinatorsListURL
                )
            }//: TASK (detached)
    }//: moveLocalCoordListToICloud()
    
    
    /// Private method in CertificateBrain that searches the local app sandbox (documentsDirectory/Certificates) and the iCloud ubiquity
    /// container (if available) and creates a new set of CertificateCoordinator objects for each which is then used to set the value
    /// of the allCoordinators property in CertificateBrain.
    /// - Returns:
    ///     - Set of CertificateCoordinator objects for every valid URL in the app's certificates iCloud folder and local device folder
    private func getCoordinatorsForAllFiles() async -> Set<CertificateCoordinator>{
        var createdCoordinators: Set<CertificateCoordinator> = []
        var allCloudSavedFiles: [URL] = []
        var problemFiles: [URL] = []
        let localFiles = getAllSavedCertificateURLs(from: URL.localCertificatesFolder)
        if let cloudDrive = cloudCertsFolderURL {
             let cloudFiles = getAllSavedCertificateURLs(from: cloudDrive)
             cloudFiles.forEach { allCloudSavedFiles.append($0) }
        }//:IF LET
        
        // Iterating through all locally saved certificates to create new coordinators
        // for each
        for file in localFiles {
            var pulledMetadata = extractMetadataFromDoc(at: file)
            if pulledMetadata.isExampleOnly == false {
                pulledMetadata.whereSaved = .local
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
        
        // Creating coordinator objects fro all cloud-based certificates
        if allCloudSavedFiles.count > 0 {
            for file in allCloudSavedFiles {
                var pulledMetadata = extractMetadataFromDoc(at: file)
                if pulledMetadata.isExampleOnly == false {
                    pulledMetadata.whereSaved = .cloud
                    let newCoordinator = CertificateCoordinator(
                        file: file,
                        metaData: pulledMetadata,
                        version: MediaFileVersion(fileAt: file, version: 1.0)
                    )
                    
                    createdCoordinators.insert(newCoordinator)
                } else {
                    problemFiles.append(file)
                }//: IF - ELSE
            }//: LOOP
        }//: IF (count > 0)
        
        guard problemFiles.isEmpty else {
            handlingError = .syncError
            errorMessage = "A problem was encountered while trying to sync certificate data saved on this device and iCloud. If you don't see a certificate that you previously saved then try quitting the app, wait a few minutes, and reopen the app again."
            return []
        }//: GUARD
        
        return createdCoordinators
    }//: getCoordinatorsForAllFiles()
    
    // MARK: - OBSERVER METHODS
    
    /// Observer method that simply logs whenever a batch of query results is completed and the notification is sent by
    /// the system.
    /// - Parameter notification: Notification from observer (in this case, NSMetadataQueryDidUpdate)
    private func certificatesChanged(_ notification: Notification) {
        NSLog(">>> Certificates list updated")
    }//: certificatesChanged
    
    /// Private observer method that fills the allCloudCoordinators property with CertificateCoordinator objects whenever the
    /// certQuery observer gets notified that the query has been completed.
    /// - Parameter notification: Notification being sent from the observer (queryDidFinish)
    private func cloudCertSearchFinished(_notification: Notification) {
        var cloudCoordinators = Set<CertificateCoordinator>()
        certQuery.stop()
        
        let foundCertCount = certQuery.resultCount
        for item in 0..<foundCertCount {
            let resultItem = certQuery.result(at: item)
            if let certResult = resultItem as? NSMetadataItem,
               let certURL = certResult.value(forAttribute: .resultURL) as? URL  {
                let itemMeta = extractMetadataFromDoc(at: certURL)
                let coordinator = createCertificateCoordinator(with: itemMeta, fileAt: certURL)
                cloudCoordinators.insert(coordinator)
            }//: IF LET (as NSMetadataItem)
        }//: LOOP
        
        allCloudCoordinators = cloudCoordinators
        
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
    }//: cloudCertSearchFinished
    
    /// Private selector method used in the .NSUbiquityIdentityDidChange observer for the CertificateBrain class that
    /// moves the certificate coordinator JSON file from local storage to the ubiquity container using the URL created
    /// by the allCoordinatorsURL computed property.
    /// - Parameter notification: Notification object that is generated when the ubiquity idenity value changes
    @objc private func syncCertFileStorage(_ notification: Notification) {
        // TODO: Add logic
       
    }//: moveLocalCoordListToiCloudUpon()
    
    // MARK: - HELPER METHODS (private)
    
    private func extractMetadataFromDoc(at url: URL) -> CertificateMetadata {
        var extractedMetaData: CertificateMetadata = CertificateMetadata.example
        let savedCertDoc = CertificateDocument(certURL: url)
        savedCertDoc.open { (success) in
            guard success else { return }
            extractedMetaData = savedCertDoc.certMetaData
        }//: closure
        
        savedCertDoc.close()
        return extractedMetaData
    }//: extractMetadataFromDoc
    
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
        let searchPredicate = NSPredicate(format: "kMDContentType == public.cert")
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
      
        
        let _: Task<Void, Never> = Task {
            
        }//: TASK
        
        // MARK: - OBSERVERS
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(syncCertFileStorage(_:)),
            name: .NSUbiquityIdentityDidChange,
            object: nil
        )
        
       
        
    }//: INIT
}//: CertificateController
