//
//  ACIV_viewModel.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/26/26.
//

import CloudKit
import Foundation
import SwiftUI
import PDFKit
import UIKit

extension ActivityCertificateImageView {
    // MARK: - VIEW MODEL
    final class ViewModel: ObservableObject {
        // MARK: - PROPERTIES
        private let dataController: DataController
        private let fileSystem = FileManager.default
        private let settings = AppSettingsCache.shared
        private let mediaBrain = CloudMediaBrain.shared
        private let mediaList = MasterMediaList.shared
        
        @ObservedObject var activity: CeActivity
        
        @Published var certificateSavedYN: Bool = false
        @Published var certificateToShow: Certificate?
        
        // Status icons
        @Published var certDisplayStatus: MediaLoadingState = .noMedia
        @Published var certCloudIcon: MediaCloudStatusIcon = .noSavedMedia
        @Published var certIconDetails: String = ""
        
        // Limited SmartSync properties (for CeCache Core users only)
        @Published var cloudUploadAllowanceUsed: Double = 0.0
        @Published var isCloudAllowanceReached: Bool = false
        
        // Changing certificates
        @Published var showCertificateChangeWarning: Bool = false
        
        // Certificate document changes (i.e. downloading, etc.)
        @Published var certDocDownloadingProgress: String = ""
        
        // Certificate deletion properties
        @Published var showCertDeletionWarning: Bool = false
        @Published var showCertDeleteErrorAlert: Bool = false
        
        // Properties for alerting the user about any errors encountered
        @Published var showGeneralAlert: Bool = false
        @Published var errorAlertTitle: String = ""
        @Published var errorAlertMessage: String = ""
        
        // A separate error property designed to give users more detailed info about what happened via
        // a button that will appear once this String is populated with a value.
        @Published var errorDetailsText: String = ""
        
        
        // Certificate download related properties
        private var filesDownloaded: [String] = []
        private var filesNotDownloaded: [String] = []
        @Published var autoDownloadResult: String = ""
        @Published var isAutoDownloadingCerts: Bool = false
        
        // MARK: - COMPUTED PROPERTIES
        var deviceIsOnline: Bool {
            return NetworkManager.shared.isConnected
        }//: deviceIsOnline
        
        // MARK: - METHODS
        
        // MARK: ADD
        func addNewCertificate() async {
            
        }//: addNewCertificate
        
        private func locallyAddNewCertificate(withData data: Data) async {
            // Step #1: Compress data in the right file format
            
            // Step #2: Create CertificateInfo object and assign to activity with the following values:
            //          a. certType (using CertType enum)
            //          b. certFileSize
            //          c. relativePath (for local use)
            
            /*
             Step #3: Check if user is a paid supporter or not
                a. IF FREE, save only to device (using relativePath value)
                b. Ensure iCloud is available, and if not, alert user with alert
                c. IF CORE user (basic unlock):
                    i. save to local device first and then check SmartSync eligibility
                    ii. IF eligible && user has autoUpload turned on,
                          update SmartSync allowance by the size of the certificate,
                         create CKRecord with key-values and save it to iCloud,
                         updating the errorDetailsText and errorMessage property
                         if the file could not be saved to iCloud for whatever reason. Otherwise,
                        update the cloudIcon to show that the file is available for upload
                    iii. IF not eligible, notify user with cloudIcon error and errorDetails message
                         along with an alert
                d. IF PRO user:
                     i. Save to local device FIRST (using relativePath value)
                     ii. IF autoUpload is turned on:
                         1. Determine if certificate falls within the sync window specified
                         2. IF SO:
                             > create CKRecord and save it to iCloud
                             > Update the cloudIcon to uploading until the record is saved
                             > Change cloudIcon to savedInCloud once done, but if an error occurs,
                            show the error cloudIcon along with error details in the errorDetailsText property
                        3. Otherwise:
                            > change cloudIcon to uploadAvailable with details explaining that the certificate
                                is outside of the sync window, but the user can change it if desired
                    iii. IF autoUpload is OFF:
                         1. Change cloudIcon to uploadAvailable with button for manual upload
             */
        }//: locallyAddNewCertificate()
        private func smartSyncNewCertificate() async {
            
        }//: smartSyncNewCertificate()
        
