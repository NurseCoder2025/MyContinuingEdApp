//
//  CECertificate.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/29/26.
//

import Foundation
import PDFKit
import UIKit


enum CECertificate: Identifiable, Certificate, Equatable {
    case image(UIImage)
    case pdf(PDFDocument)
    
    var id: UUID { return UUID() }//: id
    
    var certificateType: CertType {
        switch self {
        case .image(_):
            return CertType.image
        case .pdf(_):
            return CertType.pdf
        }//: SWITCH
    }//: certificateType
    
    var certData: Data? {
        switch self {
        case .image(let uIImage):
            return uIImage.certData
        case .pdf(let pDFDocument):
            return pDFDocument.certData
        }//: SWITCH
    }//: certData
    
    var fileExtension: String {
        switch self {
        case .image(let uIImage):
            return uIImage.fileExtension
        case .pdf(let pDFDocument):
            return pDFDocument.fileExtension
        }//: SWITCH
    }//: fileExtension
    
}//: CECertificate
