//
//  CertificateInfo-CoreDataHelper.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/1/26.
//

import CloudKit
import CoreData
import Foundation

extension CertificateInfo {
    // MARK: - UI Helpers
    
    var certInfoId: UUID {
        get {
            infoID ?? UUID()
        }
    }//: certInfoId
    
    var certInfoRelativePath: String {
        get {
            relativePath ?? "noCertificate.pdf"
        }
        set {
            relativePath = newValue
        }
    }//: certInfoRelativePath
    
    /// CoreData helper computed property for CertificateInfo that gets the String value for the
    /// certType property.
    ///
    /// - Important: This is a getter-only.  For setting the value of this property, use the class
    /// helper method setCertificateMediaType(as). That will put in the correct String value.
    var certInfoCertType: String {
        get {
            certType ?? ""
        }
    }//: certInfoCertType
    
    /// Computed CoreDate helper property for CertificateInfo that gets and sets the certCKRecordName
    /// property for any given CKRecord.ID object.
    ///
    /// - Note: If the certCKRecordName property is currently nil, then the getter will return a new
    /// CKRecord.ID object with the name contained in the String extension mediaIdPlaceholder constant.
    ///
    /// This computed property sets all new values as NSObjects as that is the underlying data type behind
    /// Transformable types.  However, since CKRecord.ID inherits from NSObject then it can be
    /// downcast to that type and saved in the database.
    var certCloudRecordName: CKRecord.ID {
        get {
            guard let record = ckRecordID as? CKRecord.ID else {
                return CKRecord.ID(recordName: String.mediaIdPlaceholder)
            }//: GUARD
            return record
        }
        
        set {
            ckRecordID = newValue as NSObject
        }
    }//: certCloudRecordName
    
    var certErrorMessage: String {
        get {
            errorMessage ?? ""
        }
        set {
            errorMessage = newValue
        }
    }//: certErrorMessage
    
    // MARK: - Computed Properties
    
    var hasError: Bool {
        certErrorMessage.isNotEmpty
    }//: hasError
    
    /// CoreData computed helper property for CertificateInfo that returns either the ceTtile helper value
    /// for the CeActivity assigned to the CertificateInfo object or "N/A" if no activity has been assigned.
    var completedActivityName: String {
        completedCe?.ceTitle ?? "N/A"
    }//: completedActivityName
    
    /// CoreData computed helper property for CertificateInfo that returns either the ceActivityCompletedDate
    /// value or the distantPast Date constant if no CeActivity has been assigned to the object.
    var completedActivityDate: Date {
        completedCe?.ceActivityCompletedDate ?? Date.distantPast
    }//: completedActivityDate
    
    var formattedActivityCompletionDate: String {
        completedActivityDate.formatDateIntoHyphenedString()
    }//: formattedActivityCompletionDate
    
    var fileSizeInMegabytes: Double {
        certFileSize / 1_024_000.0
    }//: fileSizeInMegabytes
    
    // MARK: - RELATIONSHIPS
    
    func getAssignedCeActivity() -> CeActivity? { return completedCe }//: getAssignedCeActivity()
    
    
    // MARK: - METHODS
    
    /// CoreData helper method for CertificateInfo that sets the String value for the certType property
    /// using one of the CertType enum values (whose raw value is a String)
    /// - Parameter type: CertType enum value corresponding to whether the certificate being
    /// saved is an image or pdf file
    func setCertificateMediaType(as type: CertType) {
        certType = type.rawValue
    }//: setCertificateMediaType(as)
    
    /// CertificateInfo CoreData helper method that returns a URL value for where the actual
    /// certificate binary file was stored at on the local device.
    /// - Parameter basePath: URL representing the top-level folder that holds all CE
    /// Certificates on the device (use the URL constant)
    /// - Returns: Optional URL if a URL can be constructed from the relativePath CertificateInfo
    /// property and the basePath argument
    ///
    /// The relativePath in the CertificateInfo CoreData entity object should be in the following format:
    /// \(computed activity file folder name)\(computed file name.extension)
    func resolveURL(basePath: URL) -> URL? {
        guard basePath.hasDirectoryPath else {return nil}
        guard let pathSaved = relativePath else {return nil}
        return basePath.appending(path: pathSaved, directoryHint: .notDirectory)
    }//: resolveURL(basePath)
    
