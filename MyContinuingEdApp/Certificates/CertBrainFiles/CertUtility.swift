//
//  CertUtility.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/31/26.
//

import CoreData
import Foundation
import UIKit


final class CertUtility {
    // MARK: - PROPERTIES
    
    private let dataController: DataController
    private let certBrain: CertificateBrain
    private let coordManager: CertCoordinatorManager
    
    private let fileExtension: String = .certFileExtension
    
    private let fileSystem = FileManager()
    
    // MARK: - Metadata
    
    func extractMetadataFromDoc(at url: URL) async -> CertificateMetadata {
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
    
    // MARK: - Certificate Confirmation
    
    /// Method for determining if an individual CeActivity has a certificate saved for it, based on a matching coordinator object.
    /// - Parameter activity: CeActivity that is to be checked for a CE certificate
    /// - Returns: True if a matching coordinator can be found and the CertiifcateDocument can be opened at the
    /// coordinator's fileURL property.  False if otherwise.
    func ceActivityHasCertificateSaved(_ activity: CeActivity) async -> Bool {
        if coordManager.currentCoordinators.isEmpty {
            await coordManager.decodeCoordinatorList()
        }//: IF (.isEmpty))
        
        let coordinators = coordManager.currentCoordinators
        guard coordinators.isNotEmpty else { return false }
        
        let matchingCoordinator = coordinators.first { coordinator in
            coordinator.assignedObjectID == activity.activityID
        }//: closure
        
        guard let foundCoordinator = matchingCoordinator else { return false }
        
        let savedCert = await CertificateDocument(certURL: foundCoordinator.fileURL)
        if await savedCert.open() {
            await savedCert.close()
            return true
        } else {
            return false
        }//: IF await
    }//: ceActivityHasCertificateSaved(activity)
    
    // MARK: - URL and Folder Naming
    
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
    func createDocURL(with metaData: CertificateMetadata, for saveLocale: SaveLocation) -> URL {
        let topFolderURL: URL
        
        switch saveLocale {
        case .local:
            topFolderURL = URL.localCertificatesFolder
        case .cloud:
            if let cloudURL = certBrain.cloudCertsFolderURL {
                topFolderURL = cloudURL
            } else {
                topFolderURL = URL.localCertificatesFolder
            }
        case .unknown:
            NSLog(">>> 'unknown' SaveLocation value passed in as an argument to the getCoordinatorsForFiles(savedAt) method in CertificateBrain. Using the local certificates file as the top folder URL.")
            topFolderURL = URL.localCertificatesFolder
        }//: SWITCH
        
        let topFolderExists =  fileSystem.doesFolderExistAt(path: topFolderURL)
        if topFolderExists {
            if let assignedActivity = matchCertificateWithActivity(using: metaData) {
                let certFileName = createCertificateFileName(for: assignedActivity)
                // If there is a matching CeActivity, but there is no title for it for whatever reason
                // don't create a folder for the activity, but instead just save the certificate in the
                // Certificates folder (topFolderURL) with the completion date of the activity.
                guard assignedActivity.ceTitle.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 else {
                    return topFolderURL.appending(path: certFileName, directoryHint: .notDirectory)
                }//: GUARD
                
                // Creating a folder with the activity's name IF a matching one was found
                let activityFolderName = createActivitySubFolderName(for: assignedActivity)
                let activityFolderURL = topFolderURL.appending(path: activityFolderName, directoryHint: .isDirectory)
                let activityFolderExists =  fileSystem.doesFolderExistAt(path: activityFolderURL)
                
                if activityFolderExists {
                    return activityFolderURL.appending(path: certFileName, directoryHint: .notDirectory)
                } else {
                    // If the activity sub-folder cannot be created for whatever reason, save the file in the
                    // respective top-level folder ("Certificates")
                    return topFolderURL.appending(path: certFileName, directoryHint: .notDirectory)
                }
            } else {
                // Certificates that do not have an assigned CeActivity (unlikely but potential scenario)
                // Saving them to the main certificates directory ("Certificates") for the app
                let certFileName = createCertificateFileName(for: nil)
                return topFolderURL.appending(path: certFileName, directoryHint: .notDirectory)
            }
        } else {
            // If the "Certificates" folder cannot be created, then set the URL for a certificate
            // using the Documents folder instead.
            let certFileName = createCertificateFileName(for: matchCertificateWithActivity(using: metaData))
            switch saveLocale {
            case .local:
                return URL.documentsDirectory.appending(path: certFileName, directoryHint: .notDirectory)
            case .cloud:
                if let cloudURL = dataController.userCloudDriveURL {
                    let cloudDocsFolder = URL(
                        filePath: "Documents",
                        directoryHint: .isDirectory,
                        relativeTo: cloudURL
                    )//: cloudDocsFolder
                    let cloudDocsExists =  fileSystem.doesFolderExistAt(path: cloudDocsFolder)
                    if cloudDocsExists {
                        return cloudDocsFolder.appending(path: certFileName, directoryHint: .notDirectory)
                    } else {
                        // Save certificate to the app's ubiquity container top-level directory if
                        // the Documents folder is not available (can't be created)
                        NSLog(">>>Unable to find/create Documents folder in the app's ubiquity container. Saving certificate to the top-level directory of the ubiquity container.")
                        return cloudURL.appending(path: certFileName, directoryHint: .notDirectory)
                    }//: IF - ELSE (cloudDocsExists)
                } else {
                    // If the iCloud ubiquity container URL cannot be retrieved, then set the URL
                    // to the local device
                    NSLog(">>>Error trying to save certificate to iCloud due to the ubiquity container URL being a nil value at this time. Saving to the local device's Documents folder.")
                    return URL.documentsDirectory.appending(path: certFileName, directoryHint: .notDirectory)
                }//: IF - ELSE (cloudURL)
            case .unknown:
                let localURL = URL.documentsDirectory.appending(path: certFileName, directoryHint: .notDirectory)
                NSLog(">>> Returning a local URL for a certificate due to the 'unknown' SaveLocation value type being passed into the createDocURL(with, for) method as an argument.")
                NSLog(">>> The new URL being returned is: \(localURL.absoluteString)")
                return localURL
            }//: SWITCH
        }//: IF ELSE
    }//: createDocURL

    /// Private method that creates the name for the sub-folder holding CE certificate objects for a specific activity.
    /// - Parameter ce: CeActivity that the certificate is being saved to
    /// - Returns: String value for the folder name
    ///
    /// The folder convention for CE certificates in this app is that all certificate objects are to be stored within a top-level
    /// "Certificates" folder within the local or iCloud Documents folder.  Then, inside of the "Certificates" folder additional
    /// sub-folders will be created for each CeActivity, using the name of the activity as its name to hold all certificate objects
    /// for that activity. To keep the folder names to a reasonable length, the method limits the returned string to a max of
    /// 25 characters (after trimming the activity's title property to remove any white spaces and lines).
    func createActivitySubFolderName(for ce: CeActivity) -> String {
        let activityFolderName = fileSystem.sanitizeFileName(ce.ceTitle).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "_")
        
        let maxNameLength: Int = 25
        
        if activityFolderName.count > maxNameLength {
            let shortenedName = activityFolderName.prefix(maxNameLength)
            return String(shortenedName)
        } else  {
            return activityFolderName
        }//: IF ELSE
    }//: createActivitySubFolder

