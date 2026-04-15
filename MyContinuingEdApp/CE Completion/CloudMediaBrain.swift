//
//  MediaBrain.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/10/26.
//

import CloudKit
import CoreData
import Foundation


final class CloudMediaBrain: ObservableObject {
    // MARK: - PROPERTIES
    
    let settings = AppSettingsCache.shared
    let dataController: DataController
    
    let cloudDB: CKDatabase = CKContainer.default().privateCloudDatabase
    let certZone = CKRecordZone(zoneName: String.certificateZoneId)
    let audioZone = CKRecordZone(zoneName: String.audioReflectionZoneId)
    
    @Published var zonesCreated: Bool = false
    @Published var userErrorMessage: String = ""
    
    // MARK: - COMPUTED PROPERTIES
    
    var iCloudIsAccessible: Bool {
        return settings.iCloudState.iCloudIsAvailable
    }//: okToRunOnlineMethods
    
    var userIsAPaidSupporter: Bool {
        let subLevel = settings.getCurrentPurchaseLevel()
        return subLevel == .proSubscription || subLevel == .basicUnlock || subLevel == .proLifetime
    }//: userIsASubscriber
    
    // MARK: - RECORD ZONE HANDLING
    
    private func doAllZonesExistInDB() async -> Result<(Bool, [CKRecordZone]), Error> {
        var allZones: [CKRecordZone] = []
        do {
            allZones = try await cloudDB.allRecordZones()
            if allZones.contains(certZone) && allZones.contains(audioZone) {
                return Result.success((true, allZones))
            } else {
                NSLog(">>> The allRecordZones method did not throw an error but the returned array did not contain all of the zones that it should have.")
                NSLog(">>> Instead of finding both the cert and audio zones, only found: \(allZones.map(\.zoneID.zoneName))")
                return Result.success((false, allZones))
            }//: IF (contains)
        } catch {
            NSLog(">>> CloudMediaBrain error: doZonesExistInDB")
            NSLog(">>> the allRecordZones() method threw an error while trying to fetch all zones within the user's private iCloud database.")
            NSLog(">>> Error: \(error.localizedDescription)")
            return Result.failure(error)
        }//: DO-CATCH
    }//: doAllZonesExistInDB()
    
    private func createZone(_ zoneToSave: CKRecordZone) async -> Bool {
        do {
            _ = try await cloudDB.save(zoneToSave)
            return true
        } catch {
            NSLog(">>> CloudMediaBrain error: createZone")
            NSLog(">>> Unable to save the record zone to the database becuase: \(error.localizedDescription)")
            NSLog(">>> The zone that was supposed to be saved was: \(zoneToSave)")
            return false
        }//: DO-CATCH
    }//: createZone()
    
    private func initialZoneSetup() async {
        let zonesToCreate: [CKRecordZone] = [certZone, audioZone]
        let zoneCheckResult = await doAllZonesExistInDB()
        switch zoneCheckResult {
        case .success(let (zonesExist, savedZones)):
            if zonesExist {
                NSLog(">>> CloudMediaBrain: initialZoneSetup() - No need to create any new zones because the zones already exist.")
                zonesCreated = true
                return
            } else {
                let missingZones = zonesToCreate.filter {savedZones.contains($0) == false}
                let zonesToAdd: Int = missingZones.count
                var zonesAddedOk: Int = 0
                for zone in missingZones {
                    let creationSuccess = await createZone(zone)
                    if creationSuccess {
                        NSLog(">>> CloudMediaBrain: initialZoneSetup() - Successfully created a new zone: \(zone)")
                        zonesAddedOk += 1
                    } else {
                        NSLog(">>> CloudMediaBrain: initialZoneSetup() - Failed to create a new zone: \(zone)")
                        await MainActor.run {
                            userErrorMessage = "Encountered an error while trying to configure iCloud for media file storage for this app. Please check your internet connection and iCloud account settings. Notify the developer if this error continues to occur."
                        }//: MAIN ACTOR
                    }//: IF ELSE (creationSuccess)
                }//: LOOP
                if zonesAddedOk == zonesToAdd {
                    zonesCreated = true
                }
            }//: IF ELSE (zonesExist)
        case .failure(let error):
            NSLog(">>> CloudMediaBrain: initialZoneSetup() - Encountered an error while checking the zones in the database: \(error.localizedDescription)")
            await MainActor.run {
                userErrorMessage = "Encountered an error while trying to configure iCloud for media file storage for this app. Please check your internet connection and iCloud account settings. Notify the developer if this error continues to occur."
            }//: MAIN ACTOR
        }//: SWITCH
    }//: initialZoneSetup()
    
    private func needsZoneVerification(interval: TimeInterval = 60 * 60 * 24) -> Bool {
        guard let lastCheck = settings.zoneVerificationDate else { return true }
        return Date().timeIntervalSince(lastCheck) > interval
    }//: needsZoneVerification
    