    /// CertificateInfo method for determining whether the binary data for a saved CE certificate
    /// meets the "SmartSync" criteria for uploading into iCloud or not.
    /// - Parameter syncWindow: Double value indicating the number of years the user
    /// needs to maintain CE certificates for licensure purposes
    /// - Returns: Boolean indicating if the dateCompleted value for the assigned CeActivity
    /// object is within the number of years indicated by the syncWindow argument.
    ///
    /// The "SmartSync" feature is two-fold:  for users who only purchase the Basic Unlock
    /// in-app purchase, their SmartSync only uploads certificates for the current renewal
    /// period, up to a specified data maxiumum.  Pro users (subscription or lifetime) can
    /// specifiy a particular window of time they need to maintain certificates in terms of years,
    /// like 6 years or whatever their licensing board requires.
    ///
    /// - Note: This method should be called whenever uploading certificates after
    /// verifying that the user is a Pro level user.
    ///
    /// In addition to returning false for certificates earned outside of the specified window, this
    /// method will also return false if:  1) There is either no assigned CeActivity or the
    /// dateCompleted property is nil  2) The syncWindow argument is less than 1.0  3) The
    /// date(byAdding: , value:, to:) method returns a nil
    func isCertEligibleForSmartSync(syncWindow: Double) -> Result<Bool, CloudSyncError> {
        let savedSettings = AppSettingsCache.shared
        let purchaseMade = savedSettings.getCurrentPurchaseLevel()
        guard purchaseMade != .free else {
            return Result.failure(CloudSyncError.paidUpgradeNeeded)
        }//: GUARD
        
        if purchaseMade == .proSubscription || purchaseMade == .proLifetime {
            return proUserSmartSyncCheck(with: syncWindow)
        } else {
            return basicUserSmartSyncCheck()
        }//: IF ELSE
    }//: isCertEligibleForSmartSync(syncWindow)
    
    
    private func proUserSmartSyncCheck(with window: Double) -> Result<Bool, CloudSyncError> {
        guard let ceCompltedOn = completedCe?.dateCompleted,
                window >= 1.0 else {
            NSLog(">>> CertificateInfo helper method error: proUserSmartSyncCheck")
            NSLog(">>> One of the pre-condition checks failed:")
            NSLog(">>> ceCompletedOn nil: \(completedCe?.dateCompleted == nil)")
            NSLog(">>> window argument: \(window)")
            return Result.failure(CloudSyncError.smartSyncDateWindowError)
        }//: GUARD
        
        guard window <= Double.maxCertAllowance else {
            let windowInt: Int = Int(window)
            return Result.failure(CloudSyncError.smartSyncMaxWindowExceeded(windowInt))
        }//: GUARD
        
        let convertedWindow = Int(window)
        let calendar = Calendar.current
        let now = Date()
        
        guard let dateBeforeWindow = calendar.date(
            byAdding: .year,
            value: -convertedWindow,
            to: now
        ) else {
            NSLog(">>> CertificateInfo helper method error: proUserSmartSyncCheck")
            NSLog(">>> The calendar.date(byAdding: .year, value: -convertedWindow, to: now method returned a nil value instead of a valid date.")
            NSLog(">>> window argument: \(window) | current date: \(now.formatted())")
            return Result.failure(CloudSyncError.smartSyncWindowCalcError)
        }//: GUARD
        
        let syncCheck = ceCompltedOn >= dateBeforeWindow && ceCompltedOn <= now
        if syncCheck {
            return Result.success(true)
        } else {
            return Result.failure(CloudSyncError.smartSyncCertOutOfWindow)
        }//: IF (syncCheck)
    }//: proUserSmartSyncCheck(with)
    
    private func basicUserSmartSyncCheck() -> Result<Bool, CloudSyncError> {
        guard let ceRenewals: [RenewalPeriod] = completedCe?.renewals as? [RenewalPeriod] else {
            return Result.failure(CloudSyncError.noRenewalPeriodsSaved)
        }//: GUARD
        
        if let currentRenewal = ceRenewals.filter({ $0.isRenewalCurrent }).first {
            let basicLimit: Int = Int(Double.maxCertAllowance)
            let limitExceeded: Bool = currentRenewal.hasUserExceededMaxCertAllowance()
            if limitExceeded {
                return Result.failure(CloudSyncError.basicCertLimitReached(basicLimit))
            } else {
                return Result.success(true)
            }//:IF ELSE
        } else {
            return Result.failure(CloudSyncError.noCurrentRenewalFound)
        }//: IF ELSE
    }//: basicUserSmartSyncCheck()
    
    func createMediaModelForCertInfo() -> MediaModel? {
        if let certInfoId = infoID,
        let certMediaType = certType,
        let certPath = resolveURL(basePath: URL.localCertificatesFolder),
        let filePath = relativePath {
            let recType: CkRecordType = .certificate
            var certMediaTypeEnum: MediaType
            
            if certMediaType == MediaType.image.rawValue {
                certMediaTypeEnum = .image
            } else if certMediaType == MediaType.pdf.rawValue {
                certMediaTypeEnum = .pdf
            } else {
                certMediaTypeEnum = .unspecified
            }//: IF ELSE (certMediaType)
            
            let newModel = MediaModel(
                assignedObjectId: certInfoId,
                ckRecType: recType,
                mediaType: certMediaTypeEnum,
                mediaDataSavedAt: certPath,
                relPathForCKRecordID: filePath
            )//: MEDIA MODEL
            return newModel
        } else {
            NSLog(">>> CertificateInfo ext error: createMediaModelForCertInfo")
            NSLog(">>> A MediaModel instance could not be created because  either one of the require CertificateInfo fields is nil or the relativePath field did not contain a valid path value.")
            return nil
        }//: IF LET (certInfoId, certMediaType, certPath)
    }//: createMediaModelForCertInfo
    
}//: EXTENSION

// MARK: - PROTOCOL CONFORMANCE
extension CertificateInfo: RepresentsDeletableMediaFile {
    
    func returnCDSelf() -> NSManagedObject {
        return self
    }//: returnCDSelf()
    
}//: EXTENSION
