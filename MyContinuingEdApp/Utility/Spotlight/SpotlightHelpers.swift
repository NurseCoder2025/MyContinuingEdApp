//
//  SpotlightHelpers.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/29/25.
//

import Foundation
import SwiftUI

private struct SpotlightCentralKey: EnvironmentKey {
    static let defaultValue: SpotlightCentral? = nil
}

extension EnvironmentValues {
    var spotlightCentral: SpotlightCentral? {
        get {
            self[SpotlightCentralKey.self]
        } set {
            self[SpotlightCentralKey.self] = newValue
        }
    }
}

