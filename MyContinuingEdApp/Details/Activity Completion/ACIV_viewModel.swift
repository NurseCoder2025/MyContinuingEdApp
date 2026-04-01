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
        let dataController: DataController
        let certBrain: CertificateBrain
        
        let fileSystem = FileManager()
        
        @ObservedObject var activity: CeActivity
        
        @Published var certificateSavedYN: Bool = false
        @Published var certificateToShow: Certificate?
        
        @Published var certDisplayStatus: MediaLoadingState = .blank
        
        // Changing certificates
        @Published var showCertificateChangeWarning: Bool = false
        
        // Certificate document changes (i.e. downloading, etc.)
        @Published var certDocDownloadingProgress: String = ""
        
        // Certificate deletion properties
        @Published var showCertDeletionWarning: Bool = false
        @Published var showCertDeletErrorAlert: Bool = false
        
        // Properties for alerting the user about any errors encountered
        @Published var errorAlertTitle: String = ""
        @Published var errorAlertMessage: String = ""
        @Published var showSaveErrorAlert: Bool = false
        
        // Notifications
        let loadCompleted = Notification.Name(.certLoadingDoneNotification)
        let certDeleted = Notification.Name(.certDeletionCompletedNotification)
        let saveCompleted = Notification.Name(.certSaveCompletedNotification)
        let docChanged = CertificateDocument.stateChangedNotification
        
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
        @MainActor
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
                        try await cBrain.loader.loadSavedCertificate(for: specificCe)
                    }
                } catch {
                    self?.errorAlertTitle = "Certificate Loading Error"
                    self?.errorAlertMessage = self?.certBrain.errorMessage ?? "Unknown error"
                    self?.certDisplayStatus = .error
                }
            }//: TASK
        }//: loadExistingCert()
        
        @MainActor
        func deleteSavedCert() {
            guard certificateSavedYN else {return}
            
            Task {@MainActor [weak self] in
                do {
                    if let cBrain = self?.certBrain,
                    let selectedCE = self?.activity {
                        try await cBrain.writer.deleteCertificate(for: selectedCE)
                    }//: IF LET
                } catch {
                    self?.errorAlertTitle = "Certificate Deletion Error"
                    self?.errorAlertMessage = self?.certBrain.errorMessage ?? "Unknown error"
                    self?.showCertDeletErrorAlert = true
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
                // Warn users about changing an existing certificate
                showCertificateChangeWarning = true
            } else {
                // For adding a certificate to an activity that previously doesn't
                // have one
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
                        try await cBrain.writer.addNewCeCertificate(for: someCE, with: data, dataType: fileType)
                        self?.certDisplayStatus = .loaded
                    } catch {
                        self?.errorAlertTitle = "Certificate Save Error"
                        self?.errorAlertMessage =  cBrain.errorMessage
                        if self?.certBrain.handlingError == .saveLocationUnavailable {
                            self?.showSaveErrorAlert = true
                            self?.certDisplayStatus = .localOnly
                        } else {
                            self?.certDisplayStatus = .error
                        }
                    }//: DO-CATCH
                }//: IF LET
            }//: TASK
        }//: saveLoadedCertificate()
        
        
        /// Private method for handling situations where different CertificateDocument versions are in conflict
        /// - Parameter doc: CertificateDocument with the conflicting versions
        ///
        /// This method handles the conflict by removing alll older file versions, keeping only the current one via the
        /// NSFileVersion static method removeOtherVersionsOfItem(at:).
        private func resolveConflictingCertVersions(for doc: CertificateDocument) {
            Task{@MainActor in
                if let assignedCoordinator = await certBrain.coordManager.getCoordinatorFor(activity: activity) {
                    let docURL = assignedCoordinator.fileURL
                    do {
                        try NSFileVersion.removeOtherVersionsOfItem(at: docURL)
                    } catch {
                        NSLog(">>> Error removing older versions of \(docURL.lastPathComponent): \(error.localizedDescription)")
                    }//: DO-CATCH
                }//: IF LET
            }//: TASK
        }//: resolveConflictingCertDocs(_)
        
        // MARK: - SELECTORS
        
        @objc private func handleCertLoaded(_ notification: Notification) {
            Task{@MainActor [weak self] in
                self?.certificateToShow = self?.certBrain.loader.selectedCertificate
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
        
        @objc private func handleCertDocStateChange(_ notification: Notification) {
            if let docToLoad = certBrain.loader.documentToOpen {
                let currentStatus = docToLoad.documentState
                switch currentStatus {
                case .progressAvailable:
                    certDisplayStatus = .loading
                    certDocDownloadingProgress = docToLoad.progress?.localizedDescription ?? ""
                case .savingError:
                    errorAlertMessage = "An error was encountered while trying to save the certificate."
                    showSaveErrorAlert = true
                case .inConflict:
                    resolveConflictingCertVersions(for: docToLoad)
                case .editingDisabled:
                    errorAlertMessage = "Waiting on the system to finish processing the certificate before it can be loaded..."
                    NSLog(">>> Loading is delayed due to the CertificateDocument being presently busy per the documentState property of .editingDisabled.")
                default:
                    if certificateToShow == nil {
                        certBrain.loader.retrieveCertImage(from: docToLoad)
                    }
                }//: SWITCH
            }//: IF LET
        }//: handleCertDocStateChange()
        
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
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleCertDocStateChange(_:)),
                name: docChanged,
                object: nil
            )
            
            
        }//: INIT
        // MARK: - DEINIT
        deinit {
            NotificationCenter.default.removeObserver(self)
        }//: DEINIT
        
    }//: VIEWMODEL
    
}//: ActivityCertificateImageView