        // MARK: DELETE
        func deleteCertificate(withOption option: MediaCloudOption = .deviceOnly) async {
            guard let savedCert = activity.certificate else { return }//: GUARD
            // Is the certificate stored in iCloud?
            let isInICloud = savedCert.uploadedToICloud
            
            if isInICloud {
                switch option {
                case .deviceOnly:
                    // For freeing up space on the user's device
                    await removeCertificateFromDevice()
                case .deviceAndCloud:
                    // For permanent removal of the certificate
                    await permanentlyRemoveCertificateAndInfo()
                case .cloudOnly:
                    // For freeing up space on iCloud/locally archiving certificate
                    await removeUploadedCertFromICloud()
                }//: SWITCH
            } else {
                await permanentlyRemoveCertificateAndInfo()
            }//: IF ELSE
        }//: deleteCertificate()
        
        private func removeUploadedCertFromICloud() async {
            guard let savedCert = activity.certificate else { return }//: GUARD
            do {
                _ = try await doQuickNetworkCheck()
            } catch {
                return
            }//: DO-CATCH
            
            // Is the certificate stored in iCloud?
            let isInICloud = savedCert.uploadedToICloud
            
            if isInICloud {
                let cloudDeleteResult = await deleteUploadedCertFile()
                if cloudDeleteResult.result {
                    await MainActor.run {
                        savedCert.uploadedToICloud = false
                        dataController.save()
                        certCloudIcon = .availableToUpload
                    }//: MAIN ACTOR
                } else {
                let cloudError = cloudDeleteResult.error
                    await MainActor.run {
                        certCloudIcon = .cloudError
                        certIconDetails = cloudError?.localizedDescription ?? "A network, server, or other iCloud error prevented the app from deleting the certificate saved in iCloud. Please try again later."
                    }//: MAIN ACTOR
                }//: IF ELSE (result)
            }//: IF (isInICloud)
        }//: removeUploadedCertFromICloud()
        
        private func removeCertificateFromDevice() async {
            guard let savedCert = activity.certificate else { return }//: GUARD
            
            if let savedLocation: URL = savedCert.resolveURL(basePath: .documentsDirectory) {
                let _ = await deleteCertFileOnDevice(at: savedLocation)
                
            }//: IF LET (savedLocation)
        }//: removeCertificateFromDevice()
        
        private func permanentlyRemoveCertFromDevice() async {
            guard let savedCert = activity.certificate  else { return }
            await removeCertificateFromDevice()
            // Making sure that the local file was actually deleted before removing the
            // CertificateInfo object
            if let formerFile = savedCert.resolveURL(basePath: .documentsDirectory),
               let deletedData = try? Data(contentsOf: formerFile) {
                NSLog(">>>ACIV ViewModel | permanentlyDeleteOnlineCertificateAndInfo")
                NSLog(">>>The locally stored certificate at \(formerFile.absoluteString) was still located by the app, meaning that the deleteCertFileOnDevice method failed to remove it.")
                await MainActor.run {
                    errorAlertTitle = "Certificate Not Fully Deleted"
                    errorAlertMessage = "The saved certificate on the device could not be deleted at this time. You can still add a new certificate file in place of this one, however. Use the Finder or Files app to manually delete the file off your device."
                    errorDetailsText = "The file was supposed to be at this path: \(formerFile.absoluteString). Use the Finder or Files app to find and manually delete the file off your device."
                    showGeneralAlert = true
                }//: MAIN ACTOR
            } //: IF LET ELSE (formerFile, deletedData)
        }//: permanentlyRemoveCertFromDevice()
        
        private func locallyDeleteCertificate() async -> Result<(success: Bool, onlineId: CKRecord.ID?), FileIOError> {
            guard let savedCert = activity.certificate else { return Result.failure(FileIOError.fileMissing)}//: GUARD
            let cloudRec = savedCert.certCloudRecordName
            // If the locally saved certificate is also saved on iCloud, return the CKRecord.ID in the result
            if cloudRec.recordName !=  String.mediaIdPlaceholder,
            let savedAt = savedCert.resolveURL(basePath: .documentsDirectory) {
                let deletionResult = await deleteCertFileOnDevice(at: savedAt)
                switch deletionResult {
                case .success(_):
                    return Result.success((true, cloudRec))
                case .failure(let error):
                    return Result.failure(error)
                }//: SWITCH
            // If the locally saved certificate is ONLY saved on the current device, only return a true if successful
            } else if let savedAT = savedCert.resolveURL(basePath: .documentsDirectory) {
                let deletionResult = await deleteCertFileOnDevice(at: savedAT)
                switch deletionResult {
                case .success(_):
                    return Result.success((true, nil))
                case .failure(let error):
                    return Result.failure(error)
                }//: SWITCH
            } else {
                // If the URL for the file doesn't exist or isn't valid
                NSLog(">>>ACIV ViewModel | locallyDeleteCertificate")
                NSLog(">>>The certificate file could not be deleted off the device because the file path was not found.")
                NSLog(">>> This is the relative path that was used to create the URL: \(savedCert.certInfoRelativePath)")
                return Result.failure(.fileMissing)
            }//: IF LET ELSE
        }//: locallyDeleteCertificate
        
