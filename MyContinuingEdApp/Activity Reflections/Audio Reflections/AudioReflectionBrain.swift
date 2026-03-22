//
//  AudioReflectionBrain.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/12/26.
//

import AVFoundation
import CloudKit
import CoreData
import Foundation
import Speech
import UIKit

final class AudioReflectionBrain: ObservableObject {
    // MARK: - PROPERTIES
    private var coordinatorAccess = ARCoordinatorActor()
    let fileExtension: String = .audioReflectionExtension
    
    // Error handling properties
    @Published var errorMessage: String = ""
    @Published var handlingError: FileIOError = .noError
    
    // MARK: Audio playing properties
    @Published var loadedAudio: [UUID: URL] = [:]
    
    // Transcription monitoring properties
    @Published var audioToBeTranscribed: Bool = false
    @Published var audioTranscriptionFinished: Bool = false
    
    var dataController: DataController
    private let fileSystem = FileManager()
    private let audioQuery = NSMetadataQuery()
    
    // MARK: - FILE STORAGE
    
    /// Computed property in AudioReflectionBrain that indicates whether local or iCloud storage is to
    /// be used for the purpose of creating URLs for audio media files.
    ///
    /// - Note: The data type is the StorageToUse enum and its value depends on
    /// the useLocalStorage computed property of the iCloudAvailability enum.
    var storageAvailability: StorageToUse {
        switch dataController.iCloudAvailability.useLocalStorage {
        case true:
            return .local
        case false:
            return .cloud
        }//: SWITCH
    }//: currentStorageChoice
    
    /// Computed property in AudioReflectionBrain that sets the URL for the top-level directory into which all
    /// audio reflections are to be saved to in iCloud: "Documents/Reflections".  Nil is returned if the url
    /// for the app's directory in the user's iCloud drive account cannot be made.
    var cloudReflectionsFolderURL: URL? {
        if let existingURL = dataController.userCloudDriveURL, dataController.prefersCertificatesInICloud,
            storageAvailability == .cloud {
            let customCloudURL = URL(
                filePath: "Documents/Reflections",
                directoryHint: .isDirectory,
                relativeTo: existingURL
            )
            return customCloudURL
        } else {
            return nil
        }
    }//: cloudCertsURL
    
    // MARK: - COORDINATOR LIST
    
        // MARK: List Sync
    
    /// Private method that ensures the JSON file containing all ARCoordaintor objects is in sync with all files saved both locally and on
    /// iCloud.
    ///
    /// The method first looks for the JSON file on iCloud, and if it exists then those values are decoded to the allCoordinators property.  It then
    /// checks the user's cloud sync preference for certificates and if it is for local storage only, then the JSON file is moved to the local device.
    /// If the file is not on iCloud or it does not contain any data, then the local directory for the JSON file will be checked and, again, if the user's
    /// certificate storage preference is set to iCloud then the file will be moved to iCloud if possible.
    ///
    /// If there are values in the allCoordinators property after the initial file check and decoding, then the method will update it by comparing the
    /// existing set in allCoordinators with the coordinators set returned by the private method getCoordinatorsForAllFiles().  Any new coordinators
    /// will be added to the allCoordinators set.
    ///
    /// If no values are in allCoordinators, then the getCoordinatorsForAllFliles method is called to create coordinator objects for any CE certificates
    /// saved both on iCloud (if available) and on the local device.  Thoe objects are then used to set the value of allCoordinators and it is then
    /// encoded to disk, using the URL returned from the allCoordinatorsListURL computed property.
    ///
    /// Upon completion, this method also creates a custom notification using the String constant certCoordinatorListSyncCompleted and posts it
    /// to the NotificationCenter so that registered observers can take follow-up actions.
    private func syncCoordinatorList() async {
        // Find & retrieve previously saved list, if available
        if let cloudList = coordinatorCloudStoredListURL, let _ = try? Data(contentsOf: cloudList) {
            await decodeCoordinatorList(from: cloudList)
            if dataController.prefersCertificatesInICloud == false {
                moveAudioCoordListTo(location: .local)
            }//: IF (!prefersAudioReflectionsInICloud)
        } else {
            let localList = URL.localAudioCoordinatorsListFile
            if let _ = try? Data(contentsOf: localList) {
                await decodeCoordinatorList(from: localList)
                if dataController.prefersCertificatesInICloud {
                    moveAudioCoordListTo(location: .cloud)
                } //: IF LET
            }//: IF LET
        }//: IF ELSE
        
        let coordinators = await coordinatorAccess.allCoordinators
        // If there are coordinator objects in existence, then sync those objects with
        // the coordinator objects created by the createCoordinatorsForAllAudioReflections()
        if await coordinatorAccess.allCoordinators.isNotEmpty {
            let currentCoordinators = await createCoordinatorsForAllAudioReflections()
            let coordinatorsToRemove = coordinators.subtracting(currentCoordinators)
            let coordinatorsToAdd = currentCoordinators.subtracting(coordinators)
            if coordinatorsToAdd.isNotEmpty {
                let updatedList = coordinators.union(coordinatorsToAdd)
                await coordinatorAccess.setAllCoordinatorsValues(with: updatedList)
            }
            if coordinatorsToRemove.isNotEmpty {
                let updatedList = coordinators.subtracting(coordinatorsToRemove)
                await coordinatorAccess.setAllCoordinatorsValues(with: updatedList)
            }
            await encodeCoordinatorList()
        } else {
            // If no previously saved list, get new coordinator objects,
            // assign them to the allCoordinators list and then write that
            // list to file in the appropriate location.
            let newCoordinators = await createCoordinatorsForAllAudioReflections()
            // TODO: Perform on MainActor??
            await coordinatorAccess.setAllCoordinatorsValues(with: newCoordinators)
            await encodeCoordinatorList()
        }//: IF - ELSE
        
        // Removing all values from the allCloudCoordinators property in
        // coordinatorAccess since they are no longer needed now that all
        // coordinators have been created
        await coordinatorAccess.removeAllCloudCoordinators()
        
        let completedNotice = Notification.Name(.audioCoordinatorListSyncCompleted)
        NotificationCenter.default.post(name: completedNotice, object: nil)
    }//: syncCoordinatorList()
    
        // MARK: HELPERS
    
        /// Private async method that encodes the all ARCoordinator objects into a JSON file and
        /// then writes the file to the url set by the allCoordinatorsListURL computed property.
        /// - Parameters:
        ///     - location: OPTIONAL URL value if a location other than what is computed by the
        ///     allCoordinatorsListURL property is needed
        ///
        /// - Important: This method uses the ARCoordinatorActor in order to prevent data races.
        /// The method must be async for this reason, but runs the error handling block on the main actor.
        private func encodeCoordinatorList(to location: URL? = nil) async {
            let audioCoordinators = await coordinatorAccess.allCoordinators
            guard audioCoordinators.isNotEmpty else { return }
            let encoder = JSONEncoder()
            let encodedList = try? encoder.encode(audioCoordinators)
            if let data = encodedList {
                do {
                    try data.write(to: location ?? allCoordinatorsListURL)
                } catch {
                    await MainActor.run {
                        handlingError = .writeFailed
                        errorMessage = "Encountered an error writing the file that keeps track of where ce certficicates are saved to."
                        NSLog(">>> ARCoordiantor list encoding error:")
                        NSLog(errorMessage)
                    }//: MainActor.run
                }//: DO CATCH
            }//: IF LET
        }//: encodeCoorsinatorList()
    
