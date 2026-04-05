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
    func createMediaRelativePath(for activity: CeActivity, toSave media: MediaClass, forPrompt: ReflectionPrompt?) -> String {
        var pathString: String = ""
        var topDirectoryName: String = ""
        var subFolderName: String = ""
        var fileName: String = ""
        
        topDirectoryName = createTopSubDirectoryName(for: media)
        subFolderName = createActivitySubFolderName(for: activity)
        
        if let prompt = forPrompt {
            fileName = createMediaFileName(forCE: activity, forPrompt: prompt, as: media)
        } else {
            fileName = createMediaFileName(forCE: activity, forPrompt: nil, as: media)
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
    func createMediaFileName(forCE activity: CeActivity?, forPrompt prompt: ReflectionPrompt?, as category: MediaClass) -> String {
        var namePrefix: String = ""
        var baseFileName: String = ""
        var fileExtension: String = ""
        
        switch category {
        case .certificate:
            namePrefix = "Certificate"
            fileExtension = String.certImageFormatExtension
        case .audioReflection:
            namePrefix = "Reflection"
            fileExtension = String.audioFormatExtension
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
    
}//: EXTENSION

