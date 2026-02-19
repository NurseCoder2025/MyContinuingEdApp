//
//  CertificateController.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/10/26.
//

import CoreData
import Foundation
import UIKit


final class CertificateBrain: ObservableObject {
    // MARK: - PROPERTIES
   
    @Published var allCoordinators: Set<CertificateCoordinator> = []
    let fileExtension: String = "cert"
    
    // Error handling properties
    @Published var errorMessage: String = ""
    @Published var handlingError: FileIOError = .noError
    
    var dataController: DataController
    private let fileSystem = FileManager()
    
    let certQuery = NSMetadataQuery()
   
    
    // MARK: - COMPUTED PROPERTIES
    
    var currentStorageChoice: StorageToUse {
        dataController.certificateAudioStorage
    }//: currentStorageChoice
    
    // MARK: Top-Level Folder URL
    /// Computed property in CertificateBrain that sets the URL for the top-level directory into which all
    /// CE certificates are to be saved to in iCloud: "Documents/Certificates".  Nil is returned if the url
    /// for the app's directory in the user's iCloud drive account cannot be made.
    var cloudCertsFolderURL: URL? {
        if let existingURL = dataController.userCloudDriveURL {
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
        let coordinator: CertificateCoordinator
        coordinator = CertificateCoordinator(file: location, metaData: metaData)
        return coordinator
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
        var newCoordinator = createCertificateCoordinator(with: certMetaData, fileAt: localURL)
        
        // 4. Create a new CertificateDocument instance with the url, meta data, and data
        let newCertDoc = CertificateDocument(certURL: localURL, metaData: certMetaData, withData: data)
        
        // 5. Save CertificateDocument to disk locally
        newCertDoc.save(to: localURL, for: .forCreating)
        
        // 6. If the user wishes to save media files to iCloud and iCloud is available, move
        // file to iCloud/UserUbqiquityURL/Documents/Certificates
        switch currentStorageChoice {
        case .local:
            allCoordinators.insert(newCoordinator)
            return
        case .cloud:
            if let cloudFolder = cloudCertsFolderURL {
                let iCloudURL = createDocURL(with: certMetaData, for: .cloud)
                let cloudMoveTask: Task<Void, Never> = Task {
                    try? fileSystem.moveItem(at: localURL, to: iCloudURL)
                }
                
                newCoordinator.fileURL = iCloudURL
                allCoordinators.insert(newCoordinator)
            } else {
                allCoordinators.insert(newCoordinator)
                handlingError = .saveLocationUnavailable
                errorMessage = "Attempted to save the certificate to iCloud but was unable to do so. Please check your iCloud and iCloud drive settings and try again. The certificate was saved locally to the device."
            }
        }//: SWITCH
    }//: addNewCeCertificate()
   
   
    // MARK: - Deleting Certificates
    
   
    
    // MARK: - LOADING CERTIFICATES
    
    
   
    
    
    // MARK: - Moving local to iCloud
    
  
    
    
    // MARK: - Updating Certficate Coordinators
    
   
    
    
    
    // MARK: - OBSERVER METHODS
    
    func certificatesChanged(_ notification: Notification) {
        objectWillChange.send()
    }//: certificatesChanged
    
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
            forName: .NSMetadataQueryDidUpdate,
            object: certQuery,
            queue: .main,
            using: certificatesChanged
        )//: OBSERVER
        
        NotificationCenter.default.addObserver(
            forName: .NSMetadataQueryDidFinishGathering,
            object: certQuery,
            queue: .main,
            using: certificatesChanged
        )//: OBSERVER
        
    }//: INIT
}//: CertificateController