        private func deleteUploadedCertFile() async -> (result: Bool, error: CloudSyncError?) {
            do {
                _ = try await doQuickNetworkCheck()
            } catch {
                return (false, nil)
            }//: DO-CATCH
            
            guard let savedCert = activity.certificate else { return (false, nil) }
            let savedRec = savedCert.certCloudRecordName
            
            if savedRec.recordName != String.mediaIdPlaceholder,
            let certModel = savedCert.createMediaModelForCertInfo() {
                let cloudDeleteResult = await mediaBrain.deleteEntireRecord(for: savedRec, using: certModel)
                switch cloudDeleteResult {
                case .success(_):
                    return (true, nil)
                case .failure(let error):
                    return (false, error)
                }//: SWITCH
            } else {
                // Either the certificate was never stored on iCloud (due to the placeholder CKRecord.ID)
                // or the medial model couldn't be created for the associated CertificateInfo object
                // because a needed property had a nil value
                NSLog(">>>ACIV ViewModel | deleteUploadedCertFile")
                NSLog(">>>A selected certificate could not be removed from iCloud because it ether was never saved to iCloud in the first place or the associated CertificateInfo object lacked a needed property to save it to iCloud to begin with.")
                return (true, nil)
            }//: IF LET ELSE (recordName != .mediaIdPalceholder, certModel)
        }//: deleteUploadedCertFile
        
        private func deleteCertFileOnDevice(at url: URL) async -> Result<Bool, FileIOError> {
                do {
                    _ = try fileSystem.removeItem(at: url)
                    return Result.success(true)
                } catch {
                    NSLog(">>>ACIV ViewModel | locallyDeleteCertificate")
                    NSLog(">>>The removeItem method threw an error when trying to delete a certificate file located at \(url.absoluteString)")
                    NSLog(">>> The specific error is: \(error.localizedDescription)")
                    await MainActor.run {
                        errorAlertTitle = "Certificate Not Deleted"
                        errorDetailsText = "The certificate file could not be deleted off the device due to a technical reason. Please tap on the details button to get more information and try again."
                        errorDetailsText = "The certificate could not be deleted off the device because or due to: \(error.localizedDescription)."
                        showCertDeleteErrorAlert = true
                    }//: MAIN ACTOR
                    return Result.failure(.unableToDelete)
                }//: DO-CATCH
        }//: deleteCertFileOnDevice
        
        private func permanentlyRemoveCertificateAndInfo() async {
            guard let savedCert = activity.certificate else { return }//: GUARD
            let certCloudId = savedCert.certCloudRecordName
            
            await permanentlyRemoveCertFromDevice()
            
            if savedCert.uploadedToICloud {
                let certInCloudWasDeleted = await deleteUploadedCertFile()
                if certInCloudWasDeleted.result {
                    deleteCertInfoObject()
                } else {
                    NSLog(">>>ACIV ViewModel | permanentlyDeleteCertificate")
                    NSLog(">>>The deleteUploadedCertFile returned false as the result of its operation to delete the CKRecord associated with the certificate for the activity \(activity.ceTitle).")
                    Task{@MainActor in
                        errorAlertTitle = "Certificate Not Fully Deleted"
                        errorAlertMessage = "The saved certificate in iCloud could not be deleted at this time. Tap on the error details button to get more info. However, the local file was removed and can be replaced with another file if desired."
                        
                        if let errorMessage = certInCloudWasDeleted.error?.localizedDescription {
                            errorDetailsText = errorMessage
                        } else {
                            errorDetailsText = "A network, server, or other technical error prevented the app from being able to delete the certificate off of iCloud at this time. The app will continue to try deleting the iCloud copy in the meantime."
                        }//: IF LET (errorMessage)
                        
                        let deletionErrorMessage: String = "An attempt was made to delete the certificate for the CE activity '\(activity.ceTitle)' from iCloud, but an error was encountered."
                        mediaList.updateMediaRecWithError(
                            fromRec: certCloudId,
                            message: deletionErrorMessage,
                            deleteFlag: true
                        )//: updateMediaRecWithError()
                        mediaList.saveList()
                        showGeneralAlert = true
                    }//: TASK
                    deleteCertInfoObject()
                }//: IF (certInCloudWasDeleted)
            } else {
                deleteCertInfoObject()
            }//: IF ELSE (uploadedToICloud)
        }//: permanentlyRemoveCertificateAndInfo()
        
