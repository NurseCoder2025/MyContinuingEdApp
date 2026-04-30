//
//  MediaFileProtocols.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/13/26.
//

import CloudKit
import CoreData
import Foundation

// MARK: - PROTOCOL-RELATED GLOBALS
enum CertificateExtension: String, CaseIterable {
    case jpeg, png, heic, pdf
}//: CertificateExtension


// MARK: - CE Certificate Media Types

/// Custom protocol to enable functions and computed properties to handle binary data that is for either
/// a CE certificate object saved as an image file OR as a pdf.
///
/// There are 3 requirements for this protcol:
///  1.) A  property "certificateType", which is of the CertType enum data type.
///  2.) A certData computed property which gets an optional Data object
///  3.) A fileExtension computed property returning the string for the file extension which corresponds
///  to the data type represented by the certData property.
///
/// Currently, the only two objects assigned to this protocol are UIImage and PDFDocument, and the
/// certificateType values in each of those cases are .image and .pdf, respectively.
protocol Certificate {
    var certificateType: CertType {get}
    var certData: Data? { get }
    var fileExtension: String { get }
}//: PROTOCOL


// MARK: - MEDIA iCLOUD SYNC

protocol RepresentsDeletableMediaFile {
    var uploadedToICloud: Bool { get set }
    
    func resolveURL(basePath: URL) -> URL?
    func returnCDSelf() -> NSManagedObject
}//: LocalFileDeletable