        /// Private method that decodes and reads the ARCoordinator objects contained within the
        /// JSON file saved at the url set by the allCoordinatorsListURL computed property.
        /// - Parameters:
        ///     - location: OPTIONAL URL if a different location from the one produced by the
        ///     allCoordinatorsListURL property is needed
        ///
        /// - Note: This method assigns the value of the decoded JSON file to the allCoordinators property if there is
        /// anything there and it can be decoded.  If not, then no changes will be made to the allCoordinators property.
        ///
        /// The reason for the optional location argument is due to the fact that if it remains nil then the method will use the
        /// computed property allCoordinatorsListURL to set the URL from which to decode the JSON file.  Depending on the
        /// method this function is being called in, a specific location URL may need to be passed in, so this method can handle
        /// any situation.
        private func decodeCoordinatorList(from location: URL? = nil) async {
            var audioCoordinators = await coordinatorAccess.allCoordinators
            guard audioCoordinators.isEmpty else { return }
                let decoder = JSONDecoder()
                if let specifiedLocation = location, let data = try? Data(contentsOf: specifiedLocation) {
                    audioCoordinators = (try? decoder.decode(Set<ARCoordinator>.self, from: data)) ?? []
                } else {
                    if let data = try? Data(contentsOf: allCoordinatorsListURL) {
                        audioCoordinators = (try? decoder.decode(Set<ARCoordinator>.self, from: data)) ?? []
                    }//: IF LET
                }//: IF - ELSE
            
            if audioCoordinators.isNotEmpty {
                await coordinatorAccess.setAllCoordinatorsValues(with: audioCoordinators)
            }//: IF
        }//: decodeCoordinatorList()
        
        /// Private method which moves the audio reflection coordinator JSON file from local storage to the app's
        /// ubiquity container in iCloud.
        /// - Parameters:
        ///     - location: SaveLocation enum value indicating whether the list should be moved to iCloud or
        ///     local device
        ///
        /// - Dependencies:
        ///     - URL.localAudioCoordinatorsListFile static property
        ///     - cloudCertsFolderURL computed property
        ///     - allCoordinatorsListURL computed property
        private func moveAudioCoordListTo(location: SaveLocation) {
            switch location {
            case .local:
                guard let cloudList = coordinatorCloudStoredListURL,
                    let _ = try? Data(contentsOf: cloudList) else {
                    handlingError = .unableToMove
                    errorMessage = "Unable to transfer audio reflection related data to your device."
                    NSLog(">>>Conditions needed to move the audio reflection coordinator list to a local device were not met, so moveAudioCoordListTo(location) method returned. Possible causes include a nil value for the coordinatorCloudStoredListURL and/or no actual data from the URL.")
                    return
                    }//: GUARD
                
            // Moving coordinator list from iCloud to local device
               Task.detached {
                    do {
                        try self.fileSystem.setUbiquitous(
                            false, itemAt: cloudList,
                            destinationURL: URL.localAudioCoordinatorsListFile
                        )
                    } catch {
                        self.handlingError = .unableToMove
                        self.errorMessage = "Encountered an error when trying to move audio reflection related data from iCloud to the local device."
                        NSLog(">>>Error: the Task.detached for moving the audio reflection coordinator list from iCloud to a local device failed becuase the setUbiquitous method threw an error.")
                    }//: DO - CATCH
                }//: TASK
                
                
            case .cloud:
                let savedCoordList = try? Data(contentsOf: URL.localAudioCoordinatorsListFile)
                guard let _ = savedCoordList,
                    dataController.iCloudAvailability.useLocalStorage == false,
                   let _ = cloudReflectionsFolderURL
                else {
                    handlingError = .unableToMove
                    errorMessage = "Unable to transfer audio reflection related data to iCloud."
                    NSLog(">>>Conditions needed to move the audio reflection coordinator list to iCloud were not met, so moveAudioCoordListTo method returned. Possible causes include a nil value for the coordinatorCloudStoredListURL and/or no actual data from the URL.")
                    return
                }//: GUARD
                
                    // Moving coordinator list to iCloud
                    Task.detached {
                        do {
                            try self.fileSystem.setUbiquitous(
                                true,
                                itemAt: URL.localAudioCoordinatorsListFile,
                                destinationURL: self.allCoordinatorsListURL
                            )
                        } catch {
                            self.handlingError = .unableToMove
                            self.errorMessage = "Encountered an error when trying to move audio reflection related data from the local device to iCloud."
                            NSLog(">>>Error: setUbiquitous method threw an error when trying to move the audio reflection coordinator list from the local device to iCloud.")
                        }
                    }//: TASK (detached)
            case .unknown:
                handlingError = .unableToMove
                errorMessage = "Unable to move audio reflection related data to a different location on disk."
                NSLog(">>> Invalid SaveLocation passed to moveAudioCoordlistTo(location).  The 'unknown' value was used but only cloud or local are valid.")
            }//: SWITCH
           
        }//: moveLocalCoordListToICloud()
    
        /// Private method in AudioReflectionBrain that searches the local app sandbox (documentsDirectory/Reflections)
        /// and creates a new set of ARCoordinator objects for each which is then used to set the value
        /// of the allCoordinators property in the coordinatorAccess actor, along with any values in the allCloudCoordinators property.
        /// - Returns:
        ///     - Set of CertificateCoordinator objects for every valid URL in the app's reflections iCloud folder and local device folder
        ///
        /// - Important: The allCloudCoordinators property must be set before this method is called; otherwise, only
        /// coordinator objects for locally saved certificates will be returned.  The handling of allCloudCoordinators is handled by
        /// the private startICloudCertSearch method.
        private func createCoordinatorsForAllAudioReflections() async -> Set<ARCoordinator>{
            var createdCoordinators: Set<ARCoordinator> = []
            let localURL = URL.documentsDirectory
            var localFiles: [URL] = []
            var problemFiles: [URL] = []
            
            localFiles = (
                try? fileSystem.getAllSavedMediaFileURLs(
                    from: localURL,
                    with: fileExtension
                )) ?? []
          
            // Iterating through all locally saved certificates to create new coordinators
            // for each
            for file in localFiles {
                let savedAudio = await ARDocument(audioURL: file)
                if await savedAudio.open() {
                    let audioMeta = await savedAudio.audioMetadata
                    let newCoord = ARCoordinator(fileURL: file, mediaMetadata: audioMeta)
                    createdCoordinators.insert(newCoord)
                } else {
                    NSLog(">>>Error trying to open a ARDocument while iterating through all locally saved audio reflection files. The specific doc that failed to open is at this url: \(file.absoluteString)")
                    problemFiles.append(file)
                }//: IF await (open)
            }//: LOOP
            
            if problemFiles.isNotEmpty {
                await MainActor.run {
                    handlingError = .syncError
                    errorMessage = "It appears that not all of the files contained with the Reflections folder were actual reflection files (\(fileExtension)). Please use the Files app or Finder to check and move any non-reflection files out of the folder."
                    }//: MAIN ACTOR
                NSLog(">>>Error encountered with pulling meta data from local files.  Out of the total number of files, \(localFiles.count), \(problemFiles.count) were not valid reflections.")
            }//: IF (isNotEmpty)
            
            
            let cloudFileCoordinators = await coordinatorAccess.allCloudCoordinators
            cloudFileCoordinators.forEach { coordinator in
                createdCoordinators.insert(coordinator)
            }//: closure
            
            return createdCoordinators
        }//: getCoordinatorsForAllFiles()
    