        private func deleteCertInfoObject() {
            guard let savedCert = activity.certificate else { return }
            Task{@MainActor in
                dataController.delete(savedCert)
                dataController.save()
                await MainActor.run {
                    certCloudIcon = .noSavedMedia
                    certIconDetails = "Tap the certificate selection button to add a CE certificate file for this activity (must be either an image or PDF)."
                    certDisplayStatus = .noMedia
                }//: MAIN ACTOR
            }//: TASK
        }//: deleteCertInfoObject()
        
        
        // MARK: LOAD / DOWNLOAD
        func loadLocalFile() {
            guard let savedCert = activity.certificate else {
                // IF a certificate has NOT been saved for the activity
                certCloudIcon = .noSavedMedia
                certIconDetails = "Tap the certificate selection button to add a CE certificate file for this activity (must be either an image or PDF)."
                certDisplayStatus = .noMedia
                return
            }//: GUARD
            
            // If the user is able to sync the certificate in iCloud, has a previous
            // download attempt been made and an error encountered and logged?
            if mediaBrain.userIsAPaidSupporter {
                let uploadedRec = savedCert.certCloudRecordName
                if uploadedRec.recordName != String.mediaIdPlaceholder,
                   let savedRec = mediaList.getLocalMediaRecord(using: uploadedRec) {
                    if savedRec.shouldReDownload {
                        certCloudIcon = .availableToDownload
                        certIconDetails = "Tap above button to manually download the certificate from iCloud."
                        errorDetailsText = savedRec.errorMessage
                        certDisplayStatus = .noMedia
                        return
                    }//: IF (shouldReDownload)
                }//: IF LET (recordName != String.mediaIdPlaceholder, getLocalMediaRecord)
            }//: IF (userIsAPaidSupporter)
            
            if let certURL = savedCert.resolveURL(basePath: URL.documentsDirectory),
             let mediaData = (try? Data(contentsOf: certURL)),
             let savedCertData = getCertFromRawData(data: mediaData){
                certificateToShow = savedCertData
                certDisplayStatus = .loaded
                
                setCloudIconForLoadedCerts()
                
            } else if savedCert.uploadedToICloud {
                certCloudIcon = .availableToDownload
                certIconDetails = "Tap above button to manually download the certificate from iCloud."
                certDisplayStatus = .noMedia
            } else {
                certDisplayStatus = .error
                errorDetailsText = "Could not load the saved certificate file. Please try re-selecting the certificate file or take another picture of it."
            }//: IF LET ELSE (certURL, mediaData, savedCertData)
        }//: loadLocalFile
        
        func manuallyDownloadCertificate() async {
            do {
                _ = try await doQuickNetworkCheck()
            } catch {
                return
            }//: DO-CATCH
            
            guard mediaBrain.iCloudIsAccessible else {
                await MainActor.run {
                    certCloudIcon = .cloudError
                    certIconDetails = "iCloud is not currently accessible by this app. Please tap on the button above to see more details."
                    errorDetailsText = settings.iCloudState.userMessage
                }//: MAIN ACTOR
                return
            }//: GUARD
            guard let savedCert = activity.certificate else { return }//: GUARD
            await MainActor.run {
                certCloudIcon = .downloadingMedia
                certDisplayStatus = .loading
            }//: MAIN ACTOR
            
            let certModel = savedCert.createMediaModelForCertInfo()
            let savedRecId = savedCert.certCloudRecordName
            if savedRecId.recordName != String.mediaIdPlaceholder {
                let downloadResult = await mediaBrain.downloadOnlineMediaFile(for: savedRecId, using: certModel)
                switch downloadResult {
                case .success(_):
                    Task{@MainActor in
                        certCloudIcon = .inICloud
                        certDisplayStatus = .loaded
                    }//: TASK
                case .failure(let error):
                    Task{@MainActor in
                        certCloudIcon = .cloudError
                        errorDetailsText = error.localizedDescription
                        certDisplayStatus = .error
                    }//: TASK
                }//: SWITCH (downloadResult)
            }//: IF (recordName != String.mediaIdPlaceholder)
        }//: manuallyDownloadCertificate()
        
