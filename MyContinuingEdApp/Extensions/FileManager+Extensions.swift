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
    
}//: EXTENSION