    private func setupAndVerifyZones() async {
        await initialZoneSetup()
        if zonesCreated {
            settings.zonesCreated = true
            settings.zoneVerificationDate = Date()
            settings.encodeCurrentState()
        }//: IF (zonesCreated)
    }//: verifyAndCreateZones()
    
    // MARK: - SAVING
    
    private func createCKRecord(for objType: MediaClass, with model: MediaModel) -> CKRecord {
        let recType = model.getRecTypeName()
        let mediaName = model.getMediaTypeName()
        let assignedObjString = model.createAssignedObjIdString()
        
        let recAsset = CKAsset(fileURL: model.savedAt)
        var zoneToUse: CKRecordZone.ID
        
        switch objType {
        case .certificate:
            zoneToUse = certZone.zoneID
        case .audioReflection:
            zoneToUse = audioZone.zoneID
        }//: SWITCH
        
        let recID = CKRecord.ID(zoneID: zoneToUse)
        
        let record = CKRecord(recordType: recType, recordID: recID)
        record[String.mediaKey] = mediaName as CKRecordValue
        record[String.assignedObjectKey] = assignedObjString as CKRecordValue
        record[String.mediaDataKey] = recAsset
        
        return record
    }//: createCKRecord(for)
    
    private func saveRecToICloud(record: CKRecord) async -> Bool {
        do {
            _ = try await cloudDB.save(record)
            return true
        } catch {
            NSLog(">>> CloudMediaBrain error: saveRecToICloud(record) error")
            NSLog(">>> Error: \(error.localizedDescription)")
            await MainActor.run {
                userErrorMessage = "Encountered a problem while trying to upload the file to iCloud. Check your network connection, iCloud settings, & iCloud storage, and try uploading again later. Contact the developer if this issue persists."
            }//: MAIN ACTOR
            return false
        }//: DO-CATCH
    }//: saveRecToICloud(record)
    
    
    
    // MARK: - CHANGING
    
    // MARK: - DELETING
    
    // MARK: - HELPERS
    
    func canUserUtilizeCloudSyncFor(mediaType: MediaClass) -> Result<Bool, Error> {
        var userWantsToStoreInCloud: Bool = true
        switch mediaType {
        case .certificate:
            userWantsToStoreInCloud = settings.userCloudBooleanPrefs[.certsInCloud] ?? true
        case .audioReflection:
            userWantsToStoreInCloud = settings.userCloudBooleanPrefs[.audioInCloud] ?? true
        }// SWITCH
        
        let cloudSyncGoAhead: Bool = userIsAPaidSupporter && userWantsToStoreInCloud && iCloudIsAccessible
        
        if cloudSyncGoAhead {
            return Result.success(true)
        } else if userWantsToStoreInCloud == false {
            return Result.failure(CloudSyncError.prefersLocalStorage(mediaType))
        } else if iCloudIsAccessible == false {
            return Result.failure(CloudSyncError.cloudUnavailable)
        } else {
            return Result.failure(CloudSyncError.paidUpgradeNeeded)
        }//: IF ELSE
    }//: canUserUtilizeCloudSync()
    
    
    // MARK: - CERTIFICATE SPECIFIC
    
    func hasUserExceededMaxCertAllowance(allowance: Double = 500.0) throws -> Bool {
        guard settings.getCurrentPurchaseLevel() == .basicUnlock else  { return false }
        let currentRenewals = dataController.getCurrentRenewalPeriods()
        // There should only be one renewal period in currentRenewals
        // because the Basic Unlock only allows for one
        guard let renewal = currentRenewals.first else { throw CloudSyncError.noCurrentRenewalFound }
            var amountUploaded: Double = 0.0
            let uploadedCerts = renewal.getAllUploadedCertificates()
            for cert in uploadedCerts {
                amountUploaded += cert.fileSizeInMegabytes
            }//: LOOP
            return amountUploaded >= allowance
    }//: hasUserExceededMaxCertAllowance
    
    func isCEinCurrentRenewalPeriod(activity: CeActivity) throws -> Bool {
        guard settings.getCurrentPurchaseLevel() == .basicUnlock else  { return true }
        if let renewal = dataController.getCurrentRenewalPeriods().first {
            let allPeriodCes = renewal.completedRenewalActivities
            return allPeriodCes.contains(activity)
        } else {
            throw CloudSyncError.noCurrentRenewalFound
        }//: IF LET
    }//: isCEinCurrentRenewalPeriod()
    
    // MARK: - INIT
    
    init(dataController: DataController) {
        self.dataController = dataController
        
        if userIsAPaidSupporter && iCloudIsAccessible {
            Task{
                if !settings.zonesCreated || needsZoneVerification() {
                    await setupAndVerifyZones()
                }//: IF (zonesCreated OR needsZoneVerification)
            }//: TASK
        } else {
            if iCloudIsAccessible == false {
                userErrorMessage = settings.iCloudState.userMessage
            }//:IF
        }//: IF ELSE
    }//: INIT
    
    
}//: CloudMediaBrain
