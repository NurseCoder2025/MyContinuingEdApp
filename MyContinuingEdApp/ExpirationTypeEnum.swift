//
//  ExpirationTypeEnum.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/19/25.
//

import Foundation

/// This enum is specifically used for the computed property experiationStatus in the
/// ActivityRow struct.  This enum is used to provide specific values indicating
/// whether a given activity has already expired, is about to expire (within the next
/// 30 days) or is still good.
enum ExpirationType: String, CaseIterable, Hashable {
    case expired = "Expired"
    case expiringSoon = "Expiring Soon"
    case finalDay = "Final Day"
    case stillValid = "Valid"
    case finishedActivity = "Finished Activity"
    case all = "All"
}
