//
//  CECertificate.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/4/26.
//

import Foundation

struct CECertificate: Identifiable, Codable {
    enum CertType: Codable {case image, pdf}
    enum SaveLocation: Codable {case local, cloud}
    // MARK: - PROPERTIES
    var id: UUID = UUID()
    let type: CertType
    let assignedCeId: UUID
    let earnedDate: Date
    var fileExtension: String
    var isDownloaded: Bool = false
    var whereSaved: SaveLocation = .cloud
    
    // MARK: - COMPUTED PROPERTIES
    
    var fileName: String {
       "\(earnedDate.formatted(date: .numeric, time: .omitted))_CE certificate.\(fileExtension)"
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
        assignedCeId: UUID(),
        earnedDate: Date.now,
        fileExtension: "heic"
    )
    
    
}//: CECertificate

