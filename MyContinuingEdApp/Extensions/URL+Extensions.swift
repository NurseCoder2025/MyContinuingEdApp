//
//  URL+Extensions.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/17/26.
//

import Foundation


extension URL {
    
    /// Static constant property to URL that creates a folder on a user's device within the
    /// application's documents directory folder called "Certificates".
    static let localCertificatesFolder = URL.documentsDirectory.appending(path: "Certificates", directoryHint: .isDirectory)
    
    /// Static constant property to URL that creates a folder on a user's device within the
    /// application's documents directory folder called "Reflections".
    static let localAudioReflectionsFolder = URL.documentsDirectory.appending(path: "Reflections", directoryHint: .isDirectory)
    
}//: EXTENSION
