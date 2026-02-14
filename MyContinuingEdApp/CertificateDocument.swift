//
//  CertificateDocument.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/14/26.
//

import CloudKit
import Foundation
import UIKit


final class CertificateDocument: UIDocument {
    let certData: Data
    let certModel: CECertificate
    
    // MARK: - INIT
    init(certData: Data, certModel: CECertificate) {
        self.certData = certData
        self.certModel = certModel
    }
    
}//: CertifiedDocument