        private func downloadAllUploadedCerts() async {
            do {
                _ = try await doQuickNetworkCheck()
            } catch {
                return
            }//: DO-CATCH
            
            await MainActor.run {
                isAutoDownloadingCerts = true
            }//: MAIN ACTOR
            
            await manuallySyncMediaFiles()
            let certsToGet = mediaList.filesToDownload
            guard certsToGet.count > 0 else {
                await MainActor.run {
                    autoDownloadResult = "All of the certificates that have been uploaded to iCloud have been downloaded to this device. Happy times!"
                }//: MAIN ACTOR
                return
            }//: GUARD
            
            for cert in certsToGet {
                let downloadResult = await mediaBrain.downloadOnlineMediaFile(for: cert.id)
                switch downloadResult {
                case .success(let savedAt):
                    cert.errorMessage = ""
                    cert.shouldReDownload = false
                    filesDownloaded.append(savedAt.lastPathComponent)
                case .failure(_):
                    let certPath = mediaBrain.retrievePathFromID(recID: cert.id)
                    let fileName = String(certPath.split(separator: "/").last ?? "Unknown file")
                    filesNotDownloaded.append(fileName)
                }//: SWITCH
            }//: LOOP
            mediaList.saveList()
            
            if filesNotDownloaded.isEmpty {
                await MainActor.run {
                    autoDownloadResult = "All \(certsToGet.count) certificates that still needed to be downloaded were successfully downloaded to this device! Happy times!"
                }//: MAIN ACTOR
            } else {
                await MainActor.run {
                    autoDownloadResult = "Out of the \(certsToGet.count) certificates that needed to be downloaded to this device, only \(filesDownloaded.count) were successfully downloaded. The following files were not downloaded: \(filesNotDownloaded.joined(separator: ", ")). Try redownloading these files later."
                }//: MAIN ACTOR
            }//: IF ELSE (isEmpty)
            
            await MainActor.run {
                isAutoDownloadingCerts = false
            }//: MAIN ACTOR
        }//: downloadAllUploadedCerts()
        
        private func getCertFromRawData(data: Data) -> Certificate? {
            if let imageData = UIImage(data: data) {
                return imageData
            } else if let pdfData = PDFDocument(data: data) {
                return pdfData
            } else {
                return nil
            }//: IF LET
        }//: getCertFromRawData
        