        /// Private  method that returns a Set of ARCoordinator objects that correspond to a URL that is at the save location as specified
        /// by the savedAt argument value.
        /// - Parameter savedAt: Either .local or .cloud enum value for SaveLocation enum type
        /// - Returns: Set of ARCoordinator objects which contain URLs that are at the specified location (device or iCloud)
        ///
        /// This method essentially filters the allCoordinators property using the mediaMetaData property of each coordinator object to retrieve
        /// the whereSaved property from the ARMetadata object contained within it.
        private func getCoordinatorsForFiles(savedAt: SaveLocation) async -> Set<ARCoordinator> {
            _ = await coordinatorAccess.allCoordinators
            if await coordinatorAccess.allCoordinators.isEmpty { await decodeCoordinatorList() }
        
                var fileCoordinators: Set<ARCoordinator> = []
                
                fileCoordinators = await coordinatorAccess.getCoordinatorsForLocation(savedAt)
                
                return fileCoordinators
            }//: getCoordinatorsForFiles
    
        // MARK: Computed LIST Properties
    
        /// Computed property in AudioReflectionBrain that sets the URL for the top-level directory into which the
        /// audio reflection coordinator JSON file will be saved to.
        ///
        /// If the storageAvailability is .local, the user's ubiquitiy container's URL can be obtained, AND
        /// if the user wishes to save audio reflections in iCloud, then the following
        /// will be appended to it:  ApplicationSupport/[String's audioCoordinatorListFile static property].
        /// Otherwise, the URL will be set to the .localAudioCoordinatorsListFile property of String.
        ///
        /// - Note: Even if all 3 conditions are met for creating an iCloud URL, if the user's iCloud storage
        /// has been maxed out, then ultimately the methods that call this property will end up throwing
        /// an error.  However, in the catch blocks of those methods the FileIOError enum case
        /// "saveLocationUnavailable" will be set for the handlingError property of the AudioReflectionBrain
        /// class along with a custom error message that will advise the user to check both their iCloud settings
        /// and storage capacity remaining.
        var allCoordinatorsListURL: URL {
            if dataController.prefersCertificatesInICloud,
                storageAvailability == .cloud,
                let cloudDrive = cloudReflectionsFolderURL {
                let coordinatorURL = URL(
                    filePath: "ApplicationSupport/\(String.audioCoordinatorListFile)",
                    directoryHint: .notDirectory,
                    relativeTo: cloudDrive
                 )
                return coordinatorURL
            } else {
                return URL.localAudioCoordinatorsListFile
            }
        }//: allCoordinatorsListURL
    
        /// Private computed property in AudioReflectionBrain that returns the iCloud-based URL for the
        /// coordinator JSON file IF it can be obtained.  Nil if not.
        ///
        /// The path for the file is: .\ApplicationSupport\[String.audioCoordinatorListFile] for
        /// whatever ubiquity container is associated with the current Apple Account.
        private var coordinatorCloudStoredListURL: URL? {
            if let cloudDrive = dataController.userCloudDriveURL {
                let coordinatorURL = URL(
                    filePath: "ApplicationSupport/\(String.audioCoordinatorListFile)",
                    directoryHint: .notDirectory,
                    relativeTo: cloudDrive
                 )
                return coordinatorURL
            } else {
                return nil
            }
        }//: coordinatorCloudStoredListURL
    
    
    // MARK: - SAVING REFLECTIONS
    
    /// Method for creating and saving audio reflections in the app.
    /// - Parameters:
    ///   - activity: CeActivity object for which the user is reflecting on
    ///   - data: raw, binary audio data
    ///   - dataType: MediaType enum indicating that the data is audio
    ///
    ///   This method first creates and saves the ARDocument to local storage, but if iCloud is available and the user wishes
    ///   to utilize it, then the document file is moved to iCloud.  If an issue arises with saving to iCloud because the iCloud url can't
    ///   be obtained, then the method updates the AudioReflectionBrain''s handlingError and errorMessage properties so the user
    ///   can be alerted.
    func saveNewAudioReflection(
        for response: ReflectionResponse,
        with data: Data,
        promptUsed: ReflectionPrompt,
        recordingInfo: Recording
    ) async throws {
        let saveCompletedNotification = Notification.Name(.audioSaveCompletedNotification)
        // 1. Create metadata using activity
        let tempFileVersion = MediaFileVersion(fileAt: URL.localAudioReflectionsFolder, version: 1.0)
        var audioMetadata = createAudioReflectionMetadata(forResponse: response, version: tempFileVersion, withPrompt: promptUsed)
        
        // 2. Create the local url for saving
        let localURL = createDocURL(with: audioMetadata, for: .local)
        #if DEBUG
            print(">>> Full URL created for audio reflection: \(localURL.absoluteString)")
            print(">>> Local URL: \(localURL.lastPathComponent)")
        #endif
        let updatedVersion = MediaFileVersion(fileAt: localURL, version: 1.0)
        audioMetadata.fileVersion = updatedVersion
        
        // 3. Create the coordinator object with url and metadata
        if await coordinatorAccess.allCoordinators.isEmpty { await decodeCoordinatorList() }
        var newCoordinator = createARCoordinator(with: audioMetadata, fileAt: localURL)
        
        // 4. Create a new ARDocument instance with the url, meta data, and data
        let newReflectionDoc = await ARDocument(
            audioURL: localURL,
            metaData: audioMetadata,
            withData: data,
            recordingInfo: recordingInfo
        )
        
        #if DEBUG
        NSLog(">>> Data size: \(data.count) bytes")
        NSLog(">>> Saving to URL: \(localURL.lastPathComponent)")
        
        let testData = "Test data".data(using: .utf8)!
        do {
            try testData.write(to: URL.localAudioReflectionsFolder.appending(path: "test.txt", directoryHint: .notDirectory))
            NSLog(">>> Test save successful")
        } catch {
            NSLog(">>> Test save failed: \(error.localizedDescription)")
        }
        #endif
        
        // 5. Save CertificateDocument to disk locally
        if await newReflectionDoc.save(to: localURL, for: .forCreating) {
                Task{@MainActor in
                    response.hasAudioReflection = true
                    dataController.save()
                }//: TASK
            } else {
                NSLog(">>>Error saving ARDocument to the local url: \(localURL)")
                NSLog(">>>Exiting the saveNewAudioREflection(for) method early without attempting to save to iCloud.")
                handlingError = .writeFailed
                errorMessage = "Failed to save the audio reflection to your device. Please try again."
                throw handlingError
            }//: IF ELSE
   
        
        // 6. If the user wishes to save media files to iCloud and iCloud is available, move
        // file to iCloud/UserUbqiquityURL/Documents/Certificates
        guard dataController.prefersAudioReflectionsInICloud,
              storageAvailability == .cloud,
              let _ = cloudReflectionsFolderURL else {
            if dataController.prefersAudioReflectionsInICloud {
                await MainActor.run {
                    // In this situation, the user wants to save audio reflections
                    // to iCloud but can't do so for one of several possible
                    // reasons, including a completely full drive, iCloud
                    // Drive turned off, etc.
                    handlingError = .saveLocationUnavailable
                    errorMessage = "The app is currently set to save audio reflections to iCloud, but, unfortunately, iCloud cannot be used at this time. Please check your iCloud/iCloud drive settings as well as how much available free space is on the drive for your account. The audio reflection was saved locally to the device."
                }//: MAIN ACTOR
                await coordinatorAccess.insert(coordinator: newCoordinator)
                await encodeCoordinatorList()
                throw handlingError
            } else {
                // In this situation, the user has indicated that CE certificates are to be saved to
                // the local device only via the control in Settings
                await coordinatorAccess.insert(coordinator: newCoordinator)
                await encodeCoordinatorList()
            }//: IF - ELSE
                return
            }//: GUARD
        
            let iCloudURL = createDocURL(with: audioMetadata, for: .cloud)
                // Moving the file to iCloud, and if successful, updating the coordinator object
                // before inserting it into the list and writing the updated list to disk.
                do {
                   try self.fileSystem.setUbiquitous(true, itemAt: localURL, destinationURL: iCloudURL)
                    newCoordinator.fileURL = iCloudURL
                    await coordinatorAccess.insert(coordinator: newCoordinator)
                    await encodeCoordinatorList()
                } catch {
                    // Updating published properties on the MainActor
                    await MainActor.run {
                        handlingError = .saveLocationUnavailable
                        errorMessage = "Attempted to save the audio reflection to iCloud but was unable to do so. Please check your iCloud/iCloud drive settings as well as how much available free space is on the drive for your account. The file was saved locally to the device."
                    }//: MAIN ACTOR
                    await coordinatorAccess.insert(coordinator: newCoordinator)
                    await encodeCoordinatorList()
                    throw handlingError
                }//: DO-CATCH
                
                // If the file was moved successfully and no errors were thrown, then update the
                // metadata for the file, then post the notification that the move is complete.
                do {
                    try await updateARDocMetaAfterMove(to: .cloud, at: iCloudURL)
                   
                    Task {@MainActor in
                        NotificationCenter.default.post(name: saveCompletedNotification, object: nil)
                    }//: TASK
                } catch {
                    NSLog(">>>Error trying to update the metadata for an ARDocument that was successfully moved to iCloud. The whereSaved property is still set to .local")
                    NSLog(">>> The url for the moved reflectoin is: \(iCloudURL.absoluteString)")
                }//: DO-CATCH
        
    }//: addNewCeCertificate()
    
