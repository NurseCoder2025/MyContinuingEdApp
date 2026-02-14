//
//  CECertificate.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/4/26.
//

import Foundation

struct CECertificate: MediaObjectModel {
    // MARK: - PROPERTIES
    var id: UUID = UUID()
    let type: CertType
    let assignedObjectId: UUID
    let earnedDate: Date
    var fileExtension: String
    var isDownloaded: Bool = false
    var whereSaved: SaveLocation = .cloud
    
    // MARK: - COMPUTED PROPERTIES
    
    var fileName: String {
        "\(assignedObjectId.uuidString)_\(earnedDate.formatted(date: .numeric, time: .omitted))_CE certificate.\(fileExtension)"
    }//: certFileURLName
    
    // MARK: - METHODS
    mutating func makeOffline() {
        whereSaved = .local
        isDownloaded = true
    }//: makeOffline
    
    mutating func makeOnlineOnly() {
        whereSaved = .cloud
        isDownloaded = false
    } //: makeOnlineOnly
    
    mutating func makeOnlineDownloaded() {
        whereSaved = .cloud
        isDownloaded = true
    }//: makeOnlineDownloaded
    
    
    // MARK: - EXAMPLE
    static let example: CECertificate = CECertificate(
        type: .image,
        assignedObjectId: UUID(),
        earnedDate: Date.now,
        fileExtension: "heic"
    )
    
    // MARK: - HASHABLE CONFROMANCE
    
    /// Method creating custom Hashable conformance for CECertificate objects.
    /// - Parameter hasher: Hasher object (system handled)
    ///
    /// Only the following 3 properties are used for creating Hashable conformance:
    ///     - assignedCeId
    ///     - earnedDate
    ///     - fileExtension
    ///
    /// - Note: All three of these properties are part of the fileName computed property, which allows
    /// for the creation of CECertificate objects just based on file names.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(assignedObjectId)
        hasher.combine(earnedDate)
        hasher.combine(fileExtension)
    }//: hash
    
    
}//: CECertificate

