//
//  FileManager+Extensions.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/4/26.
//

import Foundation


extension FileManager {
    
    /// FileManager method for determining whether a directory exists at a specified path (URL) and if not, attempts to create one
    /// - Parameter url: URL for the directory
    /// - Returns: True if either the url is a directory or if one could be created at the specified url; False otherwise
    func doesFolderExistAt(path url: URL) throws -> Bool {
        guard url.hasDirectoryPath else {
            NSLog(">>>Error: The url argument passed into the ensureFolderExists(withPath) method is not a directory url.")
            NSLog(">>> The url passed in was: \(url.absoluteString)")
            throw FileIOError.invalidArgument
        }//: GUARD
        var doesExist: Bool = false
        
        if self.fileExists(atPath: url.path(percentEncoded: true)) {
            doesExist = true
        } else {
            do {
                try self.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                doesExist = true
            } catch {
                NSLog(">>>Error creating directory for the specified url: \(url.absoluteString)")
                NSLog(">>>Error: \(error.localizedDescription)")
                throw FileIOError.writeFailed
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
    
    /// FileManager method that creates the name for the sub-folder holding media objects for a specific activity.
    /// - Parameter ce: CeActivity that the media object is being saved for
    /// - Returns: String value for the folder name
    ///
    /// Output:
    ///     - CeActivity.ceTitle (trimmed to 25 characters)
    ///     - IF ceTitle is nil and the activityID has a value, then "UnnamedCe_(trimmed uuid string)"_
    ///     - IF no activityID or ceTitle, then "UnnamedCe_(random Int between 1 and 500)"_
    ///
    /// The folder convention for media files in this app is that all media objects are to be stored within a top-level
    /// folder within the local or iCloud Documents folder that has the name of the type of media being stored (
    /// i.e. Certficates, Reflections).  Then, inside of the  folder additional sub-folders will be created for each
    /// CeActivity, using the name of the activity as its name to hold all media objects
    /// for that activity.  If the ce argument happens to have no title, then the id property will be returned as a string.
    /// To keep the folder names to a reasonable length, the method limits the returned string to a max of
    /// 25 characters (after trimming the activity's title property to remove any white spaces and lines).
    ///
    /// - Note: This method limits the length of the sub folder name to 25 characters
    func createActivitySubFolderName(for ce: CeActivity) -> String {
        let maxNameLength: Int = 25
        let trimmedTitle = ce.ceTitle.trimWordsTo(length: maxNameLength)
        let activityFolderName = trimmedTitle.replacingOccurrences(of: " ", with: "_")
        
        if activityFolderName.isEmpty, let assignedID = ce.activityID {
            return "UnnamedCe_\(assignedID.uuidString.trimWordsTo(length: 10))"
        } else if activityFolderName.isEmpty {
            // Logging details as this particular scenario should not happen as every CeActivity should
            // be assigned an activityID value upon creation.
            NSLog(">>>While creating the folder name for an unnamed CeActivity, found a nil value for the activityID property. Using a random Int value for the folder name.")
            NSLog(">>>The specific activity was created on \(ce.ceActivityAddedDate)")
            NSLog(">>>The specific activity's description: \(ce.ceDescription)")
            
            let nameToReturn = "UnnamedCe_\(Int.random(in: 1...500))"
            NSLog(">>>The new folder name for the unnamed CE is :\(nameToReturn)")
            return nameToReturn
        } else {
            return activityFolderName
        }//: IF ELSE
    }//: createActivitySubFolder
    
}//: EXTENSION

