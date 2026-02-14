//
//  CertificateController.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/10/26.
//

import CoreData
import Foundation


final class CertificateController: ObservableObject {
    // MARK: - PROPERTIES
    @Published private var allCertificates = Set<CECertificate>()
    @Published var errorMessage: String = ""
    @Published var handlingError: FileIOError = .noError
    
    private let masterCertList: URL = URL.applicationSupportDirectory.appending(path: "masterCertificateList.json", directoryHint: .notDirectory)
    var dataController: DataController
   
    
    
    // MARK: - COMPUTED PROPERTIES
    
    var currentStorageChoice: StorageToUse {
        dataController.certificateAudioStorage
    }//: currentStorageChoice
    
    // MARK: Top-Level Folder URLs
    var localCertsFolderURL: URL {
        return dataController.localStorage.appending(path: "Certificates", directoryHint: .isDirectory)
    }//: localCertsURL
    
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
    
     // MARK: - Saving Certificates
    
    /// Private method for getting the corresponding CeActivity for a particular CECertificate object.
    /// - Parameter cert: CECertificate object containing the UUID for the CeActivity it is being assigned to
    /// - Returns: Corresponding CeActivity if found or nil if not
    ///
    /// Method is used primarily for saving new ce certificates.  The process is thus:
    ///     - CECertificate object is created whenever a user selects an image or PDF for saving to a CeActivity
    ///     - The CECertificate is created with an assignedCeId value that corresponds to the current activity being edited in the
    ///     UI, along with other properties
    ///
    /// This method is used to ensure that all certificate files being saved are matched to a specific CeActivity object.  If either no matching
    /// objects can be found (either due to an incorrect/missing assignedCeId property) or multiple objects are returned, then this method
    /// will return nil.
    private func getMatchingCEActivity(for cert: CECertificate) -> CeActivity? {
        let context = dataController.container.viewContext
        let activityFetch = CeActivity.fetchRequest()
        activityFetch.sortDescriptors = [NSSortDescriptor(key: "activityTitle", ascending: true)]
        activityFetch.predicate = NSPredicate(format: "activityID == %@", cert.assignedObjectId as CVarArg)
        let matchingCE: [CeActivity] = (try? context.fetch(activityFetch)) ?? []
        guard matchingCE.count == 1 else { return nil }
        
        return matchingCE[0]
    }//: matchCertWithCE
    
    /// Private method that saves a given image or PDF file to local or iCloud-based storage for a specific CeActivity object.
    /// - Parameters:
    ///   - cert: CECertificate object (needs to have an assignedCeId, fileExtension, and whereSaved values)
    ///   - certData: Data representing either image or PDF data that is the certificate being saved
    ///
    ///   Once called, the method first ensures there is a corresponding CeActivity for the CECertificate object and saves the updated
    ///   allCertificates property to disk (applicationSupport).  If any errors are thrown while trying to write the data to the right URL, then
    ///   the class's handlingError property will be set to writeFailed with a custom message assigned to errorMessage.
    ///
    ///   - Note: The newly created CECertificate object is first inserted into the allCertificates set by the addCertificate method, which
    ///   calls this one.
    private func save(cert: CECertificate, certData: Data) async  {
        if let matchingCe = getMatchingCEActivity(for: cert), let data = try? JSONEncoder().encode(allCertificates) {
            try? data.write(to: masterCertList, options: [.atomic, .completeFileProtection])
            
            switch currentStorageChoice {
            case .local:
                do {
                    let localSaveURL = localCertsFolderURL.appending(path: cert.fileName, directoryHint: .notDirectory)
                    try certData.write(to: localSaveURL)
                } catch {
                    errorMessage = "Failed to save the certificate: \(error.localizedDescription)"
                    handlingError = .writeFailed
                }
            case .cloud:
                if let iCloudURL = cloudCertsFolderURL {
                    let cloudSaveURL = iCloudURL.appending(path: cert.fileName, directoryHint: .notDirectory)
                    do {
                        try certData.write(to: cloudSaveURL)
                    } catch {
                        errorMessage = "Failed to save the certificate: \(error.localizedDescription)"
                        handlingError = .writeFailed
                    }
                } else {
                    handlingError = .saveLocationUnavailable
                    errorMessage = "Tried to save certificate to your iCloud drive, but could not access it. Check your iCloud settings and network connection and try again."
                }//: IF ELSE
            }//: SWITCH
        }//: IF LET
    }//: save()
    
    
    /// Method for saving a new CE certificate to either local or iCloud storage.
    /// - Parameters:
    ///   - cert: CECertificate object created when the user selects and saves an image or PDF file
    ///   - certData: the actual binary data for the image or PDF file
    ///
    ///- Note: This method inserts the new CECertificate object into the allCertificates set, but the underlying file which saves all of it
    ///is not updated until the private "save" method is called within this method.
    func addCertificate(_ cert: CECertificate, certData: Data) {
        allCertificates.insert(cert)
        let saveTask: Task<Void, Never> = Task {
            await save(cert: cert, certData: certData)
        }//: TASK
    }//: addCertificate
    
   
    // MARK: - Deleting Certificates
    
