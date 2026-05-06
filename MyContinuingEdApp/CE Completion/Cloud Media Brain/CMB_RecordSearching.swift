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
                    logRecordCantBeFound(for: recId, with: CloudSyncError.cloudRecordNotFound)
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
                  logRecordCantBeFound(for: recId, with: CloudSyncError.cloudRecordNotFound)
              }//: IF LET (objModel)
          }//: IF ELSE (shouldRetry)
        } catch {
            if let objModel = model {
                matchingRecord = await searchZoneForRecordMatching(using: objModel)
            } else {
                logRecordCantBeFound(for: recId, with: CloudSyncError.cloudRecordNotFound)
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
    
    func getAllAudioRecords(retryCount: Int = 0) async throws -> (found: [CKRecord], missing: [CKRecord.ID]) {
        guard netManager.isConnected else { return ([], []) }//: GUARD
        return try await withCheckedThrowingContinuation { continuation in
            // Defining everything that needs to happen within the continuation
            // inside an internal method declaration (searchAttempt)
            func searchAttempt(retry: Int) {
                let audioPred: NSPredicate = NSPredicate(value: true)
                let audioQuery: CKQuery = CKQuery(
                    recordType: CkRecordType.audioReflection.rawValue, predicate: audioPred
                )//: CKQuery
                
                var audioRecordingsInCloud: [CKRecord] = []
                var audioRecordingsNotObtained: [CKRecord.ID] = []
                
                let queryOperation = CKQueryOperation(query: audioQuery)
                queryOperation.desiredKeys = [
                    String.mediaKey,
                    String.assignedObjectKey
                ]
                queryOperation.zoneID = audioZone.zoneID
                queryOperation.recordMatchedBlock = { recordId, result in
                    switch result {
                    case .success(let rec):
                        audioRecordingsInCloud.append(rec)
                    case .failure(let error):
                        NSLog(">>>CloudMediaBrain | getAllAudioRecords")
                        NSLog(">>>While attempting to find all stored audio reflections in iCloud, a record was found with the query but the record itself could not be obtained due to: \(error.localizedDescription).")
                        NSLog(">>> Record ID: \(recordId.recordName)")
                        audioRecordingsNotObtained.append(recordId)
                    }//: SWITCH
                }//: recordMatchedBlock
                
                queryOperation.queryResultBlock = { [weak self] result in
                    switch result {
                    case .success(_):
                        NSLog(">>>CloudMediaBrain | getAllAudioRecords")
                        NSLog(">>>The search operation completed successfully with a total of \(audioRecordingsInCloud.count) records obtained and \(audioRecordingsNotObtained.count) records that could not be obtained.")
                        continuation.resume(returning: (audioRecordingsInCloud, audioRecordingsNotObtained))
                    case .failure(let error):
                        if let webError = error as? CKError,
                           let _ = self?.shouldRetry(
                            error: webError,
                            currentRetry: retryCount
                           ),
                           let delay = self?.calculateRetryBackoff(
                            retryCount: retryCount,
                            error: webError
                           ) {
                            
                            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                                searchAttempt(retry: retryCount + 1)
                            }//: DISPATCH QUEUE
                            
                        } else {
                            NSLog(">>>CloudMediaBrain | getAllAudioRecords")
                            NSLog(">>>The queryOperation queryResultBlock encountered an unexpected error that is not a transient CKError: \(error.localizedDescription).")
                            continuation.resume(throwing: error)
                        }//: IF LET (webError = error as? CKError)
                    }//: SWITCH
                }//: queryResultBlock
                cloudDB.add(queryOperation)
            }//: FUNC
            
            // Calling the method so that it runs and the continuation resumes
            // ** VERY IMPORTANT **
            // If this method is not called, then the entire getAllAudioRecords method
            // will hang indefinitely!!
            searchAttempt(retry: retryCount)
        }//: withCheckedContinuation
    }//: getAllAudioRecords()
    
    
    func getAllCertificateRecords(retryCount: Int = 0) async throws -> (found: [CKRecord], missing: [CKRecord.ID]) {
        guard netManager.isConnected else { return ([], [])}//: GUARD
        
        let searchResult: ([CKRecord], [CKRecord.ID]) = try await withCheckedThrowingContinuation { continuation in
            // Defining the method that the continuation needs to run
            func certSearchAttempt(attemptNumber: Int) {
                let certPred: NSPredicate = NSPredicate(value: true)
                let certQuery: CKQuery = CKQuery(recordType: CkRecordType.certificate.rawValue, predicate: certPred)
                
                var certsInCloud: [CKRecord] = []
                var certsNotObtainable: [CKRecord.ID] = []
                
                let queryOp = CKQueryOperation(query: certQuery)
                queryOp.desiredKeys = [
                    String.mediaKey,
                    String.assignedObjectKey
                ]
                
                queryOp.zoneID = certZone.zoneID
                
                queryOp.recordMatchedBlock = { recId, result in
                    switch result {
                    case .success(let rec):
                        certsInCloud.append(rec)
                    case .failure(let error):
                        NSLog(">>>CloudMediaBrain | getAllCertificateRecords")
                        NSLog(">>>While searching for all CE certificate records in iCloud, the query operation was able to find but not pull the record for \(recId.recordName).")
                        NSLog(">>> Error details: \(error.localizedDescription).")
                        certsNotObtainable.append(recId)
                    }//: SWITCH
                }//: recordMatchedBlock
                queryOp.queryResultBlock = { [weak self] result in
                    switch result {
                    case .success(_):
                        NSLog(">>>CloudMediaBrain | getAllCertificateRecords")
                        NSLog(">>>The query operation for finding certificates in iCloud found a total of \(certsInCloud.count) records, with \(certsNotObtainable.count) records that could not be retrieved.")
                        continuation.resume(returning: (certsInCloud, certsNotObtainable))
                    case .failure(let error):
                        if let webError = error as? CKError,
                        let _ = self?.shouldRetry(error: webError, currentRetry: retryCount),
                        let delay = self?.calculateRetryBackoff(
                            retryCount: retryCount,
                            error: webError
                        ) {
                            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                                certSearchAttempt(attemptNumber: retryCount + 1)
                            }//: DISPATCH QUEUE
                        } else {
                            NSLog(">>>CloudMediaBrain | getAllCertificateRecords")
                            NSLog(">>>After making multiple attempts, could not successfully retrieve certificate records from iCloud.")
                            NSLog(">>> Error details: \(error.localizedDescription).")
                            continuation.resume(throwing: error)
                        }//: IF LET (webError)
                    }//: SWITCH
                }//: queryResultsBlock
                cloudDB.add(queryOp)
            }//: FUNC: certSearchAttempt
            
            // Calling the previously defined method
            certSearchAttempt(attemptNumber: retryCount)
        }//: CONTINUATION
        
        return searchResult
    }//: getAllCertificateRecords
    
    
}//: EXTENSION
