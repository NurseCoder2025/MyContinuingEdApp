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
        
        // Observer Notifications
        let dataLoaded = Notification.Name(.certGettingRawDataDone)
        
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
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleDataLoaded(_:)),
                name: dataLoaded,
                object: nil
            )
            
            Task {
                certData = await certBrain.getSavedCertData(for: activity)
            }//: TASK
        }//: loadCertData(for)
        
        // MARK: - SELECTORS
        
        /// Private selector method that runs upon completion of the CertificateBrain's getSavedCertData(for) method by
        /// taking the certificate binary data and creating a temporary URL for the file so it can be shared/exported out of the
        /// app.
        /// - Parameter notification: Notification object with the name of the String constant .certGettingRawDataDone
        ///
        /// - Note: This method removes the observer created by the loadCertData(for) method at the end.  If an error was
        /// encountered by the getSavedCertData(for) method, then the view model's errorAlertTitle and errorAlertMessage
        /// published properties will be set so that the info will be displayed to the user. A cooresponding log entry will be made
        /// as well.
        @objc private func handleDataLoaded(_ notification: Notification) {
            if let loadedData = certData {
                fileShareURL = HelperFunctions.createTempFileURL(for: activity, with: loadedData)
                    if let linkURL = fileShareURL {
                        sharingLinkStatus = .loaded
                    } else {
                        sharingLinkStatus = .error
                        errorAlertTitle = "Sharing Link Error"
                        errorAlertMessage = "Unable to create a sharing link for the certificate."
                        showErrorAlert = true
                        NSLog(">>>Error creating the URL needed for creating a ShareLink object for the activity \(activity.ceTitle). The raw binary data was loaded correctly, but the createTempFileURL method returned a nil value.")
                        NSLog(">>>Specific URL error encountered: \(certBrain.errorMessage)")
                    }//: IF ELSE (linkURL)
            } else {
                if certBrain.handlingError != .noError {
                    errorAlertTitle = "Sharing Link Error"
                    errorAlertMessage = "Unable to load the certificate data needed for sharing it."
                    sharingLinkStatus = .error
                    showErrorAlert = true
                }//: IF
                NSLog(">>>Unable to create URL for sharing a CE certificate for \(activity.ceTitle) because the raw data could not be loaded.")
                NSLog(">>>Specific error encountered: \(certBrain.errorMessage)")
            }//: IF ELSE
            
            NotificationCenter.default.removeObserver(self, name: dataLoaded, object: nil)
        }//: handleDataLoaded
        
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
