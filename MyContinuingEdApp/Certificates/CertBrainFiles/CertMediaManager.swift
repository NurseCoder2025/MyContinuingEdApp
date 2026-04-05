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
     
        - nc = NotificationCenter.default
     */
    
    var problemCertRecordFiles: [CKRecord.ID] = []
  
    
    // MARK: - LOADING
    
    func loadAllCertificates() async {
        isLoading = true
        errorMessage = ""
        
        let loadingCompleted = Notification.Name(String.certLoadingDoneNotification)
        nc.removeObserver(self, name: loadingCompleted, object: nil)
        nc.addObserver(
            self,
            selector: #selector(handleCertsLoadingCompleted(_:)),
            name: loadingCompleted,
            object: nil
        )//: addObserver
        
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
        let _ = activity.activityID else {
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
        var newModel = createCertModelFor(activity: activity, inFormat: inFormat)
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
    
    func deleteSavedCertificateFor(activity: CeActivity, asType: MediaClass) async {
        guard let assignedCertificate = activity.certificate,
        let assignedId = activity.activityID else { return } //: GUARD
        
        do {
            try await deleteMediaItem(cat: asType, for: assignedId)
            dataController.delete(assignedCertificate)
            dataController.save()
        } catch {
            NSLog(">>> CertMediaManager error: deleteSavedCertificateFor(activity)")
            NSLog(">>> Unable to find a matching CertificateModel to delete from the mediaFiles set.")
            NSLog(">>> Without the model, the CKRecord cannot be located and removed.")
        }//: DO-CATCH
        
    }//: deleteSavedCertificateFor(activity)
    
    // MARK: - SELECTORS
    
    @objc private func handleCertsLoadingCompleted(_ notification: Notification) {
        Task{
            await saveNewlyDownloadedCerts()
        }//: TASK
    }//: handleCertsLoadingCompleted()
    
    
    
    // MARK: - HELPER METHODS
    private func processCertRecordQueryResults(
        results: [(CKRecord.ID, Result<CKRecord, any Error>)]
    ) {
        var fetchedCerts: [CertificateModel] = []
        let loadedCompleted = Notification.Name(String.certLoadingDoneNotification)
        
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
        
        if problemCertRecordFiles.isNotEmpty {
            loadingError = true
            loadingErrorMessage = "Not all certificates could be loaded. Out of \(recordResultCount) files, \(problemCertRecordFiles.count) could not be loaded.) "
            NSLog(">>> \(loadingErrorMessage)")
        }//: IF (isNotEmpty)
        
        isLoading = false
        Task{@MainActor in
            nc.post(name: loadedCompleted, object: nil)
        }//: MAIN ACTOR
    }//: processCertRecordQueryResults
    
    private func createCertModelFromCkRecord(_ record: CKRecord) -> CertificateModel? {
        if let pathString = record[.relPathKey] as? String,
            let medType = record[.mediaKey] as? String,
            let locName = record[.locationKey] as? String,
            let version = record[.versionKey] as? Double,
            let assocObj = record[.assignedObjectKey] as? UUID,
            let _ = record[.objectIdStringKey] as? String {
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
        guard let _ = activity.certificate,
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
    private func createCertModelFor(
        activity: CeActivity,
        asType: MediaClass = .certificate,
        inFormat certFormat: MediaType
    ) -> CertificateModel
    {
        if let assignedId = activity.activityID {
            let certRelPath = fileSystem.createMediaRelativePath(for: activity, toSave: asType, forPrompt: nil)
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
            
            let certRelPath = fileSystem.createMediaRelativePath(for: activity, toSave: asType, forPrompt: nil)
            let newCertModel = CertificateModel(
                relativePath: certRelPath,
                mediaType: certFormat.rawValue,
                assignedObjectId: newActivityId
            )
            return newCertModel
        }//: IF LET ELSE
    }//: createCertModelFor(activity)
    
    
    private func saveNewlyDownloadedCerts() async {
        guard mediaFiles.isNotEmpty else { return }
        
        var filesToMove: [CertificateModel: URL] = [:]
        for file in self.mediaFiles {
            if let savedRecord = file.cloudRecord, let certFileAsset = savedRecord[.mediaDataKey] as? CKAsset {
                if let assetUrl = certFileAsset.fileURL {
                    if assetUrl.isMediaLocallySavedUrlFor(category: .certificate) {
                        continue
                    } else {
                        filesToMove[file] = assetUrl
                    }//: IF ELSE (.isMediaLocallySavedUrlFor(category)
                }//: IF LET
            }//: IF LET (savedRecord, certFileAsset)
        }//: LOOP
        
        var problemFiles: [CertificateModel] = []
        for (modelKey, urlValue) in filesToMove {
            if let matchedActivity = findMatchingActivityWith(model: modelKey) {
                let basePath: URL = URL.localCertificatesFolder
                var pathToUse: String
                var saveURL: URL
                if modelKey.relativePath.count < 25 {
                    pathToUse = fileSystem.createMediaRelativePath(for: matchedActivity, toSave: .certificate, forPrompt: nil)
                    saveURL = basePath.appending(path: pathToUse, directoryHint: .notDirectory)
                } else {
                    saveURL = modelKey.resolveURL(basePath: basePath)
                }//: IF ELSE
                
                do {
                    try fileSystem.moveItem(at: urlValue, to: saveURL)
                } catch {
                    NSLog(">>> CertMediaManager error: saveNewlyDownloadedCerts()")
                    NSLog(">>> Failed to move the downloaded certificate file: \(urlValue.path) to the local media folder: \(saveURL.path)")
                    NSLog("Error: \(error.localizedDescription)")
                    problemFiles.append(modelKey)
                }//: DO-CATCH
            }//: IF LET (findMatchingActivityWith)
            
            if problemFiles.count > 0 {
                loadingError = true
                loadingErrorMessage = "Unable to save all of the certificates that were previously saved on your other devices. Out of \(filesToMove.count) new certificates to save on this device, \(problemFiles.count) were not saved."
            }//: IF (count > 0)
        }//: LOOP
    }//: saveNewlyDownloadedCerts()
    
    private func findMatchingActivityWith(model: CertificateModel) -> CeActivity? {
        let context = dataController.container.viewContext
        let activityFetch = CeActivity.fetchRequest()
        let searchPredicate: NSPredicate = NSPredicate(format: "%K == %@", #keyPath(CeActivity.activityID), model.assignedObjectId as CVarArg)
        let fetchResults = (try? context.fetch(activityFetch)) ?? []
        guard fetchResults.count == 1, let matchingActivity = fetchResults.first else { return nil }
        
        return matchingActivity
    }//: findMatchingActivityWith(model)
    
    private func deleteCertDataFileUponNotification() {
        guard !dataController.subscribedToMediaDeleteNotifications else { return }//: GUARD
        
        let deletionSubId: String = .mediaDeletionSubscription
        let deletionSubscription = CKDatabaseSubscription(subscriptionID: deletionSubId)
        if let noticeInfo = deletionSubscription.notificationInfo {
            noticeInfo.shouldSendMutableContent = true
        }//: IF LET
        
        
        
        
        
    }//: deleteCertDataFileUponNotification
    
    
    // MARK: - INIT
    
   
    
}//: CLASS
