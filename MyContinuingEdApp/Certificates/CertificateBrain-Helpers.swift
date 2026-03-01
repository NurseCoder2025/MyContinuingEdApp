//
//  CertificateBrain-Helpers.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/26/26.
//

import Foundation
import SwiftUI

private struct CertificateBrainKey: EnvironmentKey {
    static let defaultValue: CertificateBrain? = nil
}//: CertificateBrainKey


extension EnvironmentValues {
    var certificateBrain: CertificateBrain? {
        get {
            self[CertificateBrainKey.self]
        } set {
            self[CertificateBrainKey.self] = newValue
        }
    }
}//: EXTENSION