    func saveAudioReflectionWithoutTranscription(
        for response: ReflectionResponse,
        with data: Data,
        promptUsed: ReflectionPrompt
    ) async {
        do {
            let recordingFiller = Recording.example
            try await saveNewAudioReflection(for: response, with: data, promptUsed: promptUsed, recordingInfo: recordingFiller)
        } catch {
            NSLog(">>>Error saving audio reflection: \(errorMessage)")
        }//: DO-CATCH
    }//: saveAudioReflectionWithoutTranscription()
    
        // MARK: SAVE HELPERS
    
        /// Private method that creates the filename string to be used for the last URL path component for an audio reflection document.
        /// - Parameter metaData: ARMetadata object associated with the audio reflection
        /// - Returns: String value using the prompt question (trimmed) from the metadata OR "UnspecifiedPrompt" if no question
        ///
        /// - Important: This method only creates the final part of the URL for audio reflection documents.  It is important that a prompt
        /// question is present in the metadata in order for the filename to reflect the question being answered.
        private func createAudioReflectionFileName(using metaData: ARMetadata) -> String {
            let trimmedPrompt = metaData.promptQuestion.trimWordsTo(length: 35)
            if trimmedPrompt.isEmpty {
                return "UnspecifiedPrompt_Response.\(fileExtension)"
            } else {
                return String(trimmedPrompt + "_Response.\(fileExtension)")
            }//: IF ELSE
        }//: createAudioReflectionFileName(for, with)
    
    
        /// Private function that creates the URL for a given AudioReflection object to be saved to.
        /// - Parameters:
        ///     - metaData: ARMetadata object that has the assignedObjectId for the ReflectionResponse the
        /// audio was recorded for
        ///     - saveLocale: SaveLocation enum indicating whether the URL to be created is for local storage or iCloud
        /// - Returns: URL (non-optional) for saving the AudioReflection object to the specified url location
        ///
        ///- Important: If creating an AudioReflection for the first time, please use the .local SaveLocation value FIRST
        /// to save the data locally, and then call this method a second time for moving it to iCloud.  If the URL for the iCloud ubiquity container
        /// remains nil at the time this function is called, then be aware that a local url will be created.
        ///
        /// The way the URL is created by this function can be broken down into three main possible formats:
        ///     - Matching CeActivity without a title (unlikely but possible):  .\Reflections\CeCompleted_01-01-2026_\PromptQuestion-trimmed_Response.refl
        ///     - Matching CeActivity: .\Reflections\CE_activity's_title_trimmed\PromptQuestion-trimmed_Response.refl
        ///     - No corresponding prompt: .\Reflections\CE_activity's_title_trimmed\UnspecifiedPrompt_Response.refl
        ///
        /// The parent directory for the URL created is either the documents directory for local devices, or if using iCloud, the iCloud ubiquity
        /// container URL (as stored in the DataController's userCloudDriveURL property) along with the Documents folder for that URL.
        private func createDocURL(with metaData: ARMetadata, for saveLocale: SaveLocation) -> URL {
            let topFolderURL: URL
            
            switch saveLocale {
            case .local:
                topFolderURL = URL.localAudioReflectionsFolder
            case .cloud:
                if let cloudURL = cloudReflectionsFolderURL {
                    topFolderURL = cloudURL
                } else {
                    topFolderURL = URL.localAudioReflectionsFolder
                }
            case .unknown:
                NSLog(">>> The unknown SaveLocation value was passed in as an argument to the createDocURL method. Using the local folder URL as default in this instance.")
                topFolderURL = URL.localAudioReflectionsFolder
            }//: SWITCH
            
            let topFolderExists = (try? fileSystem.doesFolderExistAt(path: topFolderURL)) ?? false
            if topFolderExists {
                if let assignedActivity = matchAudioReflectionWithActivity(using: metaData) {
                    let audioFileName = createAudioReflectionFileName(using: metaData)
                    
                    // Creating a folder with the activity's name IF a matching one was found
                    let activityFolderName = fileSystem.createActivitySubFolderName(for: assignedActivity)
                    let activityFolderURL = topFolderURL.appending(path: activityFolderName, directoryHint: .isDirectory)
                    let activityFolderExists = (try? fileSystem.doesFolderExistAt(path: activityFolderURL)) ?? false
                    
                    if activityFolderExists {
                        // If the top-level folder and sub-folders were created and can be accessed, save the
                        // reflection to the subfolder with the name created by the createAudioReflectionFileName
                        return activityFolderURL.appending(path: audioFileName, directoryHint: .notDirectory)
                    } else {
                        // If the activity sub-folder cannot be created for whatever reason, save the file in the
                        // respective top-level folder ("Reflections")
                        NSLog(">>>Error creating the activity sub-folder, so saving audio reflection to the top-level 'Reflections' folder.")
                        NSLog(">>>Activity: \(assignedActivity.ceTitle)")
                        return topFolderURL.appending(path: audioFileName, directoryHint: .notDirectory)
                    }//: IF ELSE (activityFolderExists)
                } else {
                    // Audio reflections that do not have an assigned CeActivity (unlikely but potential scenario)
                    // Saving them to the main Reflections directory ("Reflections") for the app
                    NSLog(">>>Saving an audio reflection that has no matching CeActivity.")
                    let audioFileName = createAudioReflectionFileName(using: metaData)
                    return topFolderURL.appending(path: audioFileName, directoryHint: .notDirectory)
                }//: IF ELSE (let assignedActivity)
            } else {
                // If the "Reflections" folder cannot be created, then set the URL for a certificate
                // using the Documents folder instead.
                let audioFileName = createAudioReflectionFileName(using: metaData)
                switch saveLocale {
                case .local:
                    return URL.documentsDirectory.appending(path: audioFileName, directoryHint: .notDirectory)
                case .cloud:
                    if let cloudURL = dataController.userCloudDriveURL {
                        let cloudDocsFolder = URL(
                            filePath: "Documents",
                            directoryHint: .isDirectory,
                            relativeTo: cloudURL
                        )//: cloudDocsFolder
                        let cloudDocsExists = (try? fileSystem.doesFolderExistAt(path: cloudDocsFolder)) ?? false
                        if cloudDocsExists {
                            return cloudDocsFolder.appending(path: audioFileName, directoryHint: .notDirectory)
                        } else {
                            // Save certificate to the app's ubiquity container top-level directory if
                            // the Documents folder is not available (can't be created)
                            NSLog(">>>Unable to find/create Documents folder in the app's ubiquity container. Saving audio reflection to the top-level directory of the ubiquity container.")
                            return cloudURL.appending(path: audioFileName, directoryHint: .notDirectory)
                        }//: IF - ELSE (cloudDocsExists)
                    } else {
                        // If the iCloud ubiquity container URL cannot be retrieved, then set the URL
                        // to the local device
                        NSLog(">>>Error trying to save certificate to iCloud due to the ubiquity container URL being a nil value at this time. Saving to the local device's Documents folder.")
                        return URL.documentsDirectory.appending(path: audioFileName, directoryHint: .notDirectory)
                    }//: IF - ELSE (cloudURL)
                case .unknown:
                    NSLog(">>> Because the unknown SaveLocation value was passed in, the audio file will be saved to the local device's Documents folder.")
                    return URL.documentsDirectory.appending(path: audioFileName, directoryHint: .notDirectory)
                }//: SWITCH
            }//: IF ELSE (topFolderExists)
        }//: createDocURL
    
