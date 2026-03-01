//
//  CertificateShareView-ViewModel.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/27/26.
//

import Foundation
import SwiftUI


extension CertificateShareView {
    
    final class ViewModel: ObservableObject {
        // MARK: - PROPERTIES
        @ObservedObject var activity: CeActivity
        @Published var certData: Data?
        @Published var fileShareURL: URL?
        
        @Published var sharingLinkStatus: LoadState = .loading
        
        // Error handling properties
        @Published var showErrorAlert: Bool = false
        @Published var errorAlertTitle: String = ""
        @Published var errorAlertMessage: String = ""
        
        private var certBrain: CertificateBrain
        
        // MARK: - METHODS
        
        /// ViewModel method for obtaining the raw binary data for a saved CE certificate assigned to a
        /// specific CeActivity object and assigning the data value to the certData optional property.
        /// - Parameter activity: CeActivity with a saved certificate that the user wishes to share/export
        /// out of the app.
        ///
        /// As part of this method, an observer object is created that will run a follow-up method once a notification
        /// is received that the getSavedCertData(for) method is done running.  Then it runs the CertificateBrain method
        /// and assigns the resulting value to the certData published property.
        ///
        /// - Note: This method was NOT designated as private in order to allow the user to force a "refresh" or retry
        /// the loading of certificate data in the event it fails somehow.  This method is called by button in for the error
        /// loading case in the view.
        func loadCertData(for activity: CeActivity) {
            guard activity.hasCompletionCertificate else {return}
            
            Task {@MainActor [weak self] in
                if let cBrain = self?.certBrain, let someCE = self?.activity {
                    do {
                        self?.certData = try await cBrain.getSavedCertData(for: someCE)
                    } catch {
                        self?.sharingLinkStatus = .error
                        self?.errorAlertTitle = "Sharing Link Error"
                        self?.errorAlertMessage = "Unable to load the certificate data needed for sharing it."
                        self?.showErrorAlert = true
                        
                    }//: DO-CATCH (getSavedCertData(for))
                    
                    if let loadedData = self?.certData {
                        do {
                            self?.fileShareURL = try HelperFunctions.createTempFileURL(for: someCE, with: loadedData)
                            self?.sharingLinkStatus = .loaded
                        } catch {
                            self?.sharingLinkStatus = .error
                            self?.errorAlertTitle = "Sharing Link Error"
                            self?.errorAlertMessage = "Unable to create a sharing link for the certificate."
                            self?.showErrorAlert = true
                            NSLog(">>>Error creating the URL needed for creating a ShareLink object for the activity \(someCE.ceTitle). The raw binary data was loaded correctly, but the createTempFileURL method returned a nil value.")
                            NSLog(">>>Specific URL error encountered: \(cBrain.errorMessage)")
                        }//: DO-CATCH (loadedData)
                        
                    }//: IF LET
                }//: IF LET
            }//: TASK
        }//: loadCertData(for)
        
        
        // MARK: - INIT
        init(
            activity: CeActivity,
            certData: Data? = nil,
            fileShareURL: URL? = nil,
            certBrain: CertificateBrain
        ) {
            self.activity = activity
            self.certData = certData
            self.fileShareURL = fileShareURL
            self.certBrain = certBrain
            
            loadCertData(for: activity)
            
        }//: INIT
        
    }//: VIEW MODEL
    
}//: EXTENSION
