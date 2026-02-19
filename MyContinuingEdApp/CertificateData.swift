//
//  CertificateData.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/18/26.
//

import Foundation
import PDFKit
import UIKit


/// Data model for holding binary data related to a CE certificate a user saves in the app
/// for a given activity.
///
/// - Parameters:
///     - certData: raw binary data that could either represent an image or PDF file
///
/// This struct has two computed properties which allow for access to either the full
/// certificate unwrapped into the corresponding data type, UIImage or PDFDocument, or a
/// thumbnail image of the certificate image file.  Those properties are: fullCertificate and
/// certImageThumbnail.
///
/// - Important: fullCertificate returns either a UIImage or PDFDocument as a
/// Certificate protocol conforming object.  To determine what the underlying data type is,
/// check the certificateType property value as the underlying enum will show either .image
/// or .pdf.  If, for some reason the fullCertificate property is nil when there is data in the
/// certData property then iOS could not convert the data into either a UIImage or PDF.
///
/// - Note: The image thumbnail is created asynchronously using the UIImage's
/// prepareThumbnail(of: completionHandler) method.
struct CertificateData: Codable {
    // MARK: - PROPERTIES
    let certData: Data?
    
    // MARK: - COMPUTED PROPERTIES
    
    var fullCertificate: Certificate? {
        if let existingData = certData {
            if let image = UIImage(data: existingData) {
                return image
            } else if let pdf = PDFDocument(data: existingData) {
                return pdf
            } else {
                return nil
            }
        } else {
            return nil
        }
    }//: fullCertificate
    
    var certImageThumbnail: UIImage? {
        if let existingData = certData {
            var reducedImage: UIImage? = nil
            if let image = UIImage(data: existingData) {
                let thumbSize: CGSize = CGSize(width: 150, height: 100)
                image.prepareThumbnail(of: thumbSize) { thumbImage in
                    reducedImage = thumbImage
                }//: closure
            }//: IF LET
            
            if let obtainedThumb = reducedImage {
                return obtainedThumb
            } else {
                return nil
            }
        } else  {
            return nil
        }
    }//: certImageThumbnail
    
    // MARK: - INIT
    init(containing certData: Data? = nil) {
        self.certData = certData
    }//: INIT
    
}//: CertificateData
