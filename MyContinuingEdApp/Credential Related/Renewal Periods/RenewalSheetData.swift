//
//  RenewalSheetData.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 10/16/25.
//

import Foundation


/// Struct used as a data wrapper for credential and renewal objects being passed up from grandchild and child views to the parent.  This
/// helps prevent data sync issues between the objects being set and the sheet being presented, which is where they are being presented
/// to.
struct RenewalSheetData: Identifiable {
    let id = UUID()
    let credential: Credential
    let renewal: RenewalPeriod?
}
