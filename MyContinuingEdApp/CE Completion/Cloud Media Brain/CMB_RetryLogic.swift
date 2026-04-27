//
//  CMB_RetryLogic.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/27/26.
//

import CloudKit
import Foundation


extension CloudMediaBrain {
    
    // MARK: - RETRY LOGIC
    
    func shouldRetry(error: CKError, currentRetry: Int) -> Bool {
        guard currentRetry < 3 else { return false }
        
        switch error.code {
        case .networkFailure, .networkUnavailable, .serviceUnavailable, .requestRateLimited:
            return true
        case .zoneBusy, .serverResponseLost:
            return true
        default:
            return false
        }//: SWITCH
    }//: shouldRetry(error, currentRetry)
    
    func calculateRetryBackoff(retryCount: Int, error: CKError) -> TimeInterval {
        // Returning the recommended retry time value if the specific CKError
        // provides for that
        if let retryAfter = error.retryAfterSeconds {
            return retryAfter
        }//: IF LET (retryAfter)
        
        // Return an exponential backoff every 2 seconds
        return pow(2.0, Double(retryCount))
    }//: calculateRetryBackoff
    
    func repeatRecordSearchAfterError(
        error: CKError,
        for objectID: CKRecord.ID,
        with secDelay: Double = 0.01
    ) async -> CKRecord? {
        var mediaRecord: CKRecord? = nil
        for attempt in 0...2 {
            if shouldRetry(error: error, currentRetry: attempt) {
                let delay = calculateRetryBackoff(retryCount: attempt, error: error)
                NSLog(">>> CloudMediaBrain: downloadOnlineMediaFile")
                NSLog(">>> Retrying download after \(delay) seconds (attempt \(attempt + 1)/3")
                try? await Task.sleep(for: .seconds(secDelay))
                do {
                    mediaRecord = try await cloudDB.record(for: objectID)
                } catch {
                    NSLog(">>> Failed record(for) method | attempt #\(attempt)")
                }//: DO-CATCH
            }//: IF (shouldRetry)
        }//: LOOP
        return mediaRecord
    }//: repeatRecordSearchAfterError(error, for, with)
    
    
}//: EXTENSION
