//
//  ContentViewModel.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/27/25.
//

import CoreData
import Foundation
import SwiftUI
import UIKit

extension ContentView {
    
    class ViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
        // MARK: - PROPERTIES
        var dataController: DataController
        
        @Environment(\.spotlightCentral) var spotlightCentral
        
        // Properties for deleting an activity in the activity list
        @Published var activityToDelete: CeActivity?
        @Published var showDeleteWarning: Bool = false
        
        // Renewal related alerts
        @Published var showWarningBoxSection: Bool = false
        @Published var showUpcomingRenewalEndingBox: Bool = false
        @Published var showAddRenewalBox: Bool = false
        @Published var showNoCredentialsWarningBox: Bool = false
        
        // Error-related alerts
        @Published var errorAlertTitle: String = ""
        @Published var errorAlertMessage: String = ""
        @Published var errorAlertDetails: String = ""
        @Published var showErrorAlert: Bool = false
        
        private let syncBrain = SmartSyncBrain.shared
        private let cloudBrain = CloudMediaBrain.shared
        private let settings = AppSettingsCache.shared
        private let masterList = MasterMediaList.shared
        
        // MARK: - CORE DATA
        // These properties are needed in order to select the proper
        // view to show in ContentView, depending on whether the
        // user is brand new to the app or simply hasn't added
        // any CE activities to it.
        private let credsController: NSFetchedResultsController<Credential>
        @Published var allCredentials: [Credential] = []
        
        private let activitiesController: NSFetchedResultsController<CeActivity>
        @Published var allActivities: [CeActivity] = []
        
        private let renewalsController: NSFetchedResultsController<RenewalPeriod>
        @Published var allRenewals: [RenewalPeriod] = []
        
        // MARK: - COMPUTED PROPERTIES
        var computedCEActivityList: [CeActivity] {dataController.activitiesForSelectedFilter()}
        
        /// Computed property used to create headings in the list of CeActivities based on the first letter of each activity so that all activities are grouped
        /// alphabetically
        var alphabeticalCEGroupings: [String : [CeActivity]] {
            Dictionary(grouping: computedCEActivityList) { activity in
                String(activity.ceTitle.prefix(1).uppercased())
            }
        }//: alphabeticalCEGroupings
        
        /// Computed property that returns a string of all letters present in entered CeActivities (keys in the alphabeticalCEGroupings property)
        var sortedKeys: [String] {
            alphabeticalCEGroupings.keys.sorted()
        }
        
        /// Computed property used to determine when to request iOS prompt the user to rate
        /// the app on the AppStore.  Criteria are:  at least 5 tags and 5 CE activities have been
        /// entered (meaning the user has made an in-app purchase and then continued to use the
        /// app for a little bit after purchasing).
        var shouldRequestReview: Bool {
            let tagCount = dataController.count(for: Tag.fetchRequest())
            let activityCount = dataController.count(for: CeActivity.fetchRequest())
            
            // TODO: Replace debug code with return true for release code
            #if DEBUG
            if tagCount >= 5 && activityCount >= 5 {
                dataController.requestReviewCount += 1
                
                if dataController.requestReviewCount.isMultiple(of: 100) {
                    return true
                }//: IF (requestReviewCount)
            }//: IF
            #endif
            
            return false
        }//: shouldRequestReview
        
        var deviceIsOnline: Bool { NetworkManager.shared.isConnected }//: deviceIsOnline
        
        // MARK: - FUNCTIONS
        func delete(activity: CeActivity) {
            activityToDelete = activity
            showDeleteWarning = true
            
            if showDeleteWarning {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
            
        } //: DELETE Method
        
        /// Method for the ContentView view model that ONLY deletes a CeActivity object in CoreData.
        /// - Parameter activity: CeActivity object that is to be deleted
        ///
        /// - Important: If the activity argument happens to have any media files associated with
        /// it (ex. certificate and/or audio reflections), and those are not deleted prior to calling this
        /// method then they will remain stored and coordinator objects will continue to be made for them,
        /// though the assignedObjectId property will be referencing an activity that no longer exists. This will
        /// cause more space to be taken up on the user's device and on iCloud.
        func deleteCeActivityCoreDataObject(_ activity: CeActivity) {
            if #available(iOS 17.0, *) {
                dataController.delete(activity)
            } else {
                spotlightCentral?.removeCeActivityFromDefaultIndex(activity)
                dataController.delete(activity)
            }//: IF #available
        }//: deleteCeActivityCoreDataObject(_ activity)
        
