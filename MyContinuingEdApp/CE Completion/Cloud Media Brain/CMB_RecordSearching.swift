//
//  CMB_RecordSearching.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/27/26.
//

import CloudKit
import Foundation

extension CloudMediaBrain {
    
    // MARK: - RECORD SEARCHING
    
    func findMatchingRecordWith(
        recId: CKRecord.ID,
        recType: MediaClass,
        using model: MediaModel? = nil,
        withKeys: [String] = [],
        retryCount: Int = 0
    ) async -> CKRecord? {
        guard iCloudIsAccessible else { return nil }
        var matchingRecord: CKRecord? = nil
        do {
            // Option for pulling part of the record but not the whole thing
            if withKeys.isNotEmpty {
                let searchResult = try await cloudDB.records(for: [recId], desiredKeys: withKeys)
                if let resultForId = searchResult[recId] {
                    switch resultForId {
                    case .success(let record):
                        matchingRecord = record
                    case .failure(let error):
                        logRecordCantBeFound(for: recId, with: error)
                    }//: SWITCH
                } else {
                    logRecordCantBeFound(for: recId, with: CloudSyncError.cloudRecordNotFound(recType))
                }//: IF LET ELSE (resultForId)
            } else {
                // Retrieving the entire record, which will download any associated CKAssets
                matchingRecord = try await cloudDB.record(for: recId)
            }//: IF ELSE (withKeys.isNotEmpty)
        } catch let webError as CKError {
          if shouldRetry(error: webError, currentRetry: retryCount) {
                let _ = calculateRetryBackoff(retryCount: retryCount, error: webError)
                _ = try? await Task.sleep(for: .seconds(0.01))
              if let modelToUse = model {
                  return await findMatchingRecordWith(
                    recId: recId,
                    recType: recType,
                    using: modelToUse,
                    withKeys: withKeys,
                    retryCount: retryCount + 1
                  )//: findMatchingRecordWith
              } else {
                  return await findMatchingRecordWith(
                    recId: recId,
                    recType: recType,
                    withKeys: withKeys,
                    retryCount: retryCount + 1
                  )//: findMatchingRecordWith
              }//: IF LET ELSE (modelToUse)
          } else {
              if let objModel = model {
                  matchingRecord = await searchZoneForRecordMatching(using: objModel)
              } else {
                  logRecordCantBeFound(for: recId, with: CloudSyncError.cloudRecordNotFound(recType))
              }//: IF LET (objModel)
          }//: IF ELSE (shouldRetry)
        } catch {
            if let objModel = model {
                matchingRecord = await searchZoneForRecordMatching(using: objModel)
            } else {
                logRecordCantBeFound(for: recId, with: CloudSyncError.cloudRecordNotFound(recType))
            }//: IF LET (objModel)
        }//: DO - CATCH
        
        return matchingRecord
    }//: findMatchingRecordWith(recId:)
    
    func logRecordCantBeFound(
        for record: CKRecord.ID,
        with error: Error,
        methodName: String = "findMatchingRecordWith"
    ) {
        NSLog("Unable to find the matching record for \(record.recordName)")
        NSLog(">>> CloudMediaBrain error: \(methodName): \(error.localizedDescription)")
    }//: logRecordCantBeFound(with error)
    
    func searchZoneForRecordMatching(
        using model: MediaModel,
        retryCount: Int = 0
    ) async -> CKRecord? {
        let matchingString = model.createAssignedObjIdString()
        let predicate: NSPredicate = NSPredicate(format: "\(String.assignedObjectKey) == %@", matchingString)
        let query: CKQuery = CKQuery(recordType: model.getRecTypeName(), predicate: predicate)
        
        let searchZone: CKRecordZone.ID = ((model.ckRecType == .certificate) ? certZone : audioZone).zoneID
        
        do {
            let searchResult = (try await cloudDB.records(matching: query, inZoneWith: searchZone, desiredKeys: nil, resultsLimit: 1)).matchResults
            
            if let foundRecord = searchResult.first {
                let searchRecordResult = foundRecord.1
                switch searchRecordResult {
                case .success(let record):
                    return record
                case .failure(let error):
                    NSLog(">>> CloudMediaBrain error: searchZoneForRecordMathing(using)")
                    NSLog(">>> The Cloud Kit query was able to find the matching CKRecord but could not read it  becuase: \(error.localizedDescription)")
                    return nil
                }//: SWITCH
            } else {
                NSLog(">>> CloudMediaBrain error: searchZoneForRecordMathing(using)")
                NSLog(">>> The Cloud Kit query was unable to retrieve any matching records after the search.")
                return nil
            }//: IF ELSE
        } catch let webError as CKError {
            if shouldRetry(error: webError, currentRetry: retryCount) {
                let delay = calculateRetryBackoff(retryCount: retryCount, error: webError)
                NSLog(">>> CloudMediaBrain: searchZoneForRecordMatching")
                NSLog(">>> Retrying record search after \(delay) seconds (\(retryCount + 1)/3")
                try? await Task.sleep(for: .seconds(0.01))
                return await searchZoneForRecordMatching(using: model, retryCount: retryCount + 1)
            } else {
                NSLog(">>> CloudMediaBrain error: searchZoneForRecordMathing(using)")
                NSLog(">>> The Cloud Kit query was unable to find the matching CKRecord due to: \(webError.localizedDescription)")
                return nil
            }//: IF (shouldRetry)
        } catch {
            NSLog(">>> CloudMediaBrain error: searchZoneForRecordMathing(using)")
            NSLog(">>> The Cloud Kit query was unable to find the matching CKRecord due to: \(error.localizedDescription)")
            return nil
        }//: DO - CATCH
    }//: searchZoneForRecordMatching(objID)
    
    
}//: EXTENSION
