//
//  FileManager+Extensions.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/4/26.
//

import CoreData
import Foundation


extension FileManager {
    
    /// FileManager method for determining whether a directory exists at a specified path (URL) and if not, attempts to create one
    /// - Parameter url: URL for the directory
    /// - Returns: True if either the url is a directory or if one could be created at the specified url; False otherwise
    func doesFolderExistAt(path url: URL) -> Bool {
        guard url.hasDirectoryPath else {
            NSLog(">>>Error: The url argument passed into the ensureFolderExists(withPath) method is not a directory url.")
            NSLog(">>> The url passed in was: \(url.absoluteString)")
            return false
        }//: GUARD
        var doesExist: Bool = false
        
        if self.fileExists(atPath: url.path) {
            doesExist = true
        } else {
            do {
                try self.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                doesExist = true
            } catch {
                NSLog(">>>Error creating directory for the specified url: \(url.absoluteString)")
                NSLog(">>>Error: \(error.localizedDescription)")
                doesExist = false
            }//: DO-CATCH
        }//: IF ELSE
        return doesExist
    }//: ensureFolderExists(having)
    
    /// FileManager method for determining if a given file URL is locally saved within the Documents folder or is in iCloud.
    /// - Parameter url: URL for a file that is saved either locally or on iCloud
    /// - Returns: SaveLocation enum case value representing whether the URL is local or cloud-based
    ///
    /// - Important: This method will throw a FileIOError.invalidArgument if a directory URL is passed in as the argument, and
    /// a NSLog entry will be made to that effect.
    ///
    /// This method only works for files saved within the documentsDirectory URL. The assumption is that if the path prefix for the
    /// for argument is equal to the standardized file URL for the documents directory, then it is a locally-saved file.
    func identifyFileURLLocation(for url: URL) throws -> SaveLocation {
        guard url.isFileURL else {
            NSLog(">>>Error: invalid url passed into the identifyFileURLLocation method. A directory URL appears to have been passed in instead of a file. The url in question is :\(url.absoluteString)")
            throw FileIOError.invalidArgument
        }//: GUARD
        
        let docsDirectory = URL.documentsDirectory.standardizedFileURL
        let fileURL = url.standardizedFileURL
        
        let docsPath = docsDirectory.path(percentEncoded: true).hasSuffix("/") ? docsDirectory.path(percentEncoded: true) : docsDirectory.path(percentEncoded: true) + "/"
        let filePath = fileURL.path(percentEncoded: true)
        
        return filePath.hasPrefix(docsPath) ? SaveLocation.local : SaveLocation.cloud
        
    }//: identifyFileURLLocation(for)
    
    /// FileManager method that utilizes the FileManager enumerator to go through a speciifed directory, and all sub-
    /// directories within it, to return an array of URLs for all specified media types saved in that location.
    /// - Parameters:
    ///   - directory: URL for the directory desired to be searched
    ///   - fileExt: String representing the file extension at the end of the filename for all object URLs to be returned
    /// - Returns: Array of URLs for alll objects in the given directory that match the fileExt argument
    ///
    /// - Note: This method will throw a FileIOError.invalidArgument error if the directory argument is a file URL.
    /// - Important: Be sure that the file extension argument is entered corrected or else no URLs may be returned.
    func getAllSavedMediaFileURLs(from directory: URL, with fileExt: String) throws -> [URL] {
        guard directory.hasDirectoryPath else {
            NSLog(">>>Error getting URLs for saved media files due to the directory argument is a file and not a directory URL.")
            throw FileIOError.invalidArgument
        }//: GUARD
        
        var foundURLs: [URL] = []
        let directoryEnumerator = self.enumerator(atPath: directory.path(percentEncoded: true))
        
        if let enumerator = directoryEnumerator {
            for case let file as String in enumerator {
                if file.hasSuffix(fileExt) {
                    let fileURL = directory.appending(path: file, directoryHint: .notDirectory)
                    foundURLs.append(fileURL)
                }//: IF
            }//: LOOP
        }//: IF LET (enumerator)
        return foundURLs
    }//: getAllSavedMediaFileURLs(from, with)
    
    // MARK: - FOLDER/URL CREATION
    
