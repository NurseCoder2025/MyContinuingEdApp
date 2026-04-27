//
//  CMB_Static.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/27/26.
//

import CloudKit
import Foundation

extension  CloudMediaBrain {
    
    // MARK: - STATIC METHODS
    
    static func handleCloudDbSubscriptionSetup(
        repeatCount: Int = 0
    ) async -> Result<CloudDbSubStatus, Error> {
        let mediaBrain = CloudMediaBrain.shared
        let settings = mediaBrain.settings
        let cloudState = mediaBrain.iCloudIsAccessible
        guard !settings.appHasCloudDatabaseSubscriptionSetup else {
            return Result.success(.alreadyCreated)
        }//: GUARD
        
        var currentSubscriptions: [CKSubscription] = []
        if cloudState {
            do {
                currentSubscriptions = try await mediaBrain.cloudDB.allSubscriptions()
            } catch let webError as CKError {
                if mediaBrain.shouldRetry(error: webError, currentRetry: repeatCount) {
                    let delay = mediaBrain.calculateRetryBackoff(retryCount: repeatCount, error: webError)
                    try? await Task.sleep(for: .seconds(0.1))
                    return await handleCloudDbSubscriptionSetup(repeatCount: repeatCount + 1)
                } else {
                    NSLog(">>> CloudMediaBrain error: handleCloudDbSubscriptionSetup")
                    NSLog(">>> Could not obtain any of the subscriptions saved on the user's iCloud account due to a CKError: \(webError.localizedDescription)")
                    return Result.failure(webError)
                }//: IF ELSE
            } catch {
                NSLog(">>> CloudMediaBrain error: handleCloudDbSubscriptionSetup")
                NSLog(">>> Could not obtain any of the subscriptions svaed on the user's iCloud account due to a general error: \(error.localizedDescription)")
                return Result.failure(error)
            }//: DO-CATCH
            
            let desiredSub = mediaBrain.configureDatabaseSubscription()
            
            if currentSubscriptions.contains(desiredSub) {
                settings.appHasCloudDatabaseSubscriptionSetup = true
                settings.encodeCurrentState()
                return Result.success(.alreadyCreated)
            } else {
                let setupResult = await mediaBrain.setupInitialCloudDBSubscription()
                switch setupResult {
                case .success(_):
                    settings.appHasCloudDatabaseSubscriptionSetup = true
                    settings.encodeCurrentState()
                    return Result.success(.justAdded)
                case .failure(let error):
                    if let cloudError = error as? CloudSyncError {
                        await MainActor.run {
                            mediaBrain.userErrorMessage = cloudError.localizedDescription
                        }//: MAIN ACTOR
                    }//: IF LET (cloudError)
                    NSLog(">>> CloudMediaBrain error: handleCloudDbSubscriptionSetup")
                    NSLog(">>> Unable to add the CKDatabaseSubscription due to the following error: \(error.localizedDescription)")
                    return Result.failure(error)
                }//: SWITCH
            }//: IF ELSE
        } else {
            NSLog(">>> CloudMediaBrain error: handleCloudDbSubscriptionSetup")
            NSLog(">>> Unable to add the CKDatabaseSubscription due to the fact that iCloud was unavailable at the time this method was called.")
            return Result.failure(CloudSyncError.cloudUnavailable)
        }//: IF (cloudState)
    }//: handleCloudDbSubscriptionSetup()
    
    static func setupAndVerifyZones() async {
        let brain = CloudMediaBrain.shared
        guard brain.iCloudIsAccessible else { return }
        
        await brain.initialZoneSetup()
        if brain.zonesCreated {
            brain.settings.zonesCreated = true
            brain.settings.zoneVerificationDate = Date()
            brain.settings.encodeCurrentState()
        }//: IF (zonesCreated)
    }//: verifyAndCreateZones()
    
}//: EXTENSION
