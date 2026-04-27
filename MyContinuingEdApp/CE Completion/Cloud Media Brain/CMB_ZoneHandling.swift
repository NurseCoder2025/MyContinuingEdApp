//
//  CMB_ZoneHandling.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/27/26.
//

import CloudKit
import Foundation


extension CloudMediaBrain {
    
    // MARK: - RECORD ZONE HANDLING
    
    func doAllZonesExistInDB(retryCount: Int = 0) async -> Result<(Bool, [CKRecordZone]), Error> {
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
        } catch let webError as CKError {
            if shouldRetry(error: webError, currentRetry: retryCount) {
                let delay = calculateRetryBackoff(retryCount: retryCount, error: webError)
                NSLog(">>> CloudMediaBrain: doAllZonesExistInDB retrying...")
                NSLog(">>> Retrying in \(delay) seconds...(attempt \(retryCount + 1)/3)")
                try? await Task.sleep(for: .seconds(0.01))
                return await doAllZonesExistInDB(retryCount: retryCount + 1)
            } else {
                NSLog(">>> CloudMediaBrain error: doZonesExistInDB")
                NSLog(">>> the allRecordZones() method threw an error while trying to fetch all zones within the user's private iCloud database, even after 3 additional attempts.")
                NSLog(">>> Error: \(webError.localizedDescription)")
                return Result.failure(webError)
            }//: IF ELSE
        } catch {
            NSLog(">>> CloudMediaBrain error: doZonesExistInDB")
            NSLog(">>> the allRecordZones() method threw an error while trying to fetch all zones within the user's private iCloud database.")
            NSLog(">>> Error: \(error.localizedDescription)")
            return Result.failure(error)
        }//: DO - CATCH
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
    
    func initialZoneSetup() async {
        let zonesToCreate: [CKRecordZone] = [certZone, audioZone]
        let zoneCheckResult = await doAllZonesExistInDB()
        switch zoneCheckResult {
        case .success(let (zonesExist, savedZones)):
            if zonesExist {
                NSLog(">>> CloudMediaBrain: initialZoneSetup() - No need to create any new zones because the zones already exist.")
                updateZonesCreated()
                return
            } else {
                let missingZones = zonesToCreate.filter {savedZones.doesNOTContain($0)}
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
                    updateZonesCreated()
                } else {
                    NSLog(">>> CloudMediaBrain: initialZoneSetup() - Failed to create all of the new zones. Zones that were not created: \(missingZones)")
                    await MainActor.run {
                        userErrorMessage = "Failed to properly configure your iCloud drive for this app to save and sync media files due to a technical, iCloud side error. Open this app later to see if issue gets resolved."
                    }//: MAIN ACTOR
                }//: IF ELSE (zonesAddedOk == zonesToAdd)
            }//: IF ELSE (zonesExist)
        case .failure(let error):
            NSLog(">>> CloudMediaBrain: initialZoneSetup() - Encountered an error while checking the zones in the database: \(error.localizedDescription)")
            await MainActor.run {
                userErrorMessage = "Encountered an error while trying to configure iCloud for media file storage for this app. Please check your internet connection and iCloud account settings. Notify the developer if this error continues to occur."
            }//: MAIN ACTOR
        }//: SWITCH
    }//: initialZoneSetup()
    
    func needsZoneVerification(interval: TimeInterval = (60 * 60 * 24)) -> Bool {
        guard settings.zonesCreated else { return true }
        guard let lastCheck = settings.zoneVerificationDate else { return true }
        return Date().timeIntervalSince(lastCheck) > interval
    }//: needsZoneVerification
    
}//: EXTENSION