    /// FileManager method for creating relative path strings for media files that are to be associated with any given
    /// CeActivity or ReflectionPrompt, or other CoreData entity in this app.
    /// - Parameters:
    ///   - activity: CeActivity that is associated with the media file (either directly or indirectly)
    ///   - media: MediaType enum indicating if the media being stored is an image, pdf, or audio file
    ///   - forPrompt: [Optional] ReflectionPrompt object for which audio reflections are being saved
    /// - Returns: String representing the relative path for the newly selected/created media file
    func createMediaRelativePath(
        for activity: CeActivity,
        toSave media: MediaClass,
        forPrompt: ReflectionPrompt?,
        usingExt fileExtension: String
    ) -> String {
        var pathString: String = ""
        var topDirectoryName: String = ""
        var subFolderName: String = ""
        var fileName: String = ""
        
        topDirectoryName = createTopSubDirectoryName(for: media)
        subFolderName = createActivitySubFolderName(for: activity)
        
        if let prompt = forPrompt {
            fileName = createMediaFileName(forCE: activity, forPrompt: prompt, as: media, usingExt: fileExtension)
        } else {
            fileName = createMediaFileName(forCE: activity, forPrompt: nil, as: media, usingExt: fileExtension)
        }//: IF LET
        
        pathString.append("\(topDirectoryName)/\(subFolderName)/\(fileName)")
        
        return pathString
    }//: createMediaRelativePath(for)
    
    func createTopSubDirectoryName(for category: MediaClass) -> String {
        switch category {
        case .certificate:
            return "Certificates"
        case .audioReflection:
            return "Reflections"
        }//: SWITCH
    }//: createTopSubDirectoryName(for)
    
    /// Method that creates the name for the sub-folder holding CE media objects for a specific activity.
    /// - Parameter ce: CeActivity that the certificate is being saved to
    /// - Returns: String value for the folder name
    ///
    /// The folder convention for media files in this app is that all CE-related objects are to be stored within a top-level
    /// folder within the local or iCloud Documents folder that is named for the type of media being stored (certificates/audio reflections)..  Then, inside of that folder additional
    /// sub-folders will be created for each CeActivity, using the name of the activity as its name to hold all certificate objects
    /// for that activity. To keep the folder names to a reasonable length, the method limits the returned string to a max of
    /// 25 characters (after trimming the activity's title property to remove any white spaces and lines).
    func createActivitySubFolderName(for ce: CeActivity) -> String {
        let activityFolderName = self.sanitizeFileName(ce.ceTitle).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "_")
        
        let maxNameLength: Int = 25
        
