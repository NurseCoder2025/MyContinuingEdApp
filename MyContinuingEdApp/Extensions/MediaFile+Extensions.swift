//
//  MediaFile+Extensions.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/18/26.
//

import Foundation
import PDFKit
import UIKit


extension UIImage: Certificate {
    var certificateType: CertType { .image }
    
    /// The certData implementation for UIImage as part of the Certificate protocol either returns
    /// the UIImage data in Apple's HEIC format (for devices running iOS 17 [and equivalents] & later
    /// only) or jpeg with 50% compression in order to save space.
    ///
    /// The resason the data type is optional is because either UIImage method for creating a
    /// heic or jpeg data representation of the image data may fail if the underlying data is corrupted or
    /// can't be converted for whatever reason.
    var certData: Data? {
        get {
            if #available(iOS 17.0, *) {
                self.heicData() ?? nil
            } else {
                self.jpegData(compressionQuality: 5.0) ?? nil
            }//: IF (available)
        }//: GETTER
    }//: certData
    
    var fileExtension: String {
        if #available(iOS 17.0, *) {
            return CertificateExtension.heic.rawValue
        } else {
            return CertificateExtension.jpeg.rawValue
        }//: IF (available)
    }//: fileExtension
    
}//: EXTENSION


extension PDFDocument: Certificate {
    var certificateType: CertType {.pdf}
    
    /// The certData property for PDFDocument, as part of its conformance to the Certificate protocol,
    /// returns the document data as a NSObject object without compressing the file size.
    var certData: Data? {
        self.dataRepresentation()
    }//: certData
    
    var fileExtension: String { return CertificateExtension.pdf.rawValue }//: fileExtension
}//: EXTENSION

