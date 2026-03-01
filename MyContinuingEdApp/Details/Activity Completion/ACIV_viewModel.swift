//
//  ACIV_viewModel.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/26/26.
//

import Foundation
import SwiftUI
import PDFKit
import UIKit

extension ActivityCertificateImageView {
    // MARK: - VIEW MODEL
    final class ViewModel: ObservableObject {
        // MARK: - PROPERTIES
        var dataController: DataController
        var certBrain: CertificateBrain
        
        @ObservedObject var activity: CeActivity
        
        @Published var certificateSavedYN: Bool = false
        @Published var certificateToShow: Certificate?
        
        @Published var certDisplayStatus: MediaLoadingState = .blank
        
        // Changing certificates
        @Published var showCertificateChangeWarning: Bool = false
        
        // Certificate deletion properties
        @Published var showCertDeletionWarning: Bool = false
        
        // Properties for alerting the user about any errors encountered
        @Published var errorAlertTitle: String = ""
        @Published var errorAlertMessage: String = ""
        
        // Notifications
        let loadCompleted = Notification.Name(.certLoadingDoneNotification)
        let certDeleted = Notification.Name(.certDeletionCompletedNotification)
        let saveCompleted = Notification.Name(.certSaveCompletedNotification)
        
        // MARK: - METHODS
        
        /// Method for loading the saved CE certificate object for the specific CeActivity in the UI.
        ///
        /// This method updates the @Published previousCertificate property with the Certificate-conforming
        /// object that was located by the loadSavedCertificate(for) method.
        ///
        /// - Important: This function must run on the MainActor as it will be updated published
        /// properties for handling loading errors and notifying the user about them along with the data
        /// that will be used by the UI to display the certificate to the user.
        ///
        /// - Note: Error handling is accomplished via an observer object that runs the handleCertLoaded
        /// method to update the errorAlertMessage and errorAlertTitle properties if an error was encountered
        /// in the loadSavedCertificate(for) method.
        func loadExistingCert() {
            guard certificateSavedYN else {return}
            certDisplayStatus = .loading
            
            Task {
                await certBrain.loadSavedCertificate(for: activity)
            }//: TASK
        }//: loadExistingCert()
        
        func deleteSavedCert() {
            guard certificateSavedYN else {return}
            
            Task {
                await certBrain.deleteCertificate(for: activity)
            }//: TASK
        }//: deleteSavedCert()
        
        /// ViewModel method that sets the value of the @Published certificateToShow property
        /// to whatever PDF or Image data is passed in as an argument.
        /// - Parameter data: Binary Data type corresponding to a PDF or UIImage file
        func updateCertificate(with data: Data)  {
            if let pdfData = PDFDocument(data: data) {
               certificateToShow = pdfData
            } else if let imageData = HelperFunctions.decodeCertImage(from: data) {
                certificateToShow = imageData
            }
        }//: updateCertificate(with)
        
        /// ViewModel method that takes in binary data passed in from CertificatePickerView and either creates
        /// a new Certificate object with the data (using updateCertificate(with) or triggers the boolean for showing
        /// the user an alert to confirm they wish to change the certificate for the CE activity.
        /// - Parameter data: Binary Data type (should be an image or PDF)
        func addOrChangeCertificate(with data: Data) {
            certDisplayStatus = .loading
            if certificateToShow != nil {
                showCertificateChangeWarning = true
            } else {
                updateCertificate(with: data)
                saveLoadedCertificate(with: data)
            }
        }//: addOrChangeCertificate(with)
        
        func saveLoadedCertificate(with data: Data) {
            guard let loadedCert = certificateToShow else { return }
            
            let fileType: MediaType
            switch loadedCert.certificateType {
            case .image:
                fileType = .image
            case .pdf:
                fileType = .pdf
            }//: SWITCH
            
            Task {
                await certBrain.addNewCeCertificate(for: activity, with: data, dataType: fileType)
            }//: TASK
        }//: saveLoadedCertificate()
        
        // MARK: - SELECTORS
        
        @objc private func handleCertLoaded(_ notification: Notification) {
            if certBrain.handlingError != .noError {
                errorAlertTitle = "Certificate Loading Error"
                errorAlertMessage = certBrain.errorMessage
                certDisplayStatus = .error
            } else if let savedCert = certBrain.selectedCertificate {
                certificateToShow = savedCert
                certDisplayStatus = .loaded
            }//: IF ELSE LET
        }//: handleCertLoaded
        
        @objc private func handleCertDeleted(_ notification: Notification) {
            if certBrain.handlingError != .noError {
                errorAlertTitle = "Certificate Deletion Error"
                errorAlertMessage = certBrain.errorMessage
                certDisplayStatus = .error
            } else {
                certDisplayStatus = .blank
                certificateToShow = nil
                activity.hasCompletionCertificate = false
                certificateSavedYN = false
            }
        }//: handleCertDeleted()
        
        @objc private func handleCertSaved(_ notification: Notification) {
            if certBrain.handlingError != .noError {
                errorAlertTitle = "Certificate Save Error"
                errorAlertMessage = certBrain.errorMessage
            } else {
                certDisplayStatus = .loaded
                activity.hasCompletionCertificate = true
                certificateSavedYN = true
            }//: IF ELSE
        }//: handleCertSaved()
        
        // MARK: - INIT
        init(
            dataController: DataController,
            certBrain: CertificateBrain,
            activity: CeActivity
        ) {
            self.dataController = dataController
            self.certBrain = certBrain
            self.activity = activity
            
            self.certificateSavedYN = activity.hasCompletionCertificate
            
            // MARK: - OBSERVERS
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleCertLoaded(_:)),
                name: loadCompleted,
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleCertDeleted(_:)),
                name: certDeleted,
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleCertSaved(_:)),
                name: saveCompleted,
                object: nil
            )
            
            
        }//: INIT
        // MARK: - DEINIT
        deinit {
            NotificationCenter.default.removeObserver(self)
        }//: DEINIT
        
    }//: VIEWMODEL
    
}//: ActivityCertificateImageView