        /// Method for creating ARMetadata objects based on the ReflectionResponse object for which the certificate was earned.
        /// - Parameters:
        ///   - response: ReflectionResponse object containing the prompt that the user is responding to
        ///   - version: MediaFileVersion with the URL and version number for the file
        ///   - withPrompt: ReflectionPrompt object representing the question being responded to by the user
        ///   - withData: Recording object that contains the transcription of the audio as well as other details
        /// - Returns: ARMetadata object with properties set
        ///
        /// - Note: If the ReflectionResponse argument happens to not have an id property set, then this method will create
        /// a new UUID value, assign it to the object, and then call the DataController's save method to save the context prior
        /// to creating and returning the new ARMetadata object.
        private func createAudioReflectionMetadata(
            forResponse response: ReflectionResponse,
            version: MediaFileVersion,
            withPrompt: ReflectionPrompt,
        ) -> ARMetadata {
            var metaObjectID: UUID = UUID()
                if let reflectionID = response.id {
                    metaObjectID = reflectionID
                } else {
                    NSLog(">>> Assigning new UUID to ReflectionResponse that does not have a previously assigned UUID.")
                    response.id = metaObjectID
                    dataController.save()
                }// IF ELSE (let assignedID)
                
                if let promptQuestion = withPrompt.question {
                    let newMetadata = ARMetadata(
                        forResponseId: metaObjectID,
                        fileVersion: version,
                        prompt: promptQuestion,
                    )
                    return newMetadata
                } else {
                    NSLog(">>> No prompt string available for ReflectionPrompt passed into the createAudioReflectionmetadata method. Using placeholder text instead.")
                    NSLog(">>> Is ReflectionPrompt a user-created one: \(withPrompt.customYN)")
                    let noQuestionText = "No prompt available for this response."
                    let newMetadata = ARMetadata(
                        forResponseId: metaObjectID,
                        fileVersion: version,
                        prompt: noQuestionText,
                    )
                    return newMetadata
                }//: IF ELSE
            }//: createAudioReflectionMetadata
    
        /// Private method that creates and returns an ARCoordinator object as part of the new audio reflection document creation and saving.
        /// - Parameter metaData: ARMetadata object for the certificate
        /// - Returns: ARCoordinator with the local URL that the data is saved to first along with the meta data
        ///
        /// - Note: If saving the certificate document to iCloud, the save method will handle that process as Apple recommends first saving the data
        /// to local disk prior to saving to iCloud.  Once the file is moved, the coordinator's file url property can be updated.
        private func createARCoordinator(with metaData: ARMetadata, fileAt location: URL) -> ARCoordinator {
            return ARCoordinator(fileURL: location, mediaMetadata: metaData)
        }//: createARCoordinator(with, fileAt)
    
    // MARK: - LOADING AUDIO REFLECTIONS
    
    /// Method for opening an existing audio reflection file that has been saved and storing the
    /// audio data  for use in the user interface via writing the data to the temporary directory.
    /// - Parameter response: ReflectionResponse containing the prompt that the audio was recorded for
    ///
    /// Because UIDocuments are used for storing audio reflections, and because the ReflectionResponse user interface may potentially
    /// show a number of prompts  this method copies the raw audio data into the
    /// temporaryDirectory.  This ensures that the loaded data is not overridden by mistake by other
    /// ReflectionResponse objects on the same screen.
    /// - Note: The transcription for the audio was previously saved to the ReflectionResponse's answer property within the
    /// transcribeRecording method, so it can be accessed directly via CoreData.
    func loadSavedAudioReflection(for response: ReflectionResponse) async throws {
        guard response.hasAudioReflection else { return }
        let loadCompletedNotification = Notification.Name(.audioLoadingDoneNotification)
       
        guard let audioCoordinator = await findMatchingCoordinatorFor(response: response)
        else {
            await MainActor.run {
                handlingError = .loadingError
                errorMessage = "Unable to load the audio reflection data because the app was unable to locate where the data was saved to."
            }//: MAIN ACTOR
            throw handlingError
        }//: GUARD
        
        let savedAudio = await ARDocument(audioURL: audioCoordinator.fileURL)
        if await savedAudio.open() {
            let audioData = await savedAudio.audioBinaryData
            let audioRecording = await savedAudio.audioRecordingInfo
            // Loading the actual audio data to a temp directory for playing later at the user's discretion
            if let rawAudio = audioData.audioReflectionData {
                
                let audioPlayingURL: URL = URL.temporaryDirectory.appending(path: audioRecording.fileName, directoryHint: .notDirectory)
                let audioPlayerData: Data = Data(rawAudio)
                
                do {
                    try audioPlayerData.write(to: audioPlayingURL)
                    if let responseID = response.id {
                        loadedAudio[responseID] = audioPlayingURL
                    }//: IF LET
                } catch {
                    NSLog(">>> Error writing audio reflection data to the temporary directory.")
                    NSLog(">>> URL used for saving: \(audioPlayingURL.absoluteString)")
                    handlingError = .writeFailed
                    errorMessage = "Unable to load the audio data for playing on the device."
                    throw handlingError
                }//: DO-CATCH
            }//: IF LET
            await savedAudio.close()
            NotificationCenter.default.post(name: loadCompletedNotification, object: nil)
        } else {
            await MainActor.run {
                handlingError = .loadingError
                errorMessage = "Unable to load the audio data from the saved file location."
            }//: MAIN ACTOR
            NSLog(">>>Error opening ARDocument at \(audioCoordinator.fileURL)")
            throw handlingError
        }//: IF - ELSE (open)
    }//: loadSavedCertificate
    