        /// Method for updating the values of allCredentials and allActivities whenever a Credential or
        /// CeActivity object is added/deleted.  This method will then update the view model properties
        /// so that UI depending on those properties will be updated.
        /// - Parameter controller: either the credsController or activitiesController as defined in
        ///  the ContentView's view model properties list.
        func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
            if controller == credsController {
                if let newCreds = controller.fetchedObjects as? [Credential] {
                    allCredentials = newCreds
                }
            } else if controller == activitiesController {
                if let newActivities = controller.fetchedObjects as? [CeActivity] {
                    allActivities = newActivities
                }
            } else if controller == renewalsController {
                if let newRenewals = controller.fetchedObjects as? [RenewalPeriod] {
                    allRenewals = newRenewals
                }
            }//: IF (controller == credsController...)
        } //: controllerDidChangeContent()
        
        func updateRenewalsList() {
            do {
                try renewalsController.performFetch()
                allRenewals = renewalsController.fetchedObjects ?? []
            } catch {
                NSLog(">>>ContentView viewModel | updateRenewalsList()")
                NSLog(">>>The performFetch method for the renewals controller threw an error.")
                NSLog(">>> Error details: \(error.localizedDescription)")
            }//: DO-CATCH
        }//: updateRenewalsList()
        
        func performRenewalPeriodChecks() {
            guard allCredentials.count == 1 else { return } //: GUARD
            updateRenewalsList()
            if allRenewals.isEmpty {
                showAddRenewalBox = true
            } else {
                if let usersCred = allCredentials.first,
                 syncBrain.shouldShowRenewalWarningBox(using: usersCred) {
                    showUpcomingRenewalEndingBox = true
                }//: IF LET (usersCred, shouldShowRenewalWarningBox)
            }//: IF ELSE (allRenewals.isEmpty)
        }//: performRenewalPeriodChecks()
        
        func performCredentialCheck() {
            if allCredentials.isEmpty {
                 showNoCredentialsWarningBox = true
            } else {
                showNoCredentialsWarningBox = false
            }//: IF ELSE (allCredentials.isEmpty)
        }//: performCredentialCheck()
        
        func userAcknowledgesRenewalWarning(for renewal: RenewalPeriod) {
            renewal.hasUserAcknowledgedWarning = true
            dataController.save()
            
            settings.userToAcknowledgeRenewalEnding = false
            settings.encodeCurrentState()
            showUpcomingRenewalEndingBox = false
        }//: userAcknowledgesRenewalWarning(for)
        
        func shouldDisplayWarningBoxSection() -> Bool {
            performCredentialCheck( )
            performRenewalPeriodChecks( )
            
            return showNoCredentialsWarningBox || showUpcomingRenewalEndingBox || showAddRenewalBox
        }//: shouldDisplayWarningBoxSection()
        
        // MARK: DELETING Activities
        func fullyDeleteCeActivity() {
            
        }//: fullyDeleteCeActivity()
        
        // MARK: - DELETION SUB-METHODS
        
        private func deleteCeForFreeUser(activity: CeActivity) async {
            guard userPaidSupportLevel == .free else  { return }//: GUARD
            
            // Delete the locally saved media
            let _ = await deleteLocallySavedCertificate(for: activity)
            // Because deleting a CeActivity cascades down to its corresponding CertificateInfo object
            // then this method only needs to delete the media binary and then the CeActivity object itself
            await deleteActivityCDObject(activity: activity)
        }//: deleteCeForFreeUser()
        
        private func deleteCeForCoreUser(activity: CeActivity) async {
            guard userPaidSupportLevel == .basicUnlock else { return } //: GUARD
            
            // If the CE activity has a certificate associated with it, first delete the certificate
            // (and it's online data in iCloud if uploaded) and then the CE activity
            if let savedCert = activity.certificate {
                let _ = await removeAssociatedCertFrom(activity: activity)
                await deleteActivityCDObject(activity: activity)
            } else {
                // IF NO Certificate saved:
                await deleteActivityCDObject(activity: activity)
            }//: IF LET (savedCert)
        }//: deleteCeForCoreUser(activity)
        
        private func deleteCeForProUser(activity: CeActivity) async {
            guard userPaidSupportLevel == .proSubscription || userPaidSupportLevel == .proLifetime else { return } //: GUARD
            
            if let savedCert = activity.certificate {
                let _ = await removeAssociatedCertFrom(activity: activity)
            }//: IF LET (savedCert)
            
            
            // TODO: Add logic for removing all associated audio reflections
        }//: deleteCeForProUser(activity)
        
        // MARK: SUB CERTIFICATE REMOVAL METHODS
        
        private func removeAssociatedCertFrom(activity: CeActivity)  async -> Bool {
            guard let savedCert = activity.certificate else { return true }//: GUARD
            // First, delete the locally saved certificate and the what was uploaded
            // in iCloud, if it was uploaded (per the certificate's uploadedToICloud property)
            if await deleteLocallySavedCertificate(for: activity) {
                // ONLY if certificate was uploaded, try to remove...
                if await isCertUploadedToICloud(cert: savedCert) {
                    if await isDeviceOnlineForDeleting(cert: savedCert) {
                        if await isICloudAvailableForDeleting(cert: savedCert) {
                            if await removeCertFromICloud(cert: savedCert) {
                                if await removeCertMediaRecord(for: savedCert) {
                                 return true
                                } else {
                                    // Certificate was removed from iCloud, but the metadata in CoreData was NOT
                                    // deleted
                                    return false
                                }//: IF (await removeCertMediaRecord)
                            } else {
                                // Certificate on iCloud NOT deleted due to iCloud removal error
                                return false
                            }//: IF (await removeCertFromICloud)
                        } else {
                            // Certificate on iCloud NOT deleted due to iCloud being unvailable
                            return false
                        }//: IF (await isICloudAvailableForDeleting)
                    } else {
                        // Certificate on iCloud NOT deleted due to device being offline
                        return false
                    }//: IF (await isDeviceOnlineForDeleting)
                } else {
                    // IF Certificate is NOT saved in iCloud but was removed locally
                    // The CertificateInfo object was deleted by the isCertUploadedToICloud method,
                    // So no need to delete it here
                    return true
                }//: IF (await isCertUploadedToICloud)
            } else {
                // The local certificate could not be deleted due to a technical reason
                return false
            }//: IF (await deleteLocallySavedCertificate(for)
        }//: removeAssociatedCertFrom(activity)
        
        private func isCertUploadedToICloud(cert: CertificateInfo) async -> Bool {
            if cert.uploadedToICloud {
                return true
            } else {
                Task{@MainActor in
                    dataController.delete(cert)
                }//: TASK
                return false
            }//: isCertUploadedToICloud
        }//: isCertUploadedToICloud(cert)
        
        private func isDeviceOnlineForDeleting(cert: CertificateInfo) async -> Bool {
            if deviceIsOnline {
                return true
            } else {
                let certRecId = cert.certCloudRecordName
                if certRecId.recordName != String.mediaIdPlaceholder, let savedRec = masterList.getLocalMediaRecord(using: certRecId) {
                    savedRec.shouldDelete = true
                    savedRec.errorMessage = "Certificate could not be deleted from device because it was offline at the time of deletion."
                    masterList.saveList()
                    await MainActor.run {
                        errorAlertTitle = "Device Offline"
                        errorAlertMessage = "The CE certificate for the activity you wish to delete is currently saved in iCloud, but the online file could not be removed becuase the device is currently offline. The app went ahead and deleted the activity but will make another attempt at deleting the record on iCloud once the device is back online."
                        showErrorAlert = true
                    }//: MAIN ACTOR
                    return false
                } else {
                    await MainActor.run {
                        errorAlertTitle = "Device Offline"
                        errorAlertMessage = "The CE certificate for the activity you wish to delete is currently saved in iCloud, but the online file could not be removed becuase the device is currently offline. The app went ahead and deleted the activity but will make another attempt at deleting the record on iCloud once the device is back online. You may need to manually delete the certificate in iCloud using the Finder or Files app on your device if the app can't do this automatically."
                        showErrorAlert = true
                    }//: MAIN ACTOR
                    return false
                }//: IF (recordName != String.mediaIdPlaceholder, let savedRec)
            }//: IF (deviceIsOnline)
        }//: isDeviceOnlineForDeleting(cert)
        
        private func isICloudAvailableForDeleting(cert: CertificateInfo) async -> Bool {
            if cloudBrain.iCloudIsAccessible {
                return true
            } else {
                let certRecId = cert.certCloudRecordName
                if certRecId.recordName != String.mediaIdPlaceholder, let savedRec = masterList.getLocalMediaRecord(using: certRecId) {
                    savedRec.shouldDelete = true
                    savedRec.errorMessage = "Certificate could not be deleted from device because iCloud was not available at the time of deletion."
                    masterList.saveList()
                    await MainActor.run {
                        errorAlertTitle = "iCloud Unavailable/Error"
                        errorAlertMessage = "The CE certificate for the activity you wish to delete is currently saved in iCloud, but the online file could not be removed becuase the iCloud account it was stored under is not available to the app at the time of deletion. The app went ahead and deleted the activity but will make another attempt at deleting the record on iCloud once iCloud is accessible again."
                        showErrorAlert = true
                    }//: MAIN ACTOR
                    return false
                } else {
                    await MainActor.run {
                        errorAlertTitle = "iCloud Unavailable/Error"
                        errorAlertMessage = "The CE certificate for the activity you wish to delete is currently saved in iCloud, but the online file could not be removed becuase the iCloud account it was stored under is not available to the app at the time of deletion. The app went ahead and deleted the activity but will make another attempt at deleting the record on iCloud once iCloud is accessible again. You may need to manually delete the certificate in iCloud using the Finder or Files app on your device if the app can't do this automatically."
                        showErrorAlert = true
                    }//: MAIN ACTOR
                    return false
                }//: IF (recordName != String.mediaIdPlaceholder, let savedRec)
            }//: IF (mediaBrain.iCloudIsAccessible)
        }//: isICloudAvailableForDeleting(cert)
        
        private func removeCertFromICloud(cert: CertificateInfo) async -> Bool {
            let certRecId = cert.certCloudRecordName
            if certRecId.recordName != String.mediaIdPlaceholder {
                let deletionResult = await cloudBrain.deleteCompleteCKRecordWithoutModel(for: certRecId, recordType: .certificate)
                switch deletionResult {
                case .success(_):
                    return true
                case .failure(let syncError):
                    await MainActor.run {
                        errorAlertTitle = "iCloud Deletion Failed"
                        errorAlertMessage = "The app was unable to delete the associated certificate data that is saved on iCloud. Tap on the details button for more information."
                        errorAlertDetails = syncError.localizedDescription
                        showErrorAlert = true
                    }//: MAIN ACTOR
                    return false
                }//: SWITCH
            } else {
                Task{@MainActor in
                    dataController.delete(cert)
                }//: TASK
                return false
            }//: IF (certRecId.recordName != .mediaIdPlaceholder)
        }//: removeCertFromICloud
        
        private func removeCertMediaRecord(for cert: CertificateInfo) async -> Bool {
            let cloudRecId = cert.certCloudRecordName
            if cloudRecId.recordName != String.mediaIdPlaceholder, let savedRec = masterList.getLocalMediaRecord(using: cloudRecId) {
                masterList.removeMediaRecord(withID: savedRec.id)
                masterList.saveList()
            }//: IF (recordName != .mediaIdPlaceholder)
            
            Task{@MainActor in
                dataController.delete(cert)
            }//: TASK
            return true
        }//: removeCertMediaRecord(for)
        
        // MARK: DELETION HELPERS
        private func deleteActivityCDObject(activity: CeActivity) async {
            Task{@MainActor in
                dataController.delete(activity)
                dataController.save()
            }//: TASK
        }//: deleteActivityCDObject(activity)
        
        private func deleteLocallySavedCertificate(for activity: CeActivity) async -> Bool {
            let fileSystem = FileManager.default
            
            if let savedCert = activity.certificate,
            let fileToRemove: URL = savedCert.resolveURL(basePath: .documentsDirectory) {
                do {
                    _ = try fileSystem.removeItem(at: fileToRemove)
                    return true
                } catch let diskError as CocoaError {
                    Task{@MainActor in
                        let alertStrings = fileSystem.handleCommonDiskErrors(
                            thrownError: diskError,
                            when: .writing,
                            objectName: "ActivityCertificateImageView viewModel",
                            callingMethod: "setRelativePathStringForNewCert"
                        )//: handleCommonDiskErrors
                        errorAlertTitle = alertStrings.alertTitle
                        errorAlertMessage = alertStrings.alertMessage
                        errorAlertDetails = diskError.localizedDescription
                        showErrorAlert = true
                    }//: TASK
                    return false
                } catch {
                    NSLog(">>>ContentViewModel | deleteCeForFreeUser")
                    NSLog(">>>The removeItem(at) method threw an error while attempting to delete the file at: \(fileToRemove.absoluteString)")
                    await MainActor.run {
                        errorAlertTitle = "Deletion Error"
                        errorAlertMessage = "The selected CE activity could not be deleted due to an uncommon technical issue. Please tap on the details button to see the specific error details."
                        errorAlertDetails = error.localizedDescription
                        showErrorAlert = true
                    }//: MAIN ACTOR
                    return false
                }//: DO-CATCH
            } else {
                NSLog(">>>ContentViewModel | deleteLocallySavedCertificate")
                NSLog(">>>Unable to delete the locally saved certificate file because either the associated CeActivity object doesn't have a corresponding CertificateInfo object or the file URL for that certificate is nil. Nothing to delete.")
                return false
            }//: IF LET (savedCert, fileToRemove)
        }//: deleteLocallySavedCertificate(for)
        
        // MARK: - INIT
        init(dataController: DataController) {
            self.dataController = dataController
            
            let credRequest = Credential.fetchRequest()
            credRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Credential.name, ascending: true)]
            
            let activityRequest = CeActivity.fetchRequest()
            activityRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CeActivity.activityTitle, ascending: true)]
            
            let renewalRequest = RenewalPeriod.fetchRequest()
            renewalRequest.sortDescriptors = [NSSortDescriptor(key: "periodEnd", ascending: true)]
            
            credsController = NSFetchedResultsController(
                fetchRequest: credRequest,
                managedObjectContext: dataController.container.viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            activitiesController = NSFetchedResultsController(
                fetchRequest: activityRequest,
                managedObjectContext: dataController.container.viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
                )
            
            renewalsController = NSFetchedResultsController(
                fetchRequest: renewalRequest,
                managedObjectContext: dataController.container.viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )//: renewalsController
            
            super.init()
            credsController.delegate = self
            activitiesController.delegate = self
            renewalsController.delegate = self
            
            do {
                try credsController.performFetch()
                allCredentials = credsController.fetchedObjects ?? []
                
                try activitiesController.performFetch()
                allActivities = activitiesController.fetchedObjects ?? []
                
                try renewalsController.performFetch( )
                allRenewals = renewalsController.fetchedObjects ?? []
                
            } catch {
                NSLog(">>>ContentViewModel init error: \(error.localizedDescription)")
                NSLog(">>>Failed to load any credentials, activities, or renewals.")
            }//: DO-CATCH
            
        }//: INIT
        
    }//: VIEW MODEL
    
    
}//: EXTENSION
