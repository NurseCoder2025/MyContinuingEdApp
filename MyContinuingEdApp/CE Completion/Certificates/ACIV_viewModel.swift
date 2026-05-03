//
//  ACIV_viewModel.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/26/26.
//

import CloudKit
import CoreData
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
        private let netManager = NetworkManager.shared
        private let syncBrain = SmartSyncBrain.shared
        
        @ObservedObject var activity: CeActivity
        
        @Published var certificateSavedYN: Bool = false
        @Published var certificateToShow: CECertificate?
        
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
        
        
        // MARK: - ADD
        
        func addNewCertificate(usingData data: Data) async {
            
            let newCertResult = await saveNewCertToLocalDevice(withData: data)
            
            if userPaidSupportLevel != .free, let savedCert = newCertResult.cert {
                await smartSyncNewCertificate(cert: savedCert)
            }//: IF (userPaidSupportLevel, savedCert)
            
        }//: addNewCertificate
        
        private func saveNewCertToLocalDevice(withData data: Data) async -> (result: Bool, cert: CertificateInfo?) {
            // Step #1: Compress data in the right file format
            guard let certObj = getCertFromRawData(data: data),
                  let dataToSave = certObj.certData else {
                NSLog(">>>ACIV ViewModel | saveNewCertToLocalDevice")
                NSLog(">>>Unable to create a CECertificate object from the data passed in or obtain the respective Data from the certData computed property.")
                return (false, nil)
            } //: GUARD
            let context = dataController.container.viewContext
            
            if let existingCertInfo = activity.certificate {
                await deleteCertificate(withOption: .deviceAndCloud)
            }//: IF LET (existingCertInfo)
            
            // Step #2: Create CertificateInfo object and assign to activity with the following values:
            //          a. certType (using CertType enum)
            //          b. certFileSize
            //          c. relativePath (for local use)
            let newCertInfo = CertificateInfo(context: context)
            newCertInfo.infoID = UUID()
            newCertInfo.setCertificateMediaType(as: certObj.certificateType)
            newCertInfo.certFileSize = Double(dataToSave.count)
            newCertInfo.completedCe = activity
            dataController.save()
            
            let directoryResult = await createAndConfirmCertificateFolders()
            switch directoryResult {
            case .success(let dirOutcome):
                await setRelativePathStringForNewCert(folderResult: dirOutcome, withInfo: newCertInfo, ceCert: certObj)
            case .failure(_):
                // Setting the relative path as the file name for saving in the documentsDirectory
                // directly
                Task{@MainActor in
                    let pathName = fileSystem.createMediaFileName(forCE: activity, forPrompt: nil, as: .certificate, usingExt: certObj.fileExtension)
                    newCertInfo.relativePath = pathName
                    dataController.save()
                }//: TASK
            }//: SWITCH
            
            do {
                if let saveLocation = newCertInfo.resolveURL(basePath: .documentsDirectory) {
                    _ = try dataToSave.write(to: saveLocation, options: .completeFileProtection)
                    return (true, newCertInfo)
                } else {
                    NSLog(">>>ACIV ViewModel | saveNewCertToLocalDevice")
                    NSLog(">>>The CertificateInfo resolveURL(basePath) method returned a nil URL value using the path: \(newCertInfo.certInfoRelativePath).")
                    return (false, nil)
                }//: IF LET (saveLocation)
            } catch let diskError as CocoaError {
                handleCommonDiskErrors(thrownError: diskError)
                return (false, nil)
            } catch {
                NSLog(">>>ACIV ViewModel | saveNewCertToLocalDevice")
                NSLog(">>>The Data.write(to) method threw an error while trying to save the certificate file to the local device/disk.")
                NSLog(">>> Error details: \(error.localizedDescription)")
                Task{@MainActor in
                    certDisplayStatus = .error
                    errorDetailsText = "The file could not be written to your local device or disk. Please ensure that your device's storage is not full and that the app has write access to it."
                }//: TASK
                return (false, nil)
            }//: DO-CATCH
        }//: saveNewCertToLocalDevice()
        
        private func smartSyncNewCertificate(cert: CertificateInfo) async {
            guard mediaBrain.userIsAPaidSupporter else { return }//: GUARD
           
            if userPaidSupportLevel == .basicUnlock {
                let userPrefCheck = await userWantsCertsInCloudCheck(cert: cert)
                if userPrefCheck {
                    let syncEligibilityCheck = await canCoreUserUploadCertToiCloud(cert: cert)
                    if syncEligibilityCheck {
                        let initalPrepCheck = await initialUploadPrepFor(cert: cert)
                        if initalPrepCheck {
                            let networkCheck = await assessDeviceIsOnline(forCert: cert)
                            if networkCheck {
                                let iCloudCheck = await assessUserICloudIsAvailable(forCert: cert)
                                if iCloudCheck {
                                    await uploadCertificateToICloud(cert: cert)
                                }//: IF iCloudCheck
                            }//: IF (networkCheck)
                        }//: IF (initialPrepCheck)
                    }//: IF (syncEligibilityCheck)
                }//: IF (userPrefCheck)
            } else if userPaidSupportLevel == .proSubscription || userPaidSupportLevel == .proLifetime {
                let userPrefCheck = await userWantsCertsInCloudCheck(cert: cert)
                if userPrefCheck {
                    let syncEligibilityCheck = await canProUserSmartSyncCertAutomatically(cert: cert)
                    if syncEligibilityCheck {
                        let initalPrepCheck = await initialUploadPrepFor(cert: cert)
                        if initalPrepCheck {
                            let networkCheck = await assessDeviceIsOnline(forCert: cert)
                            if networkCheck {
                                let iCloudCheck = await assessUserICloudIsAvailable(forCert: cert)
                                if iCloudCheck {
                                    await uploadCertificateToICloud(cert: cert)
                                }//: IF iCloudCheck
                            }//: IF (networkCheck)
                        }//: IF (initialPrepCheck)
                    }//: IF (syncEligibilityCheck)
                }//: IF (userPrefCheck)
            }//: IF ELSE (userPaidSupportLevel)
        }//: smartSyncNewCertificate()
        
        // MARK: SAVE SUB-METHODS
        
        /// This certificate save sub-method basically looks at the current user preference in AppSettingsCache for whether
        /// they wish to save certificates in iCloud or not and returns that value.
        /// - Parameter cert: CertificateInfo object for the locally saved certificate that might be uploaded to iCloud
        /// - Returns: True if the user wants to save certificates in iCloud or not (caveat for Core users who do  not)
        ///
        /// This method should be called as the first step in the SmartSync sequence for CE certificates.  While the method
        /// essentially returns the current user preference via the CloudMediaBrain's userWantsCertsInCloud computed
        /// property, it also sets the certificate icon for Core or Pro users who have the preference turned off.  For Pro users,
        /// they automatically see the availableToUpload enum value since there are not limits on what they can upload to
        /// iCloud. However, for Core users the method first checks whether uploading the added certificate is even possible due
        /// to Core SmartSync limitations.
        ///
        /// If the Core user is eligible, then the method will set the certificate icon to availableToUpload.  Otherwise, it will
        /// remain as localStorageOnly.
        private func userWantsCertsInCloudCheck(cert: CertificateInfo) async -> Bool {
            guard userPaidSupportLevel != .free else {
                await MainActor.run {
                    certCloudIcon = .localOnly
                }//: MAIN ACTOR
                return false
            } //: GUARD
            var userWantsCloud: Bool = false
            
            Task {@MainActor in
                if userPaidSupportLevel == .basicUnlock {
                    if mediaBrain.userWantsCertsInCloud {
                        userWantsCloud = true
                    } else {
                        // The Core user does NOT want certificates saved to iCloud
                        // The Core user has the cloud preference for CE certificates turned OFF,
                        // so these lines basically set the appropriate cloud status icon
                        if syncBrain.shouldAllowCertUpload(for: cert) {
                            certCloudIcon = .availableToUpload
                            userWantsCloud = false
                        } else {
                            // IF the certificate is NOT eligible for SmartSync, then either it is
                            // becuase the limit has been reached, it is for an activity outside of
                            // the current renewal period, there is no current renewal period entered
                            // in the app (or any renewal periods altogether), or the user hasn't
                            // acknowledged the transition alert from the previous renewal to the
                            // new one.
                            
                            // Need to call the getSmartSyncIneligibilityReason method here mainly
                            // becuase this method updates two properties in SmartSyncBrain that
                            // are used for controlling the SmartSync icon that will be displayed to the
                            // user in the UI.
                            let ineligibilityReason = syncBrain.getSmartSyncIneligibilityReason(for: cert)
                            if ineligibilityReason.isNotEmpty {
                                certCloudIcon = .localOnly
                            }
                            userWantsCloud = false
                        }//: IF ELSE (shouldAllowCertUpload(for)
                    }//: IF ELSE (userWantsCertsInCloud - .basicUnlock)
                } else {
                        if mediaBrain.userWantsCertsInCloud {
                            userWantsCloud = true
                        } else {
                        // For Pro users, even if the certificate is for a CE activity that is outside
                        // of the selected SmartSync window timeframe, they can always upload whatever
                        // they want to iCloud.
                            certCloudIcon = .availableToUpload
                        userWantsCloud = false
                    }//: IF ELSE (userWantsCertsInCloud)
                }//: IF ELSE (userPaidSupportLevel)
            }//: TASK
            
            return userWantsCloud
        }//: userWantsCertsInCloudCheck()
        
        private func canCoreUserUploadCertToiCloud(cert: CertificateInfo) async -> Bool {
           await flagWhetherSmartSyncWillUploadCert(cert: cert)
        }//: canCoreUserUploadCertToiCloud(cert)
        
        private func initialUploadPrepFor(cert: CertificateInfo) async -> Bool {
            var result: Bool = false
            
            Task{@MainActor in
                if let model = cert.createMediaModelForCertInfo(),
                let savedPath = cert.resolveURL(basePath: .desktopDirectory) {
                    let zoneId = mediaBrain.certZone.zoneID
                    let newRecId = mediaBrain.createCKRecordID(using: model, forZoneId: zoneId)
                    cert.certCloudRecordName = newRecId
                    dataController.save()
                    
                    mediaList.addMediaRecord(
                        fromRec: newRecId,
                        type: .certificate,
                        originatedHere: true,
                        savedAt: savedPath
                    )//: addMediaRecord
                    mediaList.saveList()
                    result = true
                } else {
                    result = false
                    NSLog(">>>ACIV ViewModel | initialUploadPrepFor")
                    NSLog(">>>The method was not able to create the CKRecord.ID property for the CertificateInfo argument due to either a missing/invalid relativePath string, a nil value returned from the resolveURL(basePath method), or the medial model for the CertificateInfo object could not be created.")
                    if let assignedCe = cert.getAssignedCeActivity() {
                        NSLog(">>> CE Activity: \(assignedCe.ceTitle)")
                    }//: IF LET (assignedCe)
                }//: IF LET (model, savedPath)
            }//: TASK
            
            return result
        }//: initialUploadPrepFor(cert)
        
        private func assessDeviceIsOnline(forCert cert: CertificateInfo) async -> Bool {
            if deviceIsOnline {
                return true
            } else {
                await MainActor.run {
                    certCloudIcon = .internetUnavailable
                    if let savedFile = mediaList.getLocalMediaRecord(using: cert.certCloudRecordName) {
                        savedFile.shouldRetryUpload = true
                        savedFile.errorMessage = "Device was offline when a new CE certificate was added that was eligible for SmartSync upload. The app will try to automatically upload it to iCloud when the device is back online."
                        mediaList.saveList()
                    }//: IF LET (savedFile)
                }//: MAIN ACTOR
                return false
            }//: IF (isConnected)
        }//: assessDeviceIsOnline()
        
        private func assessUserICloudIsAvailable(forCert cert: CertificateInfo) async -> Bool {
            if mediaBrain.iCloudIsAccessible {
                return true
            } else {
                await MainActor.run {
                    certCloudIcon = .cloudError
                    certIconDetails = settings.iCloudState.userMessage
                }//: MAIN ACTOR
                if let savedFile = mediaList.getLocalMediaRecord(using: cert.certCloudRecordName) {
                    savedFile.shouldRetryUpload = true
                    savedFile.errorMessage = "The app does not have access to your iCloud account. Please check your iCloud drive settings, whether you are signed into iCloud, and if any restrictions have been placed on your account by Apple. The CE certificate you are adding will not be uploaded to iCloud."
                    mediaList.saveList()
                }//: IF LET (savedFile)
                return false
            }//: IF (mediaBrain.iCloudIsAccessible)
        }//: assessUserICloudIsAvailable(forCert)
        
        private func canProUserSmartSyncCertAutomatically(cert: CertificateInfo) async -> Bool {
            var result: Bool = false
            Task{@MainActor in
                let window = settings.smartSyncCertWindow
                let eligibilityResult = cert.isCertEligibleForSmartSync(syncWindow: window)
                switch eligibilityResult {
                case .success(_):
                    result = true
                case .failure(let syncError):
                    certCloudIcon = .availableToUpload
                    certIconDetails = syncError.localizedDescription
                    result = false
                }//: SWITCH
            }//: TASK
            return result
        }//: canProUserSmartSyncCertAutomatically(cert)
        
        private func uploadCertificateToICloud(cert: CertificateInfo) async {
            var certModel: MediaModel = .placeholder
            await MainActor.run {
                certModel = cert.createMediaModelForCertInfo() ?? .placeholder
            }//: MAIN ACTOR
           
            if !certModel.isPlaceholder {
                let uploadResult = await mediaBrain.manualCertUploadProcess(for: cert, using: certModel)
                switch uploadResult {
                case .success(_):
                    await MainActor.run {
                        cert.uploadedToICloud = true
                        certCloudIcon = .inICloud
                        dataController.save()
                    }//: MAIN ACTOR
                    syncBrain.updateSmartSyncUsage(for: cert)
                case .failure(let syncError):
                    await handleCertUploadError(syncError: syncError, forCert: cert)
                }//: SWITCH
            } else {
                let noModelError: CloudSyncError = .mediaModelError
                await handleCertUploadError(syncError: noModelError, forCert: cert)
            }//: IF LET (certModel)
        }//: uploadCertificateToICloud(cert)
        
        
        // MARK: SAVE HELPERS
        
        private func flagWhetherSmartSyncWillUploadCert(cert: CertificateInfo) async -> Bool {
            var willUpload: Bool = false
            Task{@MainActor in
                if syncBrain.shouldAllowCertUpload(for: cert) {
                    willUpload = true
                } else {
                    // Calling this method so the right SmartSync status icon and error properties
                    // in SmartSyncBrain are updated - don't need to use the returned String here
                    let _ = syncBrain.getSmartSyncIneligibilityReason(for: cert)
                    willUpload = false
                }//: IF ELSE (shouldAllowCertUpload)
            }//: TASK
            return willUpload
        }//: flagWhetherSmartSyncWillUploadCert(cert)
        
        private func createAndConfirmCertificateFolders() async -> Result<(allOK: Bool, missing: [String]), Error> {
            let topDirectoryName = fileSystem.createTopSubDirectoryName(for: .certificate).convertToASCIIonly()
            
            let activityDirectoryName = fileSystem.createActivitySubFolderName(for: activity).convertToASCIIonly()
            
            let topDirectory = URL.documentsDirectory.appending(path: topDirectoryName, directoryHint: .isDirectory)
            let activityPath: String = "\(topDirectoryName)/\(activityDirectoryName)"
            let activityDirectory = URL.documentsDirectory.appending(path: activityPath, directoryHint: .isDirectory)
            
            let topDirExists = fileSystem.doesFolderExistAt(path: topDirectory)
            let ceDirExists = fileSystem.doesFolderExistAt(path: activityDirectory)
            
            if topDirExists && ceDirExists {
                return Result.success((true, []))
            } else if topDirExists {
                return Result.success((false, [activityDirectoryName]))
            } else if ceDirExists {
                return Result.success((false, [topDirectoryName]))
            } else {
                return Result.failure(FileIOError.noDirectoryAvailable)
            }//: IF (topDirExists && ceDirExists)
        }//: createAndConfirmCertificateFolders()
        
        private func setRelativePathStringForNewCert(
            folderResult dirOutcome: (Bool, [String]),
            withInfo newCertInfo: CertificateInfo,
            ceCert certObj: CECertificate
        ) async {
            if dirOutcome.0 {
                saveComputedRelPathForCert(usingInfo: newCertInfo, ceCert: certObj)
            } else {
                let topDirectoryName = fileSystem.createTopSubDirectoryName(for: .certificate).convertToASCIIonly()
                
                let activityDirectoryName = fileSystem.createActivitySubFolderName(for: activity).convertToASCIIonly()
                if dirOutcome.1.contains(where: {$0 == topDirectoryName}) {
                    // If the top direcotry could not be created for whatever reason, try
                    // one more time and if that fails simply save the file name as the
                    // relative path string.
                    do {
                        let topPath = URL.documentsDirectory.appending(path: topDirectoryName, directoryHint: .isDirectory).relativePath
                        _ = try fileSystem.createDirectory(atPath: topPath, withIntermediateDirectories: true)
                        saveComputedRelPathForCert(usingInfo: newCertInfo, ceCert: certObj)
                    } catch let diskError as CocoaError {
                        handleCommonDiskErrors(thrownError: diskError)
                    } catch {
                        NSLog(">>>ACIV ViewModel | setRelativePathStringForNewCert")
                        NSLog(">>>The top-level directory for all CE certificates, 'Certificates', could not be created either by the initial createAndConfirmCertificateFolders or this backup method.")
                        NSLog(">>> Error details: \(error.localizedDescription)")
                        // Using just the documents directory to hold the certificate
                        let fileName = fileSystem.createMediaFileName(forCE: activity, forPrompt: nil, as: .certificate, usingExt: certObj.fileExtension).convertToASCIIonly()
                        Task{@MainActor in
                            newCertInfo.relativePath = fileName
                            dataController.save()
                        }//: TASK
                    }//: DO-CATCH
                } else if dirOutcome.1.contains(where: {$0 == activityDirectoryName}) {
                    do {
                        let pathString = "\(topDirectoryName)/\(activityDirectoryName)"
                        let activityPath = URL.documentsDirectory.appending(path: pathString, directoryHint: .isDirectory).relativePath
                        
                        _ = try fileSystem.createDirectory(atPath: activityPath, withIntermediateDirectories: true)
                        saveComputedRelPathForCert(usingInfo: newCertInfo, ceCert: certObj)
                    } catch let diskError as CocoaError {
                        handleCommonDiskErrors(thrownError: diskError)
                    } catch {
                        NSLog(">>>ACIV ViewModel | setRelativePathStringForNewCert")
                        NSLog(">>>The activity-specific directory for the given certificate could not be created either by the initial createAndConfirmCertificateFolders or this backup method.")
                        NSLog(">>> Error details: \(error.localizedDescription)")
                        // Simply save the certificate under the general Certificates top level directory
                        let certFileName = fileSystem.createMediaFileName(forCE: activity, forPrompt: nil, as: .certificate, usingExt: certObj.fileExtension).convertToASCIIonly()
                        let relPath = "\(topDirectoryName)/\(certFileName)"
                        Task{@MainActor in
                            newCertInfo.relativePath = relPath
                            dataController.save()
                        }//: TASK
                    }//: DO-CATCH
                }//: IF ELSE (dirCoutcome.1.contains)
            }//: IF ELSE (allOK)
        }//: setRelativePathStringForNewCert(folderResult)
        
        private func saveComputedRelPathForCert(
            usingInfo certInfo: CertificateInfo,
            ceCert: CECertificate
        ) {
            Task{@MainActor in
                let relPath = fileSystem.createRelativePathStringForCKRecord(
                    coreDataObj: certInfo,
                    assignedToCe: activity,
                    certExtension: ceCert.fileExtension
                )//: createRelativePathStringForCKRecord()
                
                certInfo.relativePath = relPath
                dataController.save()
            }//: TASK
        }//: saveComputedRelPathForCert()
        
        private func handleCertUploadError(
            syncError: Error,
            forCert cert: CertificateInfo
        ) async {
            await MainActor.run {
                certCloudIcon = .cloudError
                certIconDetails = syncError.localizedDescription
            }//: MAIN ACTOR
            mediaList.updateMediaRecWithError(fromRec: cert.certCloudRecordName, message: syncError.localizedDescription, setRetryUploadFlag: true)
        }//: handleCertUploadError
        
        
        // MARK: - DELETE
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
        
        
        // MARK: - LOAD / DOWNLOAD
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
                let downloadResult = await mediaBrain.downloadOnlineMediaFile(for: savedRecId, type: .certificate, using: certModel)
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
                let downloadResult = await mediaBrain.downloadOnlineMediaFile(for: cert.id, type: .certificate)
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
        
        private func getCertFromRawData(data: Data) -> CECertificate? {
            if let imageData = UIImage(data: data) {
                return CECertificate.image(imageData)
            } else if let pdfData = PDFDocument(data: data) {
                return CECertificate.pdf(pdfData)
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
        
        
        // MARK: - CLOUD REFRESH
        func manuallySyncMediaFiles() async {
            guard certCloudIcon != .downloadingMedia else {return}//: GUARD
            do {
                _ = try await doQuickNetworkCheck()
            } catch {
                return
            }//: DO-CATCH
            
            if !settings.shouldAutoDownloadMedia(forType: .certificate) {
                await MainActor.run {
                    errorAlertTitle = "Auto-Download OFF"
                    errorAlertMessage = "You currently have the auto-download feature for CE certificates turned off. Re-syncing your certificates will not download any new media files."
                    showGeneralAlert = true
                }//: MAIN ACTOR
            }//: IF (!shouldAutoDownloadMedia)
            
            await mediaBrain.syncLocalMediaFiles()
        }//: manuallySyncMediaFiles()
        
        
        // MARK: - BUTTON METHODS
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
        
        private func handleCommonDiskErrors(thrownError error: CocoaError) {
            if error.code == .fileWriteOutOfSpace {
                NSLog(">>>ACIV ViewModel | setRelativePathStringForNewCert")
                NSLog(">>>A Cococa Error was thrown by the FileManager's createDirectory method due to the user's device being completely full. User has been alerted.")
                Task{@MainActor in
                    errorAlertTitle = "Local Storage Full"
                    errorAlertMessage = "No new files can be added to your device because your storage is full. Please free up some space before trying to add a new CE certificate."
                    showGeneralAlert = true
                }//: TASK
            } else if error.code == .fileWriteVolumeReadOnly {
                NSLog(">>>ACIV ViewModel | setRelativePathStringForNewCert")
                NSLog(">>>A Cococa Error was thrown by the FileManager's createDirectory method due to the particular volume or disk being read-only at the moment. User has been alerted.")
                Task{@MainActor in
                    errorAlertTitle = "Cannot Write To Local Disk"
                    errorAlertMessage = "No files can be written to the currently selected disk or device because the volume is currently in read-only mode. Please ensure the volume has write permissions before trying to add a new CE certificate."
                    showGeneralAlert = true
                }//: TASK
            } else if error.code == .fileNoSuchFile {
                NSLog(">>>ACIV ViewModel | handleCommonDiskErrors")
                NSLog(">>>The file system could not locate the specified certificate file based on the path previously created or stored. User has been alerted.")
                Task{@MainActor in
                    errorAlertTitle = "File Not Found"
                    errorAlertMessage = "The file system could not locate the specific certificate file based on the path previously created or saved. If this file has been manually moved or deleted using the Finder or Files app, then re-add the certificate back to the app."
                    showGeneralAlert = true
                }//: TASK
            } else {
                NSLog(">>>ACIV ViewModel | handleCommonDiskErrors")
                NSLog(">>>Another type of Cocoa error has been thrown. User has been alerted.")
                NSLog(">>> Error details: \(error.localizedDescription)")
                Task{@MainActor in
                    errorAlertTitle = "Other Error"
                    errorAlertMessage = "The file system encountered a less common error while trying to access, save, or delete a locally saved certificate file. Please contact the app developer for assistance."
                    errorDetailsText = error.localizedDescription
                    showGeneralAlert = true
                }//: TASK
            }//: IF ELSE (diskError.code)
        }//: handleCommonDiskErrors(thrownError)
        
        
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
