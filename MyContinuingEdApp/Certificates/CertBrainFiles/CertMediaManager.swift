//
//  CertMediaManager.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/2/26.
//

import CoreData
import CloudKit
import Foundation


final class CertMediaManager: CloudMediaManager<CertificateModel> {
    // MARK: - PROPERTIES
    /*
     Parent class properties:
        - dataController (@EnvironmentObject)
        - mediaFiles: Set<forMedia>
        - isLoading: Bool
        - errorMessage: String
        - database: CKContainer
        - recordResultCount: Int
        - loadingError: Bool
        - loadingErrorMessage: String
     */
    
    var problemCertRecordFiles: [CKRecord.ID] = []
    
    // MARK: - LOADING
    
    func loadAllCertificates() async {
        isLoading = true
        errorMessage = ""
        
        let typeToLoad: String = CkRecordType.certificate.rawValue
        // Configuring search query (CKQuery)
        let query: CKQuery = CKQuery(recordType: typeToLoad, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        // Running query and handling results
        do {
            let (matchedResults,_) = try await database.records(matching: query)
            recordResultCount = matchedResults.count
            processCertRecordQueryResults(results: matchedResults)
        } catch {
            NSLog(">>> CertMediaManager error: loadAllCertificates()")
            NSLog(">>> iCloud-related error as the records(matching) method threw an error: \(error.localizedDescription).")
            self.errorMessage = "iCloud currently unavailable: \(error.localizedDescription)"
        }//: DO-CATCH
        
        if problemCertRecordFiles.isNotEmpty {
            loadingError = true
            loadingErrorMessage = "Not all certificates could be loaded. Out of \(recordResultCount) files, \(problemCertRecordFiles.count) could not be loaded.) "
            NSLog(">>> \(loadingErrorMessage)")
        }//: IF (isNotEmpty)
        
        isLoading = false
    }//: loadAllCertificates
    
    /// CertMediaManager method for finding the CKRecord that has the assignedObjectId value which matches the
    /// a specified CeActivity which has a certificate associated with it.
    /// - Parameter activity: CeActivity with previously saved certificate data
    ///
    /// This method uses two different pathways for locating the matching CKRecord.  First, it checks CoreData to see
    /// if the activity argument has a corresponding CertificateInfo object, and if the certInfoCKRecordName is not an
    /// empty string, then it uses that string value to create a CKRecordID that can be used to locate the cooresponding
    /// record.  Second, if there is an empty string value for certInfoCKRecordName, then the method runs a CKQuery
    /// to locate the record more directly via the private helper method findMatchingRecordFor(activity).
    func loadCertificateFor(activity: CeActivity) {
        guard let assignedCert = activity.certificate,
        let ceId = activity.activityID else {
            return
        }//: GUARD
        isLoading = true
        loadingErrorMessage = ""
        
        Task{
            if assignedCert.certInfoCKRecordName.isNotEmpty {
                let recordToFetch = CKRecord.ID(recordName: assignedCert.certInfoCKRecordName)
                do {
                    let fetchedRecord = try await database.record(for: recordToFetch)
                    guard fetchedRecord.recordType == CkRecordType.certificate.rawValue else {
                        NSLog(">>> CertMediaManager error: loadCertificateFor(activity)")
                        NSLog(">>> Expected the record type to be 'certificate', but instead it is \(fetchedRecord.recordType).")
                        self.loadingErrorMessage = "The certificate file for this activity does not appear to be an image or PDF file. Unable to load it."
                        return
                    }//: GUARD
                    
                    self.mediaFileToLoad = createCertModelFromCkRecord(fetchedRecord)
                } catch {
                    let customMessage: String = "Unable to locate the specified data needed to open the certificate for this activity."
                    self.createLoadFailureLogsAndMessage(
                        dueTo: error,
                        for: recordToFetch,
                        with: customMessage,
                        in: "loadCertificateFor(activity)",
                        methodClass: "CertMediaManager"
                    )//: createLoadFailureLogsAndMessage
                }//: DO-CATCH
            } else {
                if let foundCertData = await findMatchingRecordFor(activity: activity) {
                   if let loadedModel = createCertModelFromCkRecord(foundCertData) {
                        self.mediaFileToLoad = loadedModel
                   } else {
                       NSLog(">>> CertMediaManager error: loadCertificateFor(activity)")
                       NSLog(">>> Failed to create a CertificateModel from the CKRecord.")
                       self.loadingErrorMessage = "Error while loading data needed for finding the associated certificate data on iCloud for this activity."
                       self.loadingError = true
                   }//: IF LET ELSE (loadedModel)
                }//: IF LET (foundCertData)
            }//: IF ELSE (isNotEmpty)
        }//:TASK
        
    }//: loadCertificateFor(activity)
    
    // MARK: - SAVING
    
    func saveCertificateToCloudFor(activity: CeActivity, inFormat: MediaType, localSaveUrl: URL) async {
        var newModel = createCertModelFor(activity: activity, certFormat: inFormat)
        let newRecord = createNewCKRecord(recordType: CkRecordType.certificate, forModel: newModel, dataAt: localSaveUrl)
        
        do {
            let savedRecord = try await database.save(newRecord)
            newModel.cloudRecord = savedRecord
            self.mediaFiles.insert(newModel)
        } catch {
            NSLog(">>> CertMediaManager error: saveCertificateToCloudFor()")
            NSLog(">>> Error saving certificate to Cloud: \(error.localizedDescription)")
            self.errorMessage = "Error saving the certificate to iCloud. It remains saved locally on your device."
        }//: DO-CATCH
    }//: saveCertificateFor(activity)
    
    // MARK: - DELETION
    
    func deleteSavedCertificateFor(activity: CeActivity, asType: MediaType) async {
        guard let assignedCertificate = activity.certificate,
        let assignedId = activity.activityID else { return } //: GUARD
        
        do {
            try await deleteMediaItem(type: asType, for: assignedId)
            dataController.delete(assignedCertificate)
            dataController.save()
        } catch {
            NSLog(">>> CertMediaManager error: deleteSavedCertificateFor(activity)")
            NSLog(">>> Unable to find a matching CertificateModel to delete from the mediaFiles set.")
            NSLog(">>> Without the model, the CKRecord cannot be located and removed.")
        }//: DO-CATCH
        
    }//: deleteSavedCertificateFor(activity)
    
    // MARK: - HELPER METHODS
    private func processCertRecordQueryResults(
        results: [(CKRecord.ID, Result<CKRecord, any Error>)]
    ) {
        var fetchedCerts: [CertificateModel] = []
        
        for (item, recordResult) in results {
            switch recordResult {
            case .success(let record):
                if let savedCert = createCertModelFromCkRecord(record) {
                    fetchedCerts.append(savedCert)
                } else {
                    createLoadFailureLogsAndMessage(for: item, in: "processCertRecordQueryResults", methodClass: "CertMediaManager")
                    problemCertRecordFiles.append(item)
                }//: IF LET ELSE (savedCert)
            case .failure(let error):
                createLoadFailureLogsAndMessage(
                    dueTo: error,
                    for: item,
                    in: "processCertRecordQueryResults",
                    methodClass: "CertMediaManager"
                )
                problemCertRecordFiles.append(item)
            }//: SWITCH
        }//: LOOP
        
        fetchedCerts.forEach {
            self.mediaFiles.insert($0)
        }//: FOR EACH
    }//: processCertRecordQueryResults
    
    private func createCertModelFromCkRecord(_ record: CKRecord) -> CertificateModel? {
        if let pathString = record[.relPathKey] as? String,
            let medType = record[.mediaKey] as? String,
            let locName = record[.locationKey] as? String,
            let version = record[.versionKey] as? Double,
            let assocObj = record[.assignedObjectKey] as? UUID,
            let objectStringId = record[.objectIdStringKey] as? String {
            // Create the new CertificateModel record using CKRecord
            // Key-Values
            let savedCert = CertificateModel(
                relativePath: pathString,
                mediaType: medType,
                savedAt: locName,
                appVersion: version,
                assignedObjectId: assocObj,
                cloudRecord: record
            )//: CertificateModel
            
            return savedCert
        } else {
            return nil
        }//: IF LET ELSE
    }//: createCertModelFromCkRecord(record)
    
    private func findMatchingRecordFor(activity: CeActivity) async -> CKRecord? {
        guard let assignedCert = activity.certificate,
        let ceId = activity.activityID else { return nil }//: GUARD
        
        let activityIdString: String = ceId.uuidString
        let queryString: String = "\(String.objectIdStringKey) == %@"
        
        let activityPredicate: NSPredicate = NSPredicate(format: queryString, activityIdString)
        let query = CKQuery(recordType: CkRecordType.certificate.rawValue, predicate: activityPredicate)
        query.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: true)
        ]
        
