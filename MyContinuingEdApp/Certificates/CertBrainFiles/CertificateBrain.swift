//
//  CertificateController.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/10/26.
//

import CloudKit
import CoreData
import Foundation
import UIKit


final class CertificateBrain: ObservableObject {
    // MARK: - PROPERTIES
    private let fileExtension: String = .certFileExtension
    private let fileSystem = FileManager()
    
    // Error handling properties
     @Published var errorMessage: String = ""
     var handlingError: FileIOError = .noError
    
    // Coordinator loading
    @Published private(set) var isReady: Bool = false
    
    // Loaded certificate properties
    var loadedCertificates: [Certificate] = []
    
    let dataController: DataController
    
    // MARK: - Sub objects (as regular classes)
    
    lazy var coordManager: CertCoordinatorManager = {
        CertCoordinatorManager(dataController: dataController, certBrain: self)
    }()//: coordManager
    
    lazy var utility: CertUtility = {
        CertUtility(dataController: dataController, certBrain: self, coordManager: coordManager)
    }()//: utility
    
    lazy var writer: CertificateWriter = {
        CertificateWriter(dataController: dataController, certBrain: self, coordManager: coordManager, utility: utility)
    }()//: writer
    
    lazy var cloudManager: CertCloudManager = {
        CertCloudManager(certBrain: self, dataController: dataController, coordManager: coordManager, mover: mover, utility: utility)
    }()//: cloudManager
    
    lazy var mover: CertificateMover = {
        CertificateMover(certBrain: self, coordManager: coordManager, utility: utility)
    }()//: mover
    
    lazy var loader: CertificateLoader = {
        CertificateLoader(dataController: dataController, certBrain: self, coordManager: coordManager)
    }()//: loader
   
    // MARK: - FILE STORAGE
    
    /// Computed property in CertificateBrain that indicates whether local or iCloud storage is to
    /// be used for the purpose of creating URLs for certificate media files.
    ///
    /// - Note: The data type is the StorageToUse enum and its value depends on
    /// the useLocalStorage computed property of the iCloudAvailability enum.
    var storageAvailability: StorageToUse {
        switch dataController.iCloudAvailability.useLocalStorage {
        case true:
            return .local
        case false:
            return .cloud
        }//: SWITCH
    }//: currentStorageChoice
    
    // MARK: Top-Level Folder URL
    
    /// Computed property in CertificateBrain that sets the URL for the top-level directory into which all
    /// CE certificates are to be saved to in iCloud: "Documents/Certificates".  Nil is returned if the url
    /// for the app's directory in the user's iCloud drive account cannot be made.
    var cloudCertsFolderURL: URL? {
        if let existingURL = dataController.userCloudDriveURL, dataController.prefersCertificatesInICloud,
            storageAvailability == .cloud {
            let customCloudURL = existingURL.appending(path: "Documents", directoryHint: .isDirectory).appending(path: "Certificates", directoryHint: .isDirectory)
            return customCloudURL
        } else {
            return nil
        }
    }//: cloudCertsURL
    
    
    // MARK: - PREVIEW
    #if DEBUG
    static var preview: CertificateBrain = {
        let dcPreview = DataController.preview
        let cbPreview = CertificateBrain(dataController: dcPreview)
        return cbPreview
    }()
    #endif
    // MARK: - INIT
    
    /// Initializer for the CertificateController class.
    /// - Parameter dataController: DataController instance passed in from the environment
    ///
    /// Upon initialization, the class first decodes the masterCertificateList.json file and places all values into the allCertificates set.
    /// Then, it schedules a task for running the updateCertificateData method, which will look for any new binary files saved to the
    /// local and iCloud Certificates folder and then create corresponding CECertificate model objects for them and add them to the
    /// allCertificates set.  This will ensure that the locally-saved list will stay in-sync with whatever is on the user's iCloud and on the
    /// local device.
    init(dataController: DataController) {
        self.dataController = dataController
      
    }//: INIT
    
    // MARK: - DEINIT
    deinit {
        NotificationCenter.default.removeObserver(self)
        
    }//: DEINIT
}//: CertificateController
