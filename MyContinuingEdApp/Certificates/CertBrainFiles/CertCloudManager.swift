//
//  CertCloudManager.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/31/26.
//

import CloudKit
import CoreData
import Foundation
import UIKit

final class CertCloudManager: ObservableObject {
    // MARK: - PROPERTIES
    
    let fileExtension: String = .certFileExtension
    let certificateStoragePrefChange = Notification.Name(.cloudStoragePreferenceChanged)
    
    private let certBrain: CertificateBrain
    private let dataController: DataController
    private let coordManager: CertCoordinatorManager
    private let mover: CertificateMover
    private let utility: CertUtility
    let certQuery = NSMetadataQuery()
    
    private let fileSystem = FileManager()
    
    // MARK: - iCloud SEARCH
    
    /// Method that initalizes the process for searching for all CE certificate objects saved in the user's iCloud container for the app.
    ///
    /// This method does the following:
    ///     - Sets the properties for the search using the NSMetadataQuery class instance
    ///     - Creates the two required observers for the search
    ///     - Starts the query
    ///
    /// Upon search completion, the observer receiving the query completion notification will then run the private cloudCertSearchFinished
    /// method, which will update the allCloudCoordinators property with whatever objects it was able to find.
    func startICloudCertSearch() {
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
    
    // MARK: - Query Observer
    
    /// Observer method that simply logs whenever a batch of query results is completed and the notification is sent by
    /// the system.
    /// - Parameter notification: Notification from observer (in this case, NSMetadataQueryDidUpdate)
    private func certificatesChanged(_ notification: Notification) {
        NSLog(">>> Certificates list updated")
    }//: certificatesChanged

    private func cloudCertSearchFinished(_ notification: Notification) {
        Task.detached {
            await self.cloudCertSearchEndedHandler()
        }//: TASK
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
                let itemMeta = await utility.extractMetadataFromDoc(at: certURL)
                if itemMeta.isExampleOnly == false {
                    let coordinator = coordManager.createCertificateCoordinator(with: itemMeta, fileAt: certURL)
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
                certBrain.handlingError = .syncError
                certBrain.errorMessage = "It appears that not every certificate file saved in iCloud was readable. Please manually inspect the Certificates folder and remove any non-certificate (.cert) files. All readable ones will be synced."
            }//: MAIN ACTOR
            let totalCount = cloudCoordinators.count + problemFiles.count
            NSLog(">>>Out of the \(totalCount) files found on iCloud, \(problemFiles.count) could not be read due to metadata being unreadable.")
        }//: IF (isNotEmpty)
        
        coordManager.cloudCoordinators = cloudCoordinators
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
        
        await coordManager.syncCoordinatorList()
        
    }//: cloudCertSearchEndedHandler
    
    // MARK: - iCLOUD STATUS
    
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
    
    // MARK: - Storage Preference
    
    /// Private selector method called whenever the user changes the preference for saving certificate data in iCloud.
    /// - Parameter notification: Notifcation object with the name contained in the String
    /// constant .cloudStoragePreferenceChanged
    ///
    /// This method creates a new observer that listens for a notification with the name from the String constant
    /// .certCoordinatorListSyncCompleted, which is sent by the syncCertFilesStorage method when it is done
    @objc private func updateAfterCertStoragePrefChange(_ notification: Notification) {
        
        // Removing any potentially pre-existing observers
        let notificationToRemove = Notification.Name(.certCoordinatorListSyncCompleted)
        NotificationCenter.default.removeObserver(self, name: notificationToRemove, object: nil)
        
        // Creating observer that will recieve notification when the coordinator list JSON
        // file has been updated and saved, following the completion of the startICloudCertSearch
        // and cloudCertSearchFinished methods.  Since it is unknown how long it will take
        // to query iCloud for saved certificate objects, using an observer to ensure that
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
    
    /// Private selector method that calls and runs the moveCertFiles method on background threads so not as to
    /// cause hangs in the UI as the process can take time and work.
    /// - Parameter notification: Notification with the name of the String constant .certCoordinatorListSyncCompleted
    @objc private func handleMovingCertFilesUpon(_ notification: Notification) {
        Task.detached { [weak self] in
            await self?.mover.moveAllCertFiles()
        }//: TASK
    }//: handleMovingCertFilesUpon(notification)
    
    // MARK: - INIT
    init(
        certBrain: CertificateBrain,
        dataController: DataController,
        coordManager: CertCoordinatorManager,
        mover: CertificateMover,
        utility: CertUtility
    ) {
        self.certBrain = certBrain
        self.dataController = dataController
        self.coordManager = coordManager
        self.mover = mover
        self.utility = utility
        
        
        // MARK: Observers
        // **DO NOT Remove These Observers Until Deinit!!**
        
        // Observer for any Apple Account change (logging in/out)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleICloudStatusChange(_:)),
            name: .NSUbiquityIdentityDidChange,
            object: nil
        )//: addObserver
        
        // Custom observer for when the cloud storage preference setting is
        // changed by the user.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateAfterCertStoragePrefChange(_:)),
            name: certificateStoragePrefChange,
            object: nil
        )//: addObserver
        
    }//: INIT
    
    // MARK: - DEINIT
    deinit {
        NotificationCenter.default.removeObserver(self)
    }//: DEINIT
    
}//: CLASS
