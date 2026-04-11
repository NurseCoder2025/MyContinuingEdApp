//
//  CertFileVersion.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/21/26.
//

import Foundation


/// The purpose of the MediaFileVersion struct is to allow for the holding of file version information and creation
/// of NSFileVersion objects based on the URL in the struct's fileLocation property while conforming to Codable.
///
/// The main reason this struct was created was due to the fact that the NSFileVersion class conforms neither
/// to Codable nor to NSCoding, so the only way to utilize that class in media file objects, or
/// anywhere else for that matter, was to essentially "wrap" it inside of a struct that could conform to Codable.
struct MediaFileVersion: Codable, Equatable {
    // MARK: - PROPERTIES
    var fileLocation: URL
    let version: Double
    var localizedName: String?
    var savedComputer: String?
    var modifiedOn: Date?
    
    // MARK: - METHODS
    
    /// Struct method that allows for the creation of a NSFileVersion object based on
    /// the fileLocation (URL) property for any instance.
    /// - Returns: NSFileVersion instance if one can be made with the URL
    /// provided.
    func createFileVersionOfObject() -> NSFileVersion? {
        NSFileVersion.currentVersionOfItem(at: fileLocation)
    }//: createFileVersionObject(with)
    
    // MARK: - PROTOCOL CONFORMANCE
    static func ==(lhs: MediaFileVersion, rhs: MediaFileVersion) -> Bool {
        if lhs.fileLocation == rhs.fileLocation && lhs.version == rhs.version {
            return true
        } else {
            return false
        }
    }//: ==
    
    // MARK: - INIT
    init(fileAt: URL, version: Double) {
        self.fileLocation = fileAt
        self.version = version
        
        if let tempFV = NSFileVersion.currentVersionOfItem(at: fileAt) {
            self.localizedName = tempFV.localizedName
            self.savedComputer = tempFV.localizedNameOfSavingComputer
            self.modifiedOn = tempFV.modificationDate
        } else {
            self.localizedName = nil
            self.savedComputer = nil
            self.modifiedOn = nil
        }
    }//: INIT
    
}//: STRUCT