    /// Private method used when deleting CE certificates for a specific activity to retrieve the corresponding CECertificate object so that
    /// the correct URL can be computed for deleting the right file.
    /// - Parameter activity: CeActivity for which a certificate has been assigned, and the user wishes to delete
    /// - Returns: CECertificate object corresponding to the CeActivity (based on the assignedCeId property), or nil if not found
    private func retrieveActivityCertificate(_ activity: CeActivity) -> CECertificate? {
        if let matchingID = activity.activityID {
            return allCertificates.first { cert in
                cert.assignedObjectId == matchingID
            }
        } else {
            return nil
        }
    }//: retrieveActivityCertificate
    
    /// Private method that deletes only the actual CE certificate data (image or PDF) that is associated with a specific CeActivity
    /// object. If the data can be deleted succesfully, then the CECertificate object will be removed by the calling method.
    /// - Parameter activity: CeActivity object containing the certificate the user wishes to remove
    ///
    /// - Note: This method is async due to the fact it could delete an on-device only file or a cloud based file.
    /// - Important: The URL constructed for removing the certificate depends on the CECertficate's whereSaved property. If that
    /// property doesn't correctly reflect where the file was saved to then an error will be thrown by the removeItem method.
    ///
    /// If any error is thrown by the removeItem method, then the CertificateController's handlingError property will be set to unableToDelete
    /// and a custom error message will be assigned to the errorMessage string.
    private func deleteCertificate(for activity: CeActivity) async {
        if let certToDelete = retrieveActivityCertificate(activity) {
            switch certToDelete.whereSaved {
            case .local:
                let localSaveURL = localCertsFolderURL.appending(path: certToDelete.fileName, directoryHint: .notDirectory)
                
                do {
                    try dataController.fileSystem.removeItem(at: localSaveURL)
                } catch {
                    handlingError = .unableToDelete
                    errorMessage = "Unable to delete certificate. Please check your device's Files app and ensure the certificate is located within the app's 'Certificates' folder and try again."
                }
            case .cloud:
                if let cloudSaveURL = cloudCertsFolderURL {
                    let cloudURL = cloudSaveURL.appending(path: certToDelete.fileName, directoryHint: .notDirectory)
                    do {
                        try dataController.fileSystem.removeItem(at: cloudURL)
                    } catch {
                        handlingError = .unableToDelete
                        errorMessage = "Unable to delete certificate. Use the Files app to ensure that the certificate is in the 'Certficates' folder within CeCache's iCloud Drive folder and try again."
                    }
                }//:IF LET
            }//: SWITCH
        }//: IF LET
    }//: deleteCertificate
    
    
    /// Method for deleting a CE certificate from a given CE activity object.
    /// - Parameter activity: CeActivity containing a certificate for which the user wishes to remove
    ///
    /// This method first tries to delete the certificate data, and if that succeeds, then the corresponding CECertificate object will be
    /// deleted from the allCertificates set.
    func removeCertficateFromCE(_ activity: CeActivity) {
        if let certToDelete = retrieveActivityCertificate(activity) {
            let deleteTask: Task <Void, Never> = Task {
                // The following method deletes ONLY the actual certificate data at the URL
                // created by the certificate's fileName property and local or cloud folder
                // computed URL property (from within this class)
                await deleteCertificate(for: activity)
                
                // ONLY if there were no errors thrown in the deleteCertificate method
                // proceed to remove the CECertificate object from the set
                if handlingError != .unableToDelete {
                    allCertificates.remove(certToDelete)
                    if let updatedCerts = try? JSONEncoder().encode(allCertificates) {
                        try? updatedCerts.write(to: masterCertList)
                    }//: IF LET
                }//: IF
            }//: TASK
        }//:IF LET
    }//: removeCErtificateFromCE
    
    
    // MARK: - Moving local to iCloud
    
    /// Method for moving locally stored CE certificates to iCloud storage.
    /// - Parameter ce: CeActivity object for which the certificate is to be moved off device to iCloud
    ///
    /// Conditions for moving:
    ///     - There must be a matching CECertificate object (as found by the retrieveActivityCertificate method)
    ///     - The matching CECertficate object must have the .local enum value for the whereSaved property
    ///     - The cloudCertsFolderURL class property (CertificateController) must not be nil
    ///
    /// If any of those conditions are not met, or an error is thrown by the FileManager's moveItem method, then a custom error message
    /// and handlingError property value will be set for the CertificateController class.
    func moveCertToIcloud(for ce: CeActivity) async {
        if let matchingCert = retrieveActivityCertificate(ce), matchingCert.whereSaved == .local, let cloudSaveURL = cloudCertsFolderURL {
            let currentLocalURL = localCertsFolderURL.appending(path: matchingCert.fileName, directoryHint: .notDirectory)
            let newCloudURL = cloudSaveURL.appending(path: matchingCert.fileName, directoryHint: .notDirectory)
            
            do {
                try dataController.fileSystem.moveItem(at: currentLocalURL, to: newCloudURL)
            } catch {
                handlingError = .unableToMove
                errorMessage = "Unable to move certificate to iCloud. Please ensure that you are logged in and have iCloud Drive sync turned on, then try again."
            }
        } else if let matchingCert = retrieveActivityCertificate(ce), matchingCert.whereSaved == .cloud {
            handlingError = .operationUnneeded
            errorMessage = "The certificate appears to be already saved to your iCloud Drive."
        } else if cloudCertsFolderURL == nil {
            handlingError = .saveLocationUnavailable
            errorMessage = "Unable to locate your iCloud Drive folder. Please ensure that you are logged in and have iCloud Drive sync turned on, then try again."
        } else if retrieveActivityCertificate(ce) == nil {
            handlingError = .fileMissing
            errorMessage = "Unable to locate where this file is saved. Use the Files app to find it and then manually move it to the 'Certificates' sub-folder on this device for the app."
        }
    }//: moveCertToIcloud
    
    
    // MARK: - Updating Master LIST
    