    /// Private method that creates the filename string to be used for the last URL path component for a CE certificate object.
    /// - Parameter activity: CeActivity that the certificate is to be associated with (optional)
    /// - Returns: String value using the completion date for the activity or, if the activity argument is nil, a name using the
    /// current date and time value.
    ///
    /// - Note: The reason for making the activity parameter optional is because of the possibility a CeActivity may not be,
    /// and is not required to be, assigned to a CertificateDocument object.  Both situations are handled by the method.
    func createCertificateFileName(for activity: CeActivity?) -> String {
        var baseFileName: String = ""
        let calendar = Calendar.current
        if let assignedCe = activity {
            let completionDate = assignedCe.ceActivityCompletedDate
            let yearComponent: Int = calendar.component(.year, from: completionDate)
            let monthComponent: Int = calendar.component(.month, from: completionDate)
            let dayComponent: Int = calendar.component(.day, from: completionDate)
            
            baseFileName = "Certificate_\(dayComponent)-\(monthComponent)-\(yearComponent)"
        } else {
            let saveTime: Date = Date.now
            let yearComponent: Int = calendar.component(.year, from: saveTime)
            let monthComponent: Int = calendar.component(.month, from: saveTime)
            let dayComponent: Int = calendar.component(.day, from: saveTime)
            
            baseFileName = "Certificate_saved at_\(dayComponent)-\(monthComponent)-\(yearComponent)"
        }//: IF ELSE
        return fileSystem.sanitizeFileName(baseFileName) + ".\(fileExtension)"
    }//: createCertificateFileName
    
    /// Method that does the work of finding the CeActivity stored in CoreData that the user is saving
    /// a CE certificate object for.
    /// - Parameter metaData: CertificateMetaData object, which has the ID for the CeActivity
    /// - Returns: the CeActivity entity matching the assignedObjectID property in CertificateMetaData
    func matchCertificateWithActivity(using metaData: CertificateMetadata) -> CeActivity? {
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
    
    // MARK: - INIT
    
    init(
        dataController: DataController,
        certBrain: CertificateBrain,
        coordManager: CertCoordinatorManager
    ) {
        self.dataController = dataController
        self.certBrain = certBrain
        self.coordManager = coordManager
    }//: INIT
    
}//: CLASS
