//
//  CertificateLoader.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/31/26.
//
import CloudKit
import CoreData
import Foundation
import UIKit

final class CertificateLoader: ObservableObject {
    // MARK: - PROPERTIES
    
    @Published var documentToOpen: CertificateDocument?
    
    /// Published property for holding a PDF/Image (Certificate) object for a specific
    /// CeActivity as obtained by the loadSavedCertificate(for) method.
    @Published var selectedCertificate: Certificate?
    
   private let dataController: DataController
   private let certBrain: CertificateBrain
   private let coordManager: CertCoordinatorManager
    
    // MARK: - METHODS
    
    /// Method for opening an existing CE certificate file that has been saved and storing the image or PDF data for use in
    /// the user interface via the selectedCertificate published property.
    /// - Parameter activity: CeActivity object for which a CE certificate was assigned to
    ///
    /// - Important: This method relies on the mediaAs property within the certificate's metadata file (which is also
    /// saved to the respective coordinator object) to determine which of the two computed properties in CertificateData to
    /// call: fullCertificate (for the PDF) or certImageThumbnail (for images). The result of either computed property is what is
    /// assigned to the selectedCertificate property in the CertificateBrain class.
    func loadSavedCertificate(for activity: CeActivity) async throws {
        if let assignedCoordinator = await coordManager.getCoordinatorFor(activity: activity) {
            let savedCert = await CertificateDocument(certURL: assignedCoordinator.fileURL)
            documentToOpen = savedCert
            if await savedCert.docOkToOpen() {
                retrieveCertImage(from: savedCert)
            } else {
                NSLog(">>> The CertificateDocument could not be opened at this time due to a status other than closed or normal.")
                certBrain.handlingError = .loadingError
                certBrain.errorMessage = "Attempted to load the certificate while it was in a state that could not be read by the system. Another attempt to load it will be made automatically."
                throw FileIOError.loadingError
            }//: IF ELSE (documentState.contains)
        } else {
            await MainActor.run {
                certBrain.handlingError = .loadingError
                certBrain.errorMessage = "Unable to load the certificate data because the app was unable to locate where the data was saved to."
            }//: MAIN ACTOR
            NSLog(">>>Certificate Coordinator error: Unable to find the coordinator for the CE activity \(activity.ceTitle)")
            throw certBrain.handlingError
        }//: IF ELSE
    }//: loadSavedCertificate
    
    /// CertificateBrain method for retrieving the raw binary data for a saved CE certificate that is associated
    /// with a specific CE activity.
    /// - Parameter activity: CeActivity with a cooresponding CE certificate (as determined by the coordinator)
    /// - Returns: Data object if the certificate was found and the raw data read, nil if not
    func getSavedCertData(for activity: CeActivity) async throws -> Data? {
        var dataToReturn: Data?
        if coordManager.currentCoordinators.isEmpty {
            await coordManager.decodeCoordinatorList()
        }//: IF (isEmpty)
        
        let coordinators = coordManager.currentCoordinators
        guard let certCoordinator = coordinators.first(where: { coordinator in
            coordinator.assignedObjectID == activity.activityID
        }) else {
            await MainActor.run {
                certBrain.handlingError = .loadingError
                certBrain.errorMessage = "Unable to load the certificate data because the app was unable to locate where the data was saved to."
            }//: MAIN ACTOR
            NSLog(">>>Certificate Coordinator error: Unable to find the coordinator for the CE activity \(activity.ceTitle)")
            throw certBrain.handlingError
        }//: GUARD
        
        let savedCert = await CertificateDocument(certURL: certCoordinator.fileURL)
        if await savedCert.open() {
            let docData = await savedCert.certBinaryData
            if let rawData = docData.certData {
                dataToReturn = rawData
            } else {
                await MainActor.run {
                    certBrain.handlingError = .loadingError
                    certBrain.errorMessage = "Unable to read the binary data saved for the CE certificate."
                }//: MAIN ACTOR
                NSLog(">>>Error reading the raw data from the saved certificate for the CE activity \(activity.ceTitle)")
                NSLog(">>>The  certData property of the CertificateDocument object was nil.")
                throw certBrain.handlingError
            }//: IF ELSE
        } else {
            NSLog(">>>Certificate Coordinator error: Unable to open the certificate for the CE activity \(activity.ceTitle)")
            await MainActor.run {
                certBrain.handlingError = .loadingError
                certBrain.errorMessage = "Unable to get the certificate data because the app was unable to open the saved file."
            }//: MAIN ACTOR
            throw certBrain.handlingError
        }//: IF ELSE
       
        await savedCert.close()
        return dataToReturn
    }//: loadSavedCertData(for)
    
    func retrieveCertImage(from doc: CertificateDocument) {
        Task{@MainActor in
            let loadCompletedNotification = Notification.Name(.certLoadingDoneNotification)
            if doc.docOkToOpen(), await doc.open() {
                let certSavedAs = doc.certMetaData.mediaAs
                switch certSavedAs {
                case .image:
                    if let thumbImage = doc.certBinaryData.certImageThumbnail {
                        selectedCertificate = thumbImage
                        NotificationCenter.default.post(name: loadCompletedNotification, object: nil)
                    } else {
                        certBrain.handlingError = .loadingError
                        certBrain.errorMessage = "Unable to create the thumbnail image for the certificate assigned to this activity."
                        NSLog(">>>Error creating thumbnail image for the certificate saved at \(doc.certMetaData.fileVersion.fileLocation)")
                    }//: IF ELSE
                case .pdf:
                    if HelperFunctions.isPDF(doc.certBinaryData.certData) {
                        selectedCertificate = doc.certBinaryData.fullCertificate
                        NotificationCenter.default.post(name: loadCompletedNotification, object: nil)
                    } else {
                        certBrain.handlingError = .loadingError
                        certBrain.errorMessage = "Unable to load the PDF data for the certificate assigned to this activity."
                        NSLog(">>>Error loading PDF data for the certificate saved at \(doc.certMetaData.fileVersion.fileLocation)")
                        NSLog(">>> It's possible that the data actually represents an image and not a PDF.")
                    }//: IF ELSE
                case .audio:
                    return
                }//: SWITCH
            } else {
                // If opening the CertificateDocument fails...
                certBrain.handlingError = .loadingError
                certBrain.errorMessage = "Unable to load the certificate data from the saved file location."
                let docLocation = doc.certMetaData.fileVersion.fileLocation
                NSLog(">>>Error opening CertificateDocument at \(docLocation)")
                NSLog(">>>Final URL part: \(docLocation.lastPathComponent)")
                NSLog(">>>The CertificateDocument (UI Document subclass) open() method returned a false value.")
            }//: IF ELSE ( open() )
            
        }//: TASK
    }//: retrieveCertImage()
    
    // MARK: - INIT
    
    init(
        dataController: DataController,
        certBrain: CertificateBrain,
        coordManager: CertCoordinatorManager
    ) {
        self.dataController = dataController
        self.certBrain = certBrain
        self.coordManager = coordManager
    }//: INIT
    
}//: CLASS