        if activityFolderName.count > maxNameLength {
            let shortenedName = activityFolderName.prefix(maxNameLength)
            return String(shortenedName)
        } else if activityFolderName.isEmpty, let assignedId = ce.activityID {
            return "UnnamedCe_\(assignedId.uuidString.trimWordsTo(length: 10))"
        } else if activityFolderName.isEmpty {
            // Logging details as this particular scenario should not happen as every CeActivity should
            // be assigned an activityID value upon creation.
            NSLog(">>>While creating the folder name for an unnamed CeActivity, found a nil value for the activityID property. Using a random Int value for the folder name.")
            NSLog(">>>The specific activity was created on \(ce.ceActivityAddedDate)")
            NSLog(">>>The specific activity's description: \(ce.ceDescription)")
            
            let nameToReturn = "UnnamedCe_\(Int.random(in: 1...5000))"
            NSLog(">>>The new folder name for the unnamed CE is :\(nameToReturn)")
            return nameToReturn
        } else  {
            return activityFolderName
        }//: IF ELSE
    }//: createActivitySubFolder
    
    /// Method that creates the filename string to be used for the last URL path component for a CE media-related object.
    /// - Parameter activity: CeActivity that the certificate is to be associated with (optional)
    /// - Returns: String value using the completion date for the activity or, if the activity argument is nil, a name using the
    /// current date and time value.
    ///
    /// - Note: The reason for making the activity parameter optional is because of the possibility a CeActivity may not be,
    /// and is not required to be, assigned to a mediat object.  Both situations are handled by the method.
    func createMediaFileName(
        forCE activity: CeActivity?,
        forPrompt prompt: ReflectionPrompt?,
        as category: MediaClass,
        usingExt fileExtension: String
    ) -> String {
        var namePrefix: String = ""
        var baseFileName: String = ""
        
        switch category {
        case .certificate:
            namePrefix = "Certificate"
        case .audioReflection:
            namePrefix = "Reflection"
        }//: SWITCH
        
        // This block assigns either the completion date (for CE
        // certificates) or the current date (for audio reflections or
        // CE activities without a completion date (unlikely but possible).
        if let assignedCe = activity {
            let completionDate = assignedCe.ceActivityCompletedDate.formatDateIntoHyphenedString()
            baseFileName = "\(namePrefix)_\(completionDate)"
        } else if let assignedPrompt = prompt {
            let nameSuffix: String = assignedPrompt.trimQuestionLength(to: 25)
            baseFileName = "\(namePrefix)_on_\(nameSuffix)"
        } else {
            let saveTime: Date = Date.now
            let dateToUse: String = saveTime.formatDateIntoHyphenedString()
            baseFileName = "\(namePrefix)_saved at_\(dateToUse)"
        }//: IF ELSE
        return self.sanitizeFileName(baseFileName) + ".\(fileExtension)"
    }//: createMediaFileName
    
    func sanitizeFileName(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\:*#?~`'[]()^%;\"<>|")
        let nameWithGoodChars = name.components(separatedBy: invalidCharacters).joined(separator: "_")
        let sanitizedName = nameWithGoodChars.replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "__", with: "_").replacingOccurrences(of: "___", with: "_")
        return sanitizedName
    }//: sanitizeFileName
    
    func createRelativePathStringForCKRecord<T: NSManagedObject>(
        coreDataObj cdObject: T,
        assignedToCe activity: CeActivity,
        certExtension: String = ""
    ) -> String where T : RepresentsDeletableMediaFile {
    
        var mediaCat: MediaClass
        var promptArgument: ReflectionPrompt? = nil
        var fileExt: String = ""
        
        if cdObject is CertificateInfo {
            mediaCat = .certificate
            if certExtension.isNotEmpty {
                fileExt = certExtension
            } else {
                fileExt = "heic"
            }//: IF ELSE (isNotEmpty)
        } else if cdObject is AudioInfo {
            mediaCat = .audioReflection
            fileExt = String.audioFormatExtension
            if let audioInfObject = cdObject.returnCDSelf() as? AudioInfo {
                promptArgument = audioInfObject.getAssignedPrompt()
            }//: IF LET
        } else {
            return ""
        }//: IF ELSE
      
       let topDirectory = createTopSubDirectoryName(for: mediaCat).convertToASCIIonly()
       let subDirectory = createActivitySubFolderName(for: activity).convertToASCIIonly()
        let initialPath = createMediaRelativePath(for: activity, toSave: mediaCat, forPrompt: promptArgument, usingExt: certExtension).convertToASCIIonly()
        
        guard initialPath.count <= 255 else {
            return "\(topDirectory)/\(subDirectory)/UnknownFile.\(fileExt)"
        }//: GUARD
        
        NSLog(">>> createRelativePathStringForCKRecord: '\(initialPath)'")
       return initialPath
    }//: createRelavtivePathStringForCKRecord()
    
    // MARK: - I/O Errors
    
    /// Custom FileManager method designed to log and return user alert string values for common file I/O errors, such as the disk being full or invalid filename.
    /// - Parameters:
    ///   - error: Cococa error that was thrown by a method
    ///   - purpose: IOPurpose enum value representing what the method was trying to do (save, move, delete)
    ///   - objectName: Name of the object in which the method is defined and called
    ///   - callingMethod: Name of the method that threw the error
    ///   - path: String representing the path of the file the error is related to (default value: "")
    ///   - finalActions: Closure that allows for custom additional actions wherever this method is called from (default value: {})
    /// - Returns: Tuple with two string values that can be used in an alert or other UI presentation to the user so they can be informed about the error that
    /// occurred and what to do about it.
    ///
    /// As part of the function, two NSLog statements are created: the first providing the name of the object and method so the error can be tracked down easier.
    /// The second NSLog statement provides a brief and more technical description of the error along with whatever value is in the filePathString argument (if
    /// left to the default value of "", then no path will be shown in the log).  The closure takes no parameters and returns nothing.
    ///
    ///  - Note: The action property of whatever IOPurpose enum value is passed in as an argument for when will be used in the message part of the returned
    ///  tuple as the verb for describing what the user was trying to do when the error occurred.
    func handleCommonDiskErrors(
        thrownError error: CocoaError,
        when purpose: IOPurpose,
        objectName: String,
        callingMethod: String,
        filePathString path: String = "",
        finalActions: @escaping () -> Void = {}
    ) -> (alertTitle: String, alertMessage: String) {
        var logText: String = ""
        var titleText: String = ""
        var messageText: String = ""
        
        if error.code == .fileNoSuchFile {
            logText = "A Cococa error was thrown by the \(callingMethod) method due to the file system being unable to locate it based on the path provided: \(path)."
            titleText = "File Not Found"
            messageText = "The specified file could not be \(purpose.action) because the file system was unable to locate it based on the path provided. If the file has been manually moved or deleted using the Finder or Files app, then plase re-add it to the app and try again."
        } else if error.code == .fileReadCorruptFile {
            logText = "A Cococa error was thrown by the \(callingMethod) method due to the file system being unable to read the file due to it being corrupted. Path for the file: \(path)."
            titleText = "File Corrupted"
            messageText = "The specified file could not be \(purpose.action) because the underlying data has somehow been corrupted and cannot be read by the system. Please try manually removing the file by using the Finder or Files app and then re-add it again. Contact the app developer if additional assistance is needed."
        } else if error.code == .fileReadNoPermission {
            logText = "A Cococa error was thrown by the \(callingMethod) method because the app does not have the necessary permissions to read the file at its current path: \(path)."
            titleText = "File Not Accessible"
            messageText = "The app was unable to \(purpose.action) the file because the disk or area it is stored in lacks read permission access. If possible, use the Finder to grant read permission to the disk or area containing the file. Otherwise, contact the administrator for the device or Apple support."
        } else if error.code == .fileReadInvalidFileName || error.code == .fileWriteInvalidFileName {
            logText = "A Cococa error was thrown by the \(callingMethod) method becuase the file name for the specified file is in an invalid format or has invalid characters. Path for the file: \(path)."
            titleText = "Invalid Filename"
            messageText = "The app was unable to \(purpose.action) the file because the name given to it is invalid. Use the Finder or Files app to locate it and rename it with only valid characters, ensuring that the extension after the name is a recognized one (ex. jpeg, png, pdf, etc.)."
        } else if error.code == .fileWriteFileExists {
            logText = "A Cococa error was thrown by the \(callingMethod) method becuase the user tried to write over an existing file with the same name. Path for the file: \(path)."
            titleText = "Duplication Error"
            messageText = "The app was unable to \(purpose.action) the file because either another file has the exact same name as the one being \(purpose.action) or the file system is preventing the app from overwriting the existing file. Find the file that has the same name and either re-name or delete it, then try again."
        } else if error.code == .fileReadTooLarge {
            logText = "A Cococa error was thrown by the \(callingMethod) method becuase the file is too large to be read by the system. Path for the file: \(path)."
            titleText = "File Size Error"
            messageText = "The app was unable to \(purpose.action) the file because the file's size made it impossible for the system to read it. Try manually removing the file using the Finder or File app and then re-add it in a smaller (compressed if possible) size."
        } else if error.code == .fileWriteNoPermission {
            logText = ">>>A Cococa error was thrown by the \(callingMethod) method becuase the app does not have write permission for the path specified. Path: \(path)."
            titleText = "Can't Save File"
            messageText = "The app is unable to save the file to the location specified because you do not have write permission for the disk or directory you're trying to save it to. Please select a different location or update the permissions for the disk or directory so that the app can write to it."
        } else if error.code == .fileWriteVolumeReadOnly {
            logText = "A Cococa error was thrown by the \(callingMethod) method becuase the app does not have write permission for the disk/volume that it is being saved to. Path: \(path)."
            titleText = "Can't Save File"
            messageText = "The app is unable to save the file to the location specified because you do not have write permission for the disk or volume you're trying to save it to. Please select a different location or update the permissions for the disk so that the app can write to it."
        } else if error.code == .fileWriteOutOfSpace {
            logText = "A Cococa error was thrown by the \(callingMethod) method becuase the user's device or disk is completely full and nothing further can be saved ot it. Path: \(path)."
            titleText = "Disk/Device Storage Full"
            messageText = "The app is unable to save the file to the location specified because there is not enough free space available on which to save the file. Please either select a different disk that has free space (if possible) or free up space on the current device and try again."
        } else {
            logText = "A less common Cococa error was thrown by the \(callingMethod) due to a technical reason unrelated to the disk/volume being full, permission errors, invalid filename, file size, file corruption, file not being found, or duplicate file error."
            titleText = "Other Error"
            messageText = "The app was unable to \(purpose.action) the specified file due to a technical issue that is not commonly encountered such as the disk/device storage being full or an invalid filename. Please try again later. If this continues to occur, please contact the developer for additional support."
        }//: IF ELSE
        
        NSLog(">>>\(objectName) | \(callingMethod)")
        NSLog(">>>\(logText)")
        return (titleText, messageText)
    }//: handleCommonDiskErrors(thrownError, when, finalActions)
    
}//: EXTENSION