        let qOperation = CKQueryOperation(query: query)
        qOperation.resultsLimit = 1
        
        return await withCheckedContinuation { continuation in
            var matchedRecord: CKRecord? = nil
            
            qOperation.recordMatchedBlock = {recordId, result in
                switch result {
                case .success(let record):
                    matchedRecord = record
                case .failure(let error):
                    let customMessage: String = "Unable to locate the certificate for the CE \(activity.ceTitle)"
                    self.createLoadFailureLogsAndMessage(
                        dueTo: error,
                        for: recordId,
                        with: customMessage,
                        in: "findMatchingRecordFor(activity)",
                        methodClass: "CertMediaManager"
                    )//: createLoadFailureLogsAndMessages()
                    self.loadingError = true
                }//: SWITCH
            }//: recordMatchedBlock (closure)
            
            qOperation.queryResultBlock = { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    NSLog(">>> CertMediaManager error: findMatchingRecordFor(activity)")
                    NSLog(">>> The queryResultBlock method returned a Result.failure with the error: \(error.localizedDescription)")
                    self.loadingErrorMessage = "Unable to locate the certificate for the CE \(activity.ceTitle)"
                    self.loadingError = true
                }//: SWITCH
                continuation.resume(returning: matchedRecord)
            }//: queryResultBlock
            
