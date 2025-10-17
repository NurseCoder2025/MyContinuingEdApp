//
//  DebuggingFunctions.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/24/25.
//


// Purpose: Store global functions that can help with debugging issues with the app

import Foundation


/// Created this function to help debug an issue where RenewalPeriod objects were apparently created via the RenewalPeriodView sheet,
///  BUT after saving the object and dismissing the sheet nothing showed up under the Credential section header.
/// - Parameter credential: Credential that should have a renewal period associated with it (that is to be checked)
func diagnoseRenewalNotShowing(dataController: DataController, for credential: Credential?) {
    let context = dataController.container.viewContext
    let request = RenewalPeriod.fetchRequest()
    let allRenewals = (try? context.fetch(request)) ?? []
    
    if let passedCred = credential {
        print("--------------- Renewal Period Diagnostic -------------------")
        print("Renewal Period objects found for \(passedCred.credentialName)")
        for renewal in allRenewals {
            if renewal.credential == passedCred {
                print(renewal.renewalPeriodName)
            }
        }
        print("************************************************")
        print("")
        print("All Renewal Objects in Persistent storage:")
        for renewal in allRenewals {
            print(renewal.renewalPeriodName)
            print("Associated with \(renewal.credential?.credentialName ?? "Nothing found")")
        }
    }
}