    // MARK: - DELETING REFLECTIONS
    
    /// Method for permanately deleting a saved audio reflection for a specific ReflectionResponse object.
    /// - Parameter activity: ReflectionResponse object that has an audio reflection the user wishes to remove
    ///
    /// This method uses the AudioReflectionBrain's allCoordinators property for finding the url of the reflection data to
    /// remove. If a matching coordinator object cannot be returned or if the removeItem(at) method throws an error, the user
    /// will be presented with a custom error message letting them know that they may need to delete the reflection
    /// data manually (based on the class handlingError and errorMessage values).
    func deleteAudioReflection(for response: ReflectionResponse) async throws {
        guard let audioCoordinator = await findMatchingCoordinatorFor(response: response) else {
            await MainActor.run {
                handlingError = .unableToDelete
                errorMessage = "Unable to delete the audio reflection as the app was unable to locate where the data was saved. Try using the Files app or Finder to manually remove the file."
            }//: MAIN ACTOR
            NSLog(">>>Error while attempting to delete audio reflection due to a missing coordinator for the specified activity.")
            throw handlingError
        }//: GUARD
        
        do {
            try fileSystem.removeItem(at: audioCoordinator.fileURL)
            await coordinatorAccess.removeCoordinator(audioCoordinator)
            await encodeCoordinatorList()
            Task{@MainActor in
                response.hasAudioReflection = false
                dataController.save()
            }//: TASK
        } catch {
            await MainActor.run {
                handlingError = .unableToDelete
                errorMessage = "Unable to delete the audio reflection at the specified save location. You may need to manually delete it using the Files app or Finder."
            }//: MAIN ACTOR
            NSLog(">>>Error while attempting to delete an audio reflection at \(audioCoordinator.fileURL).")
            throw handlingError
        }//: DO-CATCH
    }//: deleteAudioReflection(for)
    
    
    // MARK: - MOVING REFLECTIONS
    
    private func moveSavedAudioReflection(
        using coordinator: ARCoordinator,
        to newLocation: URL,
        from currentLocale: SaveLocation
    ) async throws {
        let originalLocation = coordinator.fileURL
        if let audioMeta = coordinator.mediaMetadata as? ARMetadata, currentLocale != .unknown {
            
                do {
                    try self.fileSystem.setUbiquitous(
                        (currentLocale == .cloud) ? true : false,
                        itemAt: originalLocation,
                        destinationURL: newLocation
                    )//: setUbiquitous
                    
                    try await updateARDocMetaAfterMove(to: currentLocale, at: newLocation)
                    
                    // Creating a new ARCoordinator object to replace the old one
                    // because the object is a struct and can't be modified
                    let newVersion = MediaFileVersion(fileAt: newLocation, version: 1.0)
                    let assignedResponseId = audioMeta.assignedObjectId
                    let savedPrompt = audioMeta.promptQuestion
                    let newMetadata = ARMetadata(forResponseId: assignedResponseId, fileVersion: newVersion, prompt: savedPrompt)
                    
                    let newCoordinator = ARCoordinator(fileURL: newLocation, mediaMetadata: newMetadata)
                    
                    await coordinatorAccess.removeCoordinator(coordinator)
                    await coordinatorAccess.insert(coordinator: newCoordinator)
                    await encodeCoordinatorList()
                } catch {
                    await MainActor.run {
                        handlingError = .unableToMove
                    }//: MAIN ACTOR
                    switch currentLocale {
                    case .local:
                        await MainActor.run {
                            errorMessage = "Unable to move audio reflection file to your local device."
                        }//: MAIN ACTOR
                        NSLog(">>>Error while trying to move an audio reflection saved in iCloud to the local device. From \(originalLocation) to \(newLocation)")
                        throw handlingError
                    case .cloud:
                        await MainActor.run {
                            errorMessage = "Unable to move audio reflection to iCloud."
                        }//: MAIN ACTOR
                        NSLog(">>>Error while trying to move a local audio reflection file to the user's iCloud container. From \(originalLocation) to iCloud: \(newLocation)")
                        throw handlingError
                    case .unknown:
                        NSLog(">>> Error trying to move a certificate whose current URL cannot be identified as either on-device or on iCloud (.unknown).")
                        NSLog(">>> Current URL for audio file is: \(originalLocation.absoluteString)")
                        errorMessage = "Unable to move audio reflection data."
                        throw handlingError
                    }//: SWITCH
                    
                }//: DO - CATCH
        } else {
            await MainActor.run {
                handlingError = .unableToMove
                errorMessage = "Unable to move the specified audio reflection file as the metadata indicates it is actually not an audio reflection file."
            }//: MAIN ACTOR
            throw handlingError
        }//: IF ELSE
    }//: moveSavedAudioReflection(using, to, from)
    
        // MARK: MOVE HELPERS
    
        /// Private method that updates the metadata for an audio reflection document after it has been moved to a new URL for whatever reason.
        /// - Parameters:
        ///   - newLocation: SaveLocation enum indicating if the new URL is a local or iCloud location
        ///   - newLocURL: URL for the new save location
        ///   - versionToUse: Double representing the file version number to update the fileVersion property with, if different from the default
        ///   value of 1.0
        private func updateARDocMetaAfterMove(
            to newLocation: SaveLocation,
            at newLocURL: URL,
            versionToUse: Double = 1.0
        ) async throws {
            let newVersion = MediaFileVersion(fileAt: newLocURL, version: versionToUse)
            let movedARDoc = await ARDocument(audioURL: newLocURL)
            
            if await movedARDoc.open() {
                var metaFile = await movedARDoc.audioMetadata
                metaFile.fileVersion = newVersion
            } else {
                NSLog(">>>Error opening the ARDocument at the new URL: \(newLocURL.absoluteString)")
                await MainActor.run {
                    handlingError = .loadingError
                }//: MAIN ACTOR
                throw handlingError
            }//: IF ELSE (open)
            
           await movedARDoc.close()
        }//: updateARDocMetaAfterMove()
    
    
    // MARK: - iCLOUD
    
        // MARK: iCloud Query
    
        /// Private method that initalizes the process for searching for all audio reflection objects saved in the user's iCloud container for the app.
        ///
        /// This method does the following:
        ///     - Sets the properties for the search using the NSMetadataQuery class instance
        ///     - Creates the two required observers for the search
        ///     - Starts the query
        ///
        /// Upon search completion, the observer receiving the query completion notification will then run the private cloudCertSearchFinished
        /// method, which will update the allCloudCoordinators property with whatever objects it was able to find.
        private func startICloudAudioReflectionsSearch() {
            let searchPredicate = NSPredicate(format: "%K LIKE '*.refl'", NSMetadataItemFSNameKey)
            let cloudSearchScope = NSMetadataQueryUbiquitousDocumentsScope
            
            NotificationCenter.default.addObserver(
                forName: .NSMetadataQueryDidUpdate,
                object: audioQuery,
                queue: .main,
                using: audioReflectionsChanged
            )//: OBSERVER
            
            NotificationCenter.default.addObserver(
                forName: .NSMetadataQueryDidFinishGathering,
                object: audioQuery,
                queue: .main,
                using: cloudARSearchFinished
            )//: OBSERVER
            
            audioQuery.predicate = searchPredicate
            audioQuery.searchScopes = [cloudSearchScope]
            audioQuery.start()
            
        }//: startICloudAudioReflectionsSearch()
        