            // Running the query and query operation
            database.add(qOperation)
        }//: CONTINUATION
    }//: findMatchingRecordFor(activity)
    
    /// CertMediaManager helper method that creates a new CertificateModel object based on a CeActivity argument and format
    /// (MediaType) value as part of the initial save process for making a CKRecord and associating a CKAsset with it.
    /// - Parameters:
    ///   - activity: CeActivity that will be assigned a certificate (image/pdf) file
    ///   - certFormat: MediaType enum indicating whether the certificate is an image or pdf
    /// - Returns: CertificateModel initialized with a newly computed relative path for the file, the media format, and the
    /// activityID property for the CeActivity.  All other values are left at default values per the CertificateModel init() method.
    private func createCertModelFor(activity: CeActivity, certFormat: MediaType) -> CertificateModel {
        if let assignedId = activity.activityID {
            let certRelPath = fileSystem.createMediaRelativePath(for: activity, toSave: certFormat, forPrompt: nil)
            let newCertModel = CertificateModel(
                relativePath: certRelPath,
                mediaType: certFormat.rawValue,
                assignedObjectId: assignedId
            )//: newCertModel
            return newCertModel
        } else {
            let newActivityId = UUID()
            activity.activityID = newActivityId
            dataController.save()
            
            let certRelPath = fileSystem.createMediaRelativePath(for: activity, toSave: certFormat, forPrompt: nil)
            let newCertModel = CertificateModel(
                relativePath: certRelPath,
                mediaType: certFormat.rawValue,
                assignedObjectId: newActivityId
            )
            return newCertModel
        }//: IF LET ELSE
    }//: createCertModelFor(activity)
    
    
    
    // MARK: - INIT
    
}//: CLASS
