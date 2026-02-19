//
//  String+Extensions.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/17/26.
//

import Foundation


extension String {
    
    /// Static constant in the String struct (via extension) that sets the value for
    /// the CE certificate file package (UI Document) as "cert".
    static let certFileExtension: String = "cert"
    
    /// Static constant in the String struct (via extension) that sets the value for
    /// the audio reflection file package (UI Document) as "audio"
    static let audioReflectionExtension: String = "audio"
    
    
    /// Static constant in the String struct (via extension) that represents a String dictionary key
    /// for the FileWrapper directory objects created for the CertificateDocument (UIDocument) that
    /// correspond to the CertificateMetadata object.
    static let certMetaDataKey: String = "certificate.meta"
    
    
    /// Static constant in the String struct (via extension) that represents a String dictionary key
    /// for the FileWrapper directory objects created for the CertificateDocument (UIDocument) that
    /// correspond to the CertificateData object.
    static let certBinaryDataKey: String = "certificate.data"
    
}//: EXTENSION
