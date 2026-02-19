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
}//: EXTENSION


extension PDFDocument: Certificate {
    var certificateType: CertType {.pdf}
}//: EXTENSION