        private func setCloudIconForLoadedCerts() {
            guard let savedCert = activity.certificate else {
                certCloudIcon = .noSavedMedia
                certIconDetails = "Tap the certificate selection button to add a CE certificate file for this activity (must be either an image or PDF)."
                return
            }//: GUARD
            guard savedCert.certErrorMessage.isEmpty else {
                // If an error message was saved to the CertificateInfo's errorMessage property, alert the
                // user
                certCloudIcon = .cloudError
                certIconDetails = "An error occured while either loading this certificate or while it was being uploaded to iCloud. Tap on the button above for more details."
                errorDetailsText = savedCert.certErrorMessage
                return
            }//: GUARD
            
            if userPaidSupportLevel == .basicUnlock {
                if savedCert.uploadedToICloud,
                isCloudAllowanceReached == false {
                    if settings.iCloudState == .loggedINDifferentAppleID {
                        certCloudIcon = .differentAppleID
                        certIconDetails = "You are currently logged into iCloud with an account that is different from the previous one used in this app. New certificate files will be synced with this account, but will not be available if you log out and login with another account."
                    } else {
                        certCloudIcon = .inICloud
                    }//: IF (loggedInDifferentAppleID)
                } else if isCloudAllowanceReached {
                    certCloudIcon = .cloudLimitReached
                    certIconDetails = "You've reached the 500MB limit for storing certificate files in iCloud. Either upgrade to a Pro plan or remove files like this one off of iCloud by tapping the button above."
                }//: IF (uploadedToICloud)
            } else if userPaidSupportLevel == .free {
                certCloudIcon = .localOnly
                certIconDetails = "Free users may only save certificates locally to their device. Upgrade to a paid option to enjoy the ability to sync them across your devices."
            } else {
                if !settings.shouldAutoDownloadMedia(forType: .certificate) {
                    certCloudIcon = .availableToDownload
                    certIconDetails = "You currently have the auto-download feature turned off for CE certificates. Tap the button to manually download it or turn auto-download on."
                } else {
                    if settings.iCloudState == .loggedINDifferentAppleID {
                        certCloudIcon = .differentAppleID
                        certIconDetails = "You are currently logged into iCloud with an account that is different from the previous one used in this app. New certificate files will be synced with this account, but will not be available if you log out and login with another account."
                    } else {
                        certCloudIcon = .inICloud
                    }//: IF (loggedInDifferentAppleID)
                }//: IF ELSE
            }//: IF ELSE (userPaidSupportLevel)
        }//: setCloudIconForLoadedCerts()
        
        
        // MARK: CLOUD REFRESH
        func manuallySyncMediaFiles() async {
            guard certCloudIcon != .downloadingMedia else {return}//: GUARD
            do {
                _ = try await doQuickNetworkCheck()
            } catch {
                return
            }//: DO-CATCH
            
            await mediaBrain.syncLocalMediaFiles()
        }//: manuallySyncMediaFiles()
        
        
        // MARK: BUTTON METHODS
        func turnAutoDownloadOn() {
            dataController.prefersAutoDownloadForCerts = true
        }//: turnAutoDownloadOn()
        
        func showUpgradeOptions() {
            
        }//: showUpgradeOptions
        
        // MARK: - HELPERS
        
        private func doQuickNetworkCheck() async throws {
            if !deviceIsOnline {
                await MainActor.run {
                    certCloudIcon = .internetUnavailable
                    certIconDetails = "Changes to certificates stored in iCloud won't take effect until you're connected to the internet. If you're wanting to upload or download a certificate, please try manually later once you have a solid connection."
                    errorAlertTitle = "No Internet Connection"
                    errorAlertMessage = "Your device appears to be offline, so online syncing can resume once a connection is re-established."
                    showGeneralAlert = true
                }//: MAIN ACTOR
                throw CloudSyncError.deviceOffline
            }//: IF (!deviceIsOnline)
        }//: doQuickNetworkCheck()
        
        func findOrphanCertFilesForDeletion() async {
            let filesToDelete = mediaList.filesToDelete
            guard filesToDelete.isNotEmpty else { return }
            
            for orphanFile in filesToDelete {
                if let fileURL = orphanFile.mediaURL {
                    do {
                        _ = try fileSystem.removeItem(at: fileURL)
                        mediaList.removeMediaRecord(withID: orphanFile.id)
                    } catch {
                        continue
                    }//: DO-CATCH
                }//: IF LET (fileURL)
            }//: LOOP
            mediaList.saveList()
        }//: findOrphanCertFilesForDeletion()
        
        // MARK: - SELECTORS
        
        @objc func handleCertAutoDownloadChange(_ notification: Notification) {
            Task{
                do {
                _ = try await doQuickNetworkCheck()
                } catch {
                    return
                }//: DO-CATCH
                _ = try? await Task.sleep(for: .seconds(0.1))
                if settings.shouldAutoDownloadMedia(forType: .certificate) && !isAutoDownloadingCerts {
                   await downloadAllUploadedCerts()
                }//: IF (shouldAutoDownloadMedia)
            }//: TASK
        }//: handleCertAutoDownloadChange()
        
        
        // MARK: - INIT
        init(
            dataController: DataController,
            activity: CeActivity
        ) {
            self.dataController = dataController
            self.activity = activity
            
            self.certificateSavedYN = activity.hasCompletionCertificate
            
            let nc = NotificationCenter.default
            
            nc.addObserver(
                self,
                selector: #selector(handleCertAutoDownloadChange(_:)),
                name: .certAutoDownloadSettingChanged,
                object: nil
            )//: OBSERVER
            
            
            
        }//: INIT
        // MARK: - DEINIT
        deinit {
            NotificationCenter.default.removeObserver(self)
        }//: DEINIT
        
    }//: VIEWMODEL
    
}//: ActivityCertificateImageView