    /// Private method used for updating the masterCertificateList.json file which is stored in the local applicationSupport
    /// directory on a local device.
    ///
    ///
    ///- Important: This method should only be called when initializing the CerfiicateController class.  After that, any additions
    ///or deletions made by the user will be handled by the respective individual methods in the class. It is also critical that the
    ///file names for any saved certificates match the format as specified by the fileName computed property in the model object.
    ///
    /// This method checks local storage for any new CE certificate binary files that have been added but are not found in
    /// the master list.  It then creates new CECertificate model objects and adds those to the allCertificates set. Then it checks
    /// for any binary data in the user's iCloud folder (if available) and does the same thing.
    private func updateCertificateData() async {
        // Check local storage for any certificates, and add any new CECertificate
        // objects as needed
        if let localCerts = try? dataController.fileSystem.contentsOfDirectory(at: localCertsFolderURL, includingPropertiesForKeys: nil, options: []), localCerts.isNotEmpty {
            for cert in localCerts {
                if !allCertificates.contains(where: { $0.fileName == cert.lastPathComponent }) {
                    let certToAdd = createNewCertficateFromURL(cert, saved: .local)
                    if let newCert = certToAdd {
                        allCertificates.insert(newCert)
                    }
                }//: IF
            }//: LOOP
        }//: IF LET
        
        // Check iCloud storage for any certificates, and add any new CECertificate
        // objects as needed
        if let existingICloudFolder = cloudCertsFolderURL, let cloudCerts = try? dataController.fileSystem.contentsOfDirectory(at: existingICloudFolder, includingPropertiesForKeys: nil, options: []), cloudCerts.isNotEmpty {
            for cloudCert in cloudCerts {
                if !allCertificates.contains(where: {$0.fileName == cloudCert.lastPathComponent}) {
                    let newCloudCert = createNewCertficateFromURL(cloudCert, saved: .cloud )
                    if let createdCloudCert = newCloudCert {
                        allCertificates.insert(createdCloudCert)
                    }//: IF LET
                }//: IF
            }//: LOOP
        }//: IF LET
        
        // Save changes to master list
        let updatedList = try? JSONEncoder().encode(allCertificates)
        if let dataToSave = updatedList {
            try? dataToSave.write(to: masterCertList)
        }//: IF LET
    }//: updateCertificateData
    
    
    /// Private submethod that creates a new CECertificate model object from a URL.
    /// - Parameters:
    ///     -  url: URL representing the location of a saved CE certificate data file
    ///     - saved: SaveLocation enum identifying whether the data is on-device only or in iCloud
    /// - Returns: CECertificate object based on the last part of the url or nil if unsuccessful
    ///
    /// The success of this method depends on the fileName computed property in CECertficate.  This file name contains
    /// 3 parts which can then be extracted and used to create a new CECertificate object as needed.  Those parts include
    /// the uuid string for the object to which the certificate is assigned to, the date on which it was earned (formatted as a string),
    /// and the file extension string.
    private func createNewCertficateFromURL(_ url: URL, saved: SaveLocation) -> CECertificate? {
        if let uuidToExtract = url.lastPathComponent.split(separator: "_").first,
           let dateExtracted = url.lastPathComponent.split(separator: "_").dropFirst().first,
           let fileType = url.lastPathComponent.split(separator: ".").last,
           let convertedUUID = UUID(uuidString: String(uuidToExtract)),
           let convertedDate = try? Date(dateExtracted, strategy: .dateTime) {
            
            let newCert = CECertificate(
                type: fileType == "pdf" ? CertType.pdf : CertType.image,
                assignedObjectId: convertedUUID,
                earnedDate: convertedDate,
                fileExtension: String(fileType),
                whereSaved: saved
            )
            
            return newCert
        } else {
            return nil
        }
    }//: createNewCertificateFromURL()

    
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
      
        if let listData = try? Data(contentsOf: masterCertList) {
            allCertificates = (try? JSONDecoder().decode(Set<CECertificate>.self, from: listData)) ?? []
        }
        
        let syncTask: Task<Void, Never> = Task {
            await updateCertificateData()
        }//: TASK
        
    }//: INIT
}//: CertificateController