        // MARK: QUERY Observer Methods
    
        /// Observer method that simply logs whenever a batch of query results is completed and the notification is sent by
        /// the system.
        /// - Parameter notification: Notification from observer (in this case, NSMetadataQueryDidUpdate)
        private func audioReflectionsChanged(_ notification: Notification) {
            NSLog(">>> Audio reflections list updated")
        }//: audioReflectionsChanged
    
        /// Private observer method that calls the cloudARSearchEndedHandler in a detached Task
        /// - Parameter notification: Notification object with the name "NSMetadataQueryDidFinishGathering"
        private func cloudARSearchFinished(_ notification: Notification) {
            Task.detached {
                await self.cloudARSearchEndedHandler()
            }//: TASK
        }//: cloudARSearchFinished
    
        /// Private method  called by cloudARSearchFinished that fills the allCloudCoordinators property
        /// with ARCoordinator objects whenever the audioQuery observer gets notified that the query has been completed.
        ///
        /// - Note: This method is called  within a Task due to the observer requiring a synchronous method.
        ///
        /// Upon completion:
        ///     - The query observers created in startICloudAudioReflectionsSearch() are removed in this method.
        ///     - The set of audio reflection coordinators made for all cloud-based URLs are assigned to the
        ///     allCloudCoordinators property
        ///     - The coordinator JSON file is then updated with the syncCoordinatorList method
        private func cloudARSearchEndedHandler() async {
            audioQuery.stop()
            
            var cloudCoordinators = Set<ARCoordinator>()
            var problemFiles: [URL] = []
            
            let foundCertCount = audioQuery.resultCount
            for item in 0..<foundCertCount {
                let resultItem = audioQuery.result(at: item)
                if let audioReflectionResult = resultItem as? NSMetadataItem,
                   let audioURL = audioReflectionResult.value(forAttribute: .resultURL) as? URL  {
                    let itemMeta = await extractMetadataFromDoc(at: audioURL)
                    if itemMeta.isExampleOnly == false {
                        let coordinator = createARCoordinator(with: itemMeta, fileAt: audioURL)
                        cloudCoordinators.insert(coordinator)
                    } else {
                        problemFiles.append(audioURL)
                        NSLog(">>>Unable to read iCloud based audio reflection metadata at \(audioURL.absoluteString)")
                        continue
                    }//: IF ELSE
                }//: IF LET (as NSMetadataItem)
            }//: LOOP
            
            if problemFiles.isNotEmpty {
                await MainActor.run {
                    handlingError = .syncError
                    errorMessage = "It appears that not every audio reflection file saved in iCloud was readable. Please manually inspect the Reflections folder and remove any non-audio reflection (.refl) files. All readable ones will be synced."
                }//: MAIN ACTOR
                let totalCount = cloudCoordinators.count + problemFiles.count
                NSLog(">>>Out of the \(totalCount) files found on iCloud, \(problemFiles.count) could not be read due to metadata being unreadable.")
            }//: IF (isNotEmpty)
            
            await coordinatorAccess.setAllCloudCoordinators(with: cloudCoordinators)
            
            // Removing observers
            NotificationCenter.default.removeObserver(
                self,
                name: .NSMetadataQueryDidUpdate,
                object: audioQuery
            )
            
            NotificationCenter.default.removeObserver(
                self,
                name: .NSMetadataQueryDidFinishGathering,
                object: audioQuery
            )
            
            await syncCoordinatorList()
            
        }//: cloudARSearchEndedHandler
    
        // MARK: iCLOUD STATUS CHANGE
    
        /// Private selector method used in the .NSUbiquityIdentityDidChange observer for the AudioReflectionBrain class that
        /// calls the startICloudAudioReflectionsSearch method to begin the process that will upate the allCloudCoordinators property for
        /// whatever audio reflections objects are available.
        /// - Parameter notification: Notification object that is generated when the ubiquity idenity value changes
        ///
        /// - Note: By calling startICloudAudioReflectionsSearch, additional observers are created within that method that will run
        /// the completion method (cloudARSearchFinished) when the completion notification is received by them.
        /// This method will then create a new set of coordinator objects for all audio reflections found on iCloud and assign them
        /// to the allCloudCoordinators property.  This ensures that the JSON file isn't updated and written to disk until
        /// all cloud coordinator objects have been created and added to the allCoordinators set.
        @objc private func handleICloudStatusChange(_ notification: Notification) {
            startICloudAudioReflectionsSearch()
        }//: moveLocalCoordListToiCloudUpon()
    
        // MARK: iCLOUD PREFERENCE CHANGE
    
