//
//  CertificateBrain_SavingCerts.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/31/26.
//

import CloudKit
import CoreData
import Foundation
import UIKit

final class CertificateWriter {
    // MARK: - PROPERTIES
    private var newCertMetaData: CertificateMetadata?
    private var newCertLocalUrl: URL?
    private var newCertCoordinator: CertificateCoordinator?
    private var newCertDocument: CertificateDocument?
    
    let fileExtension: String = .certFileExtension
    
    private let dataController: DataController
    private let certBrain: CertificateBrain
    private let coordManager: CertCoordinatorManager
    private let utility: CertUtility
    
    private let fileSystem = FileManager()
    
    
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
       // 1. Create metadata using activity
       newCertMetaData = createCertificateMetadata(forCE: activity, fileType: dataType)
       
       // 2. Create the local url for saving
       if let certMeta = newCertMetaData {
           newCertLocalUrl = utility.createDocURL(with: certMeta, for: .local)
    
       // 3. Create the coordinator object with url and metadata
           if coordManager.currentCoordinators.isEmpty { await coordManager.decodeCoordinatorList() }
           let localFile = newCertLocalUrl ?? URL.locallySavedCertificateFile
           newCertCoordinator = coordManager.createCertificateCoordinator(with: certMeta, fileAt: localFile)
   
       // 4. Create a new CertificateDocument instance with the url, meta data, and data
       newCertDocument = await CertificateDocument(
           certURL: localFile,
           metaData: certMeta,
           withData: data
       )//: newCertDocument
     
       // Initial save observers
       let initialSaveDoneNotification = Notification.Name(String.certLocalSaveCompleted)
       NotificationCenter.default.removeObserver(initialSaveDoneNotification)
       NotificationCenter.default.addObserver(
           self,
           selector: #selector(handleInitialLocalSaveCompleted(_:)),
           name: initialSaveDoneNotification,
           object: nil
       )//: addObserver
       
       // 5. Save CertificateDocument to disk locally
       if let newCertDoc = newCertDocument, await newCertDoc.save(to: localFile, for: .forCreating) {
               // Adding a small delay before updating the CeActivity
               // CoreData property to ensure that the document is saved
               Task{@MainActor in
                   let sleepTime = 0.01
                   try await Task.sleep(for: .seconds(sleepTime))
               }//: TASK
               
               guard fileSystem.fileExists(atPath: localFile.path) else {
                   NSLog(">>> Newly created certificate document doesn't exist affter save.")
                   throw FileIOError.writeFailed
               }//: GUARD
               newCertDocument = nil
           
               activity.hasCompletionCertificate = true
               // The notification will trigger the app to move the file to iCloud, if available, and
               // if the user elects for iCloud storage for CE certificates
               NotificationCenter.default.post(name: initialSaveDoneNotification, object: nil)
           } else {
               NSLog(">>>Error saving CertificateDocument to the local url: \(localFile)")
               NSLog(">>>Exiting the addNewCeCertificate(for) method early without attempting to save to iCloud.")
               certBrain.handlingError = .writeFailed
               certBrain.errorMessage = "Failed to save the CE certificate to your device. Choose another file type and try again."
               throw certBrain.handlingError
           }//: IF ELSE
  
       }//: IF LET (certMeta)
      
       
   }//: addNewCeCertificate()
   
    // MARK: - Finalizing Save
   
   @objc private func handleInitialLocalSaveCompleted(_ notification: Notification) {
       if let newCertDoc = newCertDocument, let certMeta = newCertMetaData, let coordinator = newCertCoordinator {
           Task{
               // 6. If the user wishes to save media files to iCloud and iCloud is available, move
               // file to iCloud/UserUbqiquityURL/Documents/Certificates
               await transferNewlyCreatedCertToICloud(
                   certificate: newCertDoc,
                   meta: certMeta,
                   coordinator: coordinator,
                   from: newCertLocalUrl ?? URL.locallySavedCertificateFile
               )//: transferNewlyCreatedCertToICloud
           }//: TASK
       }//: IF LET
   }//: handleInitialLocalSaveCompleted
   
   private func transferNewlyCreatedCertToICloud(
       certificate: CertificateDocument,
       meta metadata: CertificateMetadata,
       coordinator: CertificateCoordinator,
       from localUrl: URL
   ) async {
       guard dataController.prefersCertificatesInICloud,
             certBrain.storageAvailability == .cloud,
             let _ = certBrain.cloudCertsFolderURL else {
               if dataController.prefersCertificatesInICloud {
                   await MainActor.run {
                       // In this situation, the user wants to save certificates
                       // to iCloud but can't do so for one of several possible
                       // reasons, including a completely full drive, iCloud
                       // Drive turned off, etc.
                       certBrain.handlingError = .saveLocationUnavailable
                       certBrain.errorMessage = "The app is currently set to save CE certificates to iCloud, but, unfortunately, iCloud cannot be used at this time. Please check your iCloud/iCloud drive settings as well as how much available free space is on the drive for your account. The certificate was saved locally to the device."
                   }//: MAIN ACTOR
                   await coordManager.coordinatorAccess.insertCoordinator(coordinator)
                   await coordManager.encodeCoordinatorList()
               } else {
                   // In this situation, the user has indicated that CE certificates are to be saved to
                   // the local device only via the control in Settings
                   await coordManager.coordinatorAccess.insertCoordinator(coordinator)
                   await coordManager.encodeCoordinatorList()
               }//: IF - ELSE
               return
           }//: GUARD
       
            let iCloudURL = utility.createDocURL(with: metadata, for: .cloud)
               // Moving the file to iCloud, and if successful, updating the coordinator object
               // before inserting it into the list and writing the updated list to disk.
           if await certificate.documentState == .closed {
               do {
                   try await moveNewlyCreatedCertToICloud(
                       copying: metadata,
                       originalCoordinator: coordinator,
                       localUrl: localUrl,
                       iCloudUrl: iCloudURL
                   )
               } catch {
                   await MainActor.run {
                       certBrain.errorMessage = "Unable to save the certificate to iCloud due to a file system error while moving the file from the local device to iCloud. The certificate remains saved on the local device."
                   }//: MAIN ACTOR
               }//: DO-CATCH
           } else {
               // Make a second attempt to close the certificate document and move it to iCloud.
               if await certificate.close() {
                   do {
                       try await moveNewlyCreatedCertToICloud(
                           copying: metadata,
                           originalCoordinator: coordinator,
                           localUrl: localUrl,
                           iCloudUrl: iCloudURL
                       )
                   } catch {
                       await MainActor.run {
                           certBrain.errorMessage = "Unable to save the certificate to iCloud due to a file system error while moving the file from the local device to iCloud. The certificate remains saved on the local device."
                       }//: MAIN ACTOR
                   }//: DO-CATCH
               } else {
                   let currentDocState = await certificate.documentState
                   NSLog(">>> Made a second attempt to move a certificate to iCloud but could not close the CertificateDocument file in order to do so.")
                   NSLog(">>> Document status: \(currentDocState.rawValue)")
                   certBrain.errorMessage = "Unable to save certificate to iCloud due to technical issue with the file the certificate is saved in. It will remain saved on the local device."
               }//: IF ELSE ( .close() )
           }//: IF ELSE (documentState == .closed)
   }//: transferNewlyCreatedCertToICloud

   /// Private CertificateBrain method used for moving a newly created CertificateDocument object to iCloud if
   /// available and the user elects iCloud storage for saving CE certificates.
   /// - Parameters:
   ///   - metadata: CertificateMetadata object containing the local file URL within the fileVersion property
   ///   - originalCoordinator: CertificateCoordinator object first created for the local URL
   ///   - localUrl: URL where the object was saved to on the local device
   ///   - iCloudUrl: URL to move the object to (in iCloud)
   ///
   ///  - Note: This method is only for use with the addNewCeCertificate method as there are two additional methods
   ///  for moving  previously created certificates (moveCertToCloud and moveSavedCertificate).  Use one of those if handling
   ///  an existing certificate.
   ///
   ///  This method only throws an error if the setUbiquitous FiileManager method throws an error.  If not, then the method will
   ///  create a new metadata object using the copying argument and then create a new coordinator object with the new
   ///  metadata.  Then the coordinator will be officially added to the list.  The final part of this method calls the
   ///  updateCertDocMetaUponMove where the CertificateDocument (now saved in iCloud) is opened and the file URL property
   ///  within the metadata's fileVersion property is updated.
   private func moveNewlyCreatedCertToICloud(
       copying metadata: CertificateMetadata,
       originalCoordinator: CertificateCoordinator,
       localUrl: URL,
       iCloudUrl: URL
   ) async throws {
       var copiedMeta = metadata
       do {
           try self.fileSystem.setUbiquitous(true, itemAt: localUrl, destinationURL: iCloudUrl)
       } catch {
           NSLog(">>> moveNewlyCreatedCertToICloud threw an error when calling the setUbiquitous method for the local and iCloud URLs.")
           NSLog(">>> Local url: \(localUrl.absoluteString)")
           NSLog(">>> iCloud url: \(iCloudUrl.absoluteString)")
           // Updating published properties on the MainActor
           await MainActor.run {
               certBrain.handlingError = .saveLocationUnavailable
               certBrain.errorMessage = "Attempted to save the certificate to iCloud but was unable to do so. Please check your iCloud/iCloud drive settings as well as how much available free space is on the drive for your account. The certificate was saved locally to the device."
           }//: MAIN ACTOR
           await coordManager.coordinatorAccess.insertCoordinator(originalCoordinator)
           await coordManager.encodeCoordinatorList()
           throw certBrain.handlingError
       }//: DO-CATCH
       
       // Updating the url saved in the metadata and using it to create a new coordinator
       // that will be assigned to the coordinator list
       copiedMeta.fileVersion.fileLocation = iCloudUrl
       let newCoordinator = coordManager.createCertificateCoordinator(with: copiedMeta, fileAt: iCloudUrl)
       
       await coordManager.coordinatorAccess.insertCoordinator(newCoordinator)
       await coordManager.encodeCoordinatorList()
       
       // If the file was moved successfully and no errors were thrown, then update the
       // metadata for the file, then post the notification that the move is complete.
       do {
           try await updateCertDocMetaUponMove(to: .cloud, at: iCloudUrl)
       } catch {
           NSLog(">>>Error trying to update the metadata for a CertificateDocument that was successfully moved to iCloud. The whereSaved property is still set to .local")
           NSLog(">>> The url for the moved certificate is: \(iCloudUrl.absoluteString)")
       }//: DO-CATCH
   }//: moveNewlyCreatedCertToICloud()
   
    // MARK: - SAVE HELPERS
   
   private func updateCertDocMetaUponMove(
       to newLocation: SaveLocation,
       at newLocURL: URL
   ) async throws {
       let movedCertDoc = await CertificateDocument(certURL: newLocURL)
       if await movedCertDoc.docOkToOpen(), await movedCertDoc.open() {
           await MainActor.run {
               movedCertDoc.certMetaData.fileVersion.fileLocation = newLocURL
           }//: MAIN ACTOR
           await movedCertDoc.close()
       } else {
           NSLog(">>>Error opening the CertificateDocument at the new URL: \(newLocURL.absoluteString)")
           await MainActor.run {
               certBrain.handlingError = .loadingError
           }//: MAIN ACTOR
           throw certBrain.handlingError
       }//: IF ELSE (open)
   }//: updateCertDocMetaUponMove(to, at)

   /// Method for creating CertificateMetadata objects based on the CeActivity object for which the certificate was earned.
   /// - Parameters:
   ///   - activity: CeActivity object marked as completed by the user for which they want to add a certificate
   ///   - fileType: MediaType enum indicating whether the certificate data the metadata is for is an image or PDF
   /// - Returns: CertificateMetadata object with properties set
   ///
   /// - Important: The method creates a temporary URL using the temporaryDirectory and createCertificateName(for)
   /// methods. This is so a MediaFileVersion object can be created (which requires a fileURL argument).  Need to update this
   /// when finally saving the object!
   /// - Note: If the CeActivity argument happens to not have an activityID property set, then this method will create
   /// a new UUID value, assign it to the object, and then call the DataController's save method to save the context prior
   /// to creating and returning the new CertificateMetadata object.
   private func createCertificateMetadata(
       forCE activity: CeActivity,
       fileType: MediaType
   ) -> CertificateMetadata {
       let fileName = utility.createCertificateFileName(for: activity)
       let tempURL = URL.temporaryDirectory.appending(path: fileName, directoryHint: .notDirectory)
       if let assignedID = activity.activityID {
           let currentVersion = MediaFileVersion(fileAt: tempURL, version: 1.0)
           return CertificateMetadata(forCeId: assignedID, as: fileType, fileVersion: currentVersion)
       } else {
           let newID = UUID()
           activity.activityID = newID
           dataController.save()
           let currentVersion = MediaFileVersion(fileAt: tempURL, version: 1.0)
           return CertificateMetadata(forCeId: newID, as: fileType, fileVersion: currentVersion)
       }//: IF - ELSE
   }//: CertificateMetadata()
           
    
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
        
        if coordManager.currentCoordinators.isEmpty {
            await coordManager.decodeCoordinatorList()
        }//: IF (isEmpty)
        
        let coordinators = coordManager.currentCoordinators
        guard let certCoordinator = coordinators.first(where: { coordinator in
            coordinator.assignedObjectID == activity.activityID
        }) else {
            await MainActor.run {
                certBrain.handlingError = .unableToDelete
                certBrain.errorMessage = "Unable to delete the certificate as the app was unable to locate where the data was saved. Try using the Files app or Finder to manually remove the file."
            }//: MAIN ACTOR
            NSLog(">>>Error while attempting to delete CE certificate due to a missing coordinator for the specified activity.  Activity: \(activity.ceTitle)")
            throw certBrain.handlingError
        }//: GUARD
        
        do {
            try fileSystem.removeItem(at: certCoordinator.fileURL)
            await coordManager.coordinatorAccess.removeCoordinator(certCoordinator)
            await coordManager.encodeCoordinatorList()
            NotificationCenter.default.post(name: deleteNotification, object: nil)
        } catch {
            await MainActor.run {
                certBrain.handlingError = .unableToDelete
                certBrain.errorMessage = "Unable to delete the certificate at the specified save location. You may need to manually delete it using the Files app or Finder."
            }//: MAIN ACTOR
            NSLog(">>>Error while attempting to delete a CE certificate at \(certCoordinator.fileURL).")
            throw certBrain.handlingError
        }//: DO-CATCH
        
    }//: deleteCertificate(for)
   
    
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
}//: CLASS
