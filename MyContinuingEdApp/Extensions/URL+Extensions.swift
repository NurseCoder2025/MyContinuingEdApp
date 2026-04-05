//
//  URL+Extensions.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/17/26.
//

import Foundation


// MARK: - URL Constants
extension URL {
    
    static let localICloudUserFile = URL.applicationSupportDirectory.appending(path: String.iCloudUserID, directoryHint: .notDirectory)
    
    /// Static constant property to URL that creates a folder on a user's device within the
    /// application's documents directory folder called "Certificates".
    static let localCertificatesFolder = URL.documentsDirectory.appending(path: "Certificates", directoryHint: .isDirectory)
    
    static let locallySavedCertificateFile = URL.localCertificatesFolder.appending(path: "newCertificate_\(Int.random(in: 1...5000)).\(String.certFileExtension)", directoryHint: .notDirectory)
    
    /// Static constant property to the URL struct that creates a folder on the user's local device within the application support directory folder called
    /// "CertificateCoordinatorList.json".  Must ensure that data is encoded and decoded to the file as JSON.
    static let localCertCoordinatorsListFile = URL.applicationSupportDirectory.appending(path: String.certCoordinatorListFile, directoryHint: .notDirectory)
    
    /// Static constant property to URL that creates a folder on a user's device within the
    /// application's documents directory folder called "Reflections".
    static let localAudioReflectionsFolder = URL.documentsDirectory.appending(path: "Reflections", directoryHint: .isDirectory)
    
    static let localAudioCoordinatorsListFile = URL.applicationSupportDirectory.appending(path: String.audioCoordinatorListFile, directoryHint: .notDirectory)
    
}//: EXTENSION

// MARK: - METHODS

extension URL {
    
    /// URL method for determining if a given media file is located within one of the
    /// media sub-folders.
    /// - Parameter category: MediaClass enum to indicate which subfolder the file
    /// should be saved in
    /// - Returns: True if the URL begins with the local folder URL for whatever MediaClass
    /// argument was passed in; false otherwise.
    ///
    /// - Important: The logic of this method assumes that there are at least four parts to the
    /// URL: the top-level directory (Documents), the media type sub-folder (Certificates or Reflections)
    /// , the name for the CeActivity the media file is associated with, and the filename. The method
    /// removes the last two parts of the URL and then compares what's left to the local media
    /// subfolder URL.
    func isMediaLocallySavedUrlFor(category: MediaClass) -> Bool {
        var directoryPath: URL
        
        switch category {
        case .certificate:
            directoryPath = URL.localCertificatesFolder
        case .audioReflection:
            directoryPath = URL.localAudioReflectionsFolder
        }//: SWITCH
        
        let fileNameRemoved = self.deletingLastPathComponent()
        let activityFolderRemoved = fileNameRemoved.deletingLastPathComponent()
        
        return activityFolderRemoved == directoryPath
    }//: isURLInMediaSubFolderFor()
    
}//: EXTENSION
