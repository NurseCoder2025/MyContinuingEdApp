//
//  CertificateInfo-CoreDataHelper.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/1/26.
//

import CoreData
import Foundation

extension CertificateInfo {
    // MARK: - UI Helpers
    
    var certInfoId: UUID {
        get {
            infoID ?? UUID()
        }
    }//: certInfoId
    
    var certInfoRelativePath: String {
        get {
            relativePath ?? ""
        }
        set {
            relativePath = newValue
        }
    }//: certInfoRelativePath
    
    /// CoreData helper computed property for CertificateInfo that gets the String value for the
    /// certType property.
    ///
    /// - Important: This is a getter-only.  For setting the value of this property, use the class
    /// helper method setCertificateMediaType(as). That will put in the correct String value.
    var certInfoCertType: String {
        get {
            certType ?? ""
        }
    }//: certInfoCertType
    
    // MARK: - Computed Properties
    
    /// CoreData computed helper property for CertificateInfo that returns either the ceTtile helper value
    /// for the CeActivity assigned to the CertificateInfo object or "N/A" if no activity has been assigned.
    var completedActivityName: String {
        completedCe?.ceTitle ?? "N/A"
    }//: completedActivityName
    
    /// CoreData computed helper property for CertificateInfo that returns either the ceActivityCompletedDate
    /// value or the distantPast Date constant if no CeActivity has been assigned to the object.
    var completedActivityDate: Date {
        completedCe?.ceActivityCompletedDate ?? Date.distantPast
    }//: completedActivityDate
    
    var formattedActivityCompletionDate: String {
        completedActivityDate.formatDateIntoHyphenedString()
    }//: formattedActivityCompletionDate
    
    
    
    // MARK: - METHODS
    
    /// CoreData helper method for CertificateInfo that sets the String value for the certType property
    /// using one of the CertType enum values (whose raw value is a String)
    /// - Parameter type: CertType enum value corresponding to whether the certificate being
    /// saved is an image or pdf file
    func setCertificateMediaType(as type: CertType) {
        certType = type.rawValue
    }//: setCertificateMediaType(as)
    
}//: EXTENSION
