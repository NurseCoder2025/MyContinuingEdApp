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
            guard certificateSavedYN, certDisplayStatus != .loaded else {return}
            certDisplayStatus = .loading
            
            NotificationCenter.default.removeObserver(self, name: loadCompleted, object: nil)
            
            // Registering an observer before loading the certificate in order
            // to prevent a race condition where the load method completes
            // before the observer is registered
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleCertLoaded(_:)),
                name: loadCompleted,
                object: nil
            )
            
            Task {@MainActor [weak self] in
                do {
                    if let specificCe = self?.activity,
                        let cBrain = self?.certBrain {
                        try await cBrain.loadSavedCertificate(for: specificCe)
                    }
                } catch {
                    self?.errorAlertTitle = "Certificate Loading Error"
                    self?.errorAlertMessage = self?.certBrain.errorMessage ?? "Unknown error"
                    self?.certDisplayStatus = .error
                }
            }//: TASK
        }//: loadExistingCert()
        
        func deleteSavedCert() {
            guard certificateSavedYN else {return}
            
            Task {@MainActor [weak self] in
                do {
                    if let cBrain = self?.certBrain,
                    let selectedCE = self?.activity {
                        try await cBrain.deleteCertificate(for: selectedCE)
                    }//: IF LET
                } catch {
                    self?.errorAlertTitle = "Certificate Deletion Error"
                    self?.errorAlertMessage = self?.certBrain.errorMessage ?? "Unknown error"
                    self?.certDisplayStatus = .error
                }//: DO - CATCH
            }//: TASK
        }//: deleteSavedCert()
        
        /// ViewModel method that sets the value of the @Published certificateToShow property
        /// to whatever PDF or Image data is passed in as an argument.
        /// - Parameter data: Binary Data type corresponding to a PDF or UIImage file
        @MainActor
        func updateCertificate(with data: Data) throws {
            if let pdfData = PDFDocument(data: data) {
               certificateToShow = pdfData
            } else if let imageData = HelperFunctions.decodeCertImage(from: data) {
                certificateToShow = imageData
            } else {
                NSLog(">>>The data argument for updateCertificate(with) was not a PDF or image file that the decodeCertImage(from) method could identify.")
                throw FileIOError.cantIdentifyFileType
            }
        }//: updateCertificate(with)
        
        /// ViewModel method that takes in binary data passed in from CertificatePickerView and either creates
        /// a new Certificate object with the data (using updateCertificate(with) or triggers the boolean for showing
        /// the user an alert to confirm they wish to change the certificate for the CE activity.
        /// - Parameter data: Binary Data type (should be an image or PDF)
        @MainActor
        func addOrChangeCertificate(with data: Data) {
            certDisplayStatus = .loading
            if certificateToShow != nil {
                showCertificateChangeWarning = true
            } else {
                do {
                    try updateCertificate(with: data)
                    saveLoadedCertificate(with: data)
                } catch {
                    errorAlertTitle = "Certificate Error"
                    errorAlertMessage = "Unable to save certificate because the underlying data is either not in a supported format (PDF or supported image format like jpeg, png, or tiff) or it might have been corrupted somehow."
                    certDisplayStatus = .error
                }//: DO-CATCH
            }//: IF - ELSE
        }//: addOrChangeCertificate(with)
        
        @MainActor
        func saveLoadedCertificate(with data: Data) {
            guard let loadedCert = certificateToShow else { return }
            
            let fileType: MediaType
            switch loadedCert.certificateType {
            case .image:
                fileType = .image
            case .pdf:
                fileType = .pdf
            }//: SWITCH
            
            Task {@MainActor [weak self] in
                if let cBrain = self?.certBrain,
                    let someCE = self?.activity {
                    do {
                        try await cBrain.addNewCeCertificate(for: someCE, with: data, dataType: fileType)
                    } catch {
                        self?.errorAlertTitle = "Certificate Save Error"
                        self?.errorAlertMessage =  cBrain.errorMessage
                        self?.certDisplayStatus = .error
                    }
                }//: IF LET
            }//: TASK
        }//: saveLoadedCertificate()
        
        // MARK: - SELECTORS
        
        @objc private func handleCertLoaded(_ notification: Notification) {
            Task{@MainActor [weak self] in
                self?.certificateToShow = self?.certBrain.selectedCertificate
                self?.certDisplayStatus = .loaded
            }//: TASK
        }//: handleCertLoaded
        
        @objc private func handleCertDeleted(_ notification: Notification) {
            Task{@MainActor [weak self] in
                self?.certDisplayStatus = .blank
                self?.certificateToShow = nil
                self?.activity.hasCompletionCertificate = false
                self?.certificateSavedYN = false
            }//: TASK
        }//: handleCertDeleted()
        
        @objc private func handleCertSaved(_ notification: Notification) {
            Task{@MainActor [weak self] in
                self?.certDisplayStatus = .loaded
                self?.activity.hasCompletionCertificate = true
                self?.certificateSavedYN = true
            }//: TASK
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
