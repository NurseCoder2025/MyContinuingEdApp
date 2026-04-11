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
        
        
        // MARK: - METHODS
        
       
        
        // MARK: - INIT
        init(
            dataController: DataController,
            activity: CeActivity
        ) {
            self.dataController = dataController
            self.activity = activity
            
            self.certificateSavedYN = activity.hasCompletionCertificate
            
            
          
            
        }//: INIT
        // MARK: - DEINIT
        deinit {
            NotificationCenter.default.removeObserver(self)
        }//: DEINIT
        
    }//: VIEWMODEL
    
}//: ActivityCertificateImageView
