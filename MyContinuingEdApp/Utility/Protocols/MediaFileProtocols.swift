//
//  MediaFileProtocols.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/13/26.
//

import CloudKit
import Foundation


// MARK: - CE Certificate Media Types

/// Custom protocol to enable functions and computed properties to handle binary data that is for either
/// a CE certificate object saved as an image file OR as a pdf.
///
/// The only requirement for this protcol is a property "certificateType", which is of the CertType enum data
/// type.  Currently, the only two objects assigned to this protocol are UIImage and PDFDocument, and the
/// certificateType values in each of those cases are .image and .pdf, respectively.
protocol Certificate {
    var certificateType: CertType {get}
}//: PROTOCOL


// MARK: - MEDIA iCLOUD SYNC

protocol LocalFileDeletable {
    var removeLocalFile: Bool { get set }
    func resolveURL(basePath: URL) -> URL?
}//: LocalFileDeletable


