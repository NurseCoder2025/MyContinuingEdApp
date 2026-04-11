//
//  CertificateDataWrapper.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/26/26.
//

import Foundation

// TODO: Remove wrapper - no longer needed

/// Struct used in ActivityCertificateImageView to allow users to revert
/// back to a previous CE certificate after selecting a new one, if needed.
///
/// The two main properties in this wrapper are the newData (non-optional) Data
/// type property and the optional oldData Data type property.
struct CertificateDataWrapper: Identifiable {
    let id = UUID()
    let newData: Certificate
    let oldData: Certificate?
}//: CertificateDataWrapper