        @objc private func cloudPreferenceChanged(_ notification: Notification) {
            let notificationToRemove = Notification.Name(.audioCoordinatorListSyncCompleted)
            NotificationCenter.default.removeObserver(self, name: notificationToRemove, object: nil)
            
            // Creating observer that will recieve notification when the coordinator list JSON
            // file has been updated and saved, following the completion of the startICloudCertSearch
            // and cloudCertSearchFinished methods.  Since it is unknown how long it will take
            // to query iCloud for saved certificate objects, using an observer to ensure that
            // the movement of files doesn't begin until after all coordinator objects are
            // updated.
            let syncCompleted = Notification.Name(.audioCoordinatorListSyncCompleted)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleMovingAudioFilesUpon(_:)),
                name: syncCompleted,
                object: nil
            )
            
            // After moving the files to whatever location the user prefers, update the
            // cloud coordinator objects and allCoordinators property to reflect the
            // file movement. Once this method is done, the cloudCertSearchFinished method
            // will be called which will do the property updating along with saving the
            // allCoordinators property values to disk.
            startICloudAudioReflectionsSearch()
        }//: cloudPreferenceChanged()
    
        /// Selector method for calling the moveAudioReflectionFiles() method upon receiving notification that the coordinator
        /// list has been synced.
        /// - Parameter notification: Notification object with the name "audioMediaStoragePrefChanged"
        @objc private func handleMovingAudioFilesUpon(_ notification: Notification) {
            Task.detached {[weak self] in
                await self?.moveAudioReflectionFiles()
            }//: detached
        }//: handleMovingAudioFilesUpon()
        
        /// Private method that uses ARCoordinator objects to move the files they represent from either the device to iCloud
        /// or vice-versa, depending on the user's cloud storage preference setting.
        ///
        /// - Important: This method should NOT be called until the querying of iCloud for any saved audio reflection
        /// objects has been completed, as indicated by the receipt of the audioCoordinatorListSyncCompleted notification.
        /// Otherwise, not all files may be transferred.
        ///
        /// This selector method calls the moveSavedCertificate(using: to: nowAt:) method to do the actual data transfer, but depends on
        /// the coordinator objects to determine which files are locally saved and which are saved on the cloud.  The
        /// DataController's prefersCertificatesInICloud computed property determines the movement of files.
        private func moveAudioReflectionFiles() async {
            let allLocalReflections = await getCoordinatorsForFiles(savedAt: .local)
            let allCloudReflections = await getCoordinatorsForFiles(savedAt: .cloud)
            var unableToMoveReflections: [ARCoordinator] = []
            
            switch dataController.prefersAudioReflectionsInICloud {
            case true:
                guard allLocalReflections.isNotEmpty else { return }
                for reflection in allLocalReflections {
                    if let reflMeta = reflection.mediaMetadata as? ARMetadata {
                        let moveToURL = createDocURL(with: reflMeta, for: .cloud)
                        do {
                            try await moveSavedAudioReflection(using: reflection, to: moveToURL, from: .local)
                        } catch {
                            unableToMoveReflections.append(reflection)
                            NSLog(">>>Error while trying to move a local audio reflection to iCloud.")
                            NSLog(">>>The audio reflection is at: \(reflection.fileURL.absoluteString)")
                        }//: DO-CATCH
                    }//: IF LET
                }//: LOOP
            case false:
                guard allCloudReflections.isNotEmpty else { return }
                for reflection in allCloudReflections {
                    if let audioMeta = reflection.mediaMetadata as? ARMetadata {
                        let moveToURL = createDocURL(with: audioMeta, for: .local)
                        do {
                            try await moveSavedAudioReflection(using: reflection, to: moveToURL, from: .cloud)
                        } catch {
                            unableToMoveReflections.append(reflection)
                            NSLog(">>>Error while trying to move an iCloud audio reflection to local device.")
                            NSLog(">>>The reflection is at: \(reflection.fileURL.absoluteString)")
                        }//: DO-CATCH
                    }//: IF LET
                }//: LOOP
            }//: SWITCH
            
            if unableToMoveReflections.isNotEmpty {
                await MainActor.run {
                    handlingError = .incompleteMove
                    errorMessage = "Unfortunately, not all files were successfully moved. Try again, but you may need to use the Files app or Finder to move them manually."
                }//: MAIN ACTOR
                let totalToMove = allLocalReflections.count + allCloudReflections.count
                NSLog(">>>Error in moving reflections.  Out of the \(totalToMove) reflections that needed to be moved, \(unableToMoveReflections.count) were not.")
                NSLog(">>>See earlier entries for the specific files that weren't moved.")
            }//: IF (isNotEmpty)
            
            let notificationToRemove = Notification.Name(.audioCoordinatorListSyncCompleted)
            NotificationCenter.default.removeObserver(self, name: notificationToRemove, object: nil)
        }//: moveCertFiles
        
    
    
    // MARK: - HELPERS
    
    private func extractMetadataFromDoc(at url: URL) async -> ARMetadata {
        var extractedMetaData: ARMetadata = ARMetadata.example
        let savedReflection = await ARDocument(audioURL: url)
        if await savedReflection.open() {
            extractedMetaData = await savedReflection.audioMetadata
        }//: closure
        await savedReflection.close()
        
        // Logging to help track why metadata reading failed
        if extractedMetaData.isExampleOnly {
            NSLog(">>>Error extracting audio reflection metadata. Returning example object instead.")
            NSLog(">>>Issue came at the following ARDocument URL: \(url.absoluteString)")
        }//: IF (isExampleOnly)
        
        return extractedMetaData
    }//: extractMetadataFromDoc
    
    /// Method for determining if an individual ReflectionResponse has audio data saved for it, based on a matching coordinator object.
    /// - Parameter activity: ReflectionResponse that is to be checked for audio data
    /// - Returns: True if a matching coordinator can be found and the ARDocument can be opened at the
    /// coordinator's fileURL property.  False if otherwise.
    func reflectionResponseHasAudioSaved(_ response: ReflectionResponse) async -> Bool {
        guard let foundCoordinator = await findMatchingCoordinatorFor(response: response) else { return false }
        
        let savedAudio = await ARDocument(audioURL: foundCoordinator.fileURL)
        if await savedAudio.open() {
            await savedAudio.close()
            return true
        } else {
            return false
        }//: IF await
    }//: ceActivityHasCertificateSaved(activity)
    
    /// Private method that does the work of finding the CeActivity stored in CoreData that the user is saving
    /// audio reflections for.
    /// - Parameter metaData: ARMetadata object, which has the ID for the ReflectionResponse
    /// - Returns: the CeActivity entity based on the ActivityReflection to which the ReflectionResponse object is associated with
    func matchAudioReflectionWithActivity(using metaData: ARMetadata) -> CeActivity? {
        let idToMatch = metaData.assignedObjectId
        let context = dataController.container.viewContext
        
        // Finding the cooresponding ReflectionResponse object from the assignedObjectId in the metadata
        let reflectResponseFetch = ReflectionResponse.fetchRequest()
        reflectResponseFetch.sortDescriptors = [NSSortDescriptor(key: "createdOn", ascending: true)]
        reflectResponseFetch.predicate = NSPredicate(format: "id == %@", idToMatch as CVarArg)
        
        let fetchedResponses = (try? context.fetch(reflectResponseFetch)) ?? []
        guard fetchedResponses.count == 1, let responseToMatch = fetchedResponses.first else {
            NSLog(">>>Error trying to return a matching CeActivity for an audio reflection. No ReflectionResponse with the assignedObjectId: \(idToMatch.uuidString) was found.")
            NSLog(">>> A total of \(fetchedResponses.count) response objects were returned by the fetch request.")
            return nil
        }//: GUARD
        
        if let assignedReflection = responseToMatch.reflection,
            let assignedCe = assignedReflection.ceToReflectUpon {
            return assignedCe
        } else {
            NSLog(">>>Error while trying to return a matching CeActivity for an audio reflection. Either no ActivityReflection object was assgined to the ReflectionResponse reflection property or no CeActivity was assigned to the ActivityReflection's ceToReflectUpon property.")
            NSLog("Response for prompt: \(metaData.promptQuestion)")
            return nil
        }//: IF LET ELSE
    }//: matchCertificatewithActivity
    
    /// Private helper method that locates a matching ARCoordinator object with a specific ReflectionResponse based on the assignedObjectId
    /// property within the coordinator.
    /// - Parameter response: ReflectionResponse object for which a coordinator is needed
    /// - Returns: ARCoordinator whose assignedObjectId property matches the ReflectionResponse's id property.
     func findMatchingCoordinatorFor(response: ReflectionResponse) async -> ARCoordinator? {
        if await coordinatorAccess.allCoordinators.isEmpty { await decodeCoordinatorList() }
        let coordinators = await coordinatorAccess.allCoordinators
        
        guard let responseID = response.id, let audioCoordinator = coordinators.first(where: { coordinator in
            coordinator.assignedObjectID == responseID
        }) else {
            NSLog(">>> Error finding a matching coordinator for a specific ReflectionResponse.")
            return nil
        }//: GUARD
        
        return audioCoordinator
    }//: findMatchingCoordinatorFor(response)
    
    // MARK: - PREVIEW
    #if DEBUG
    static var preview: AudioReflectionBrain = {
        let dcPreview = DataController.preview
        let abPreview = AudioReflectionBrain(dataController: dcPreview)
        return abPreview
    }()
    #endif
    
    // MARK: - INIT
    
    init(dataController: DataController) {
        self.dataController = dataController
        // MARK: - OBSERVERS
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleICloudStatusChange(_:)),
            name: .NSUbiquityIdentityDidChange,
            object: nil
        )//: OBSERVER
        
        let audioStoragePrefChange = Notification.Name(String.cloudAudioMediaPreferenceChanged)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cloudPreferenceChanged(_:)),
            name: audioStoragePrefChange,
            object: nil
        )//: OBSERVER
        
        // MARK: - REG INIT METHODS
        startICloudAudioReflectionsSearch()
        
    }//: INIT
    
    // MARK: - DEINIT
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }//: DEINIT
    
}//: AudioReflectionBrain
