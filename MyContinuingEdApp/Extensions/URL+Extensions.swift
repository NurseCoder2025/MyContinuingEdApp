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


