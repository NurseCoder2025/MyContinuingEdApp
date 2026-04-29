//
//  ActivityCertificateImageView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/29/25.
//

// Purpose: To display all UI controls related to the CeActivty's certificate (binary data)
// property, along with code related to the deletion and changing of an activity's certificate
// image or PDF

import SwiftUI
import UIKit

struct ActivityCertificateImageView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    @ObservedObject var activity: CeActivity
    @StateObject var viewModel: ViewModel
    
    // For holding binary data for a new certificate that the
    // user selects using CertificatePickerView which is passed up
    // to it via an @Binding property.
    @State private var certificateData: Data?
    
    // Alerts
    @State private var showChangeCertificateErrorAlert: Bool = false
    
    
    // MARK: - COMPUTED PROPERTIES
   
    
    // MARK: - BODY
    var body: some View {
        Group {
            // MARK: - Certificate Image
            Section("Certificate Image") {
                CertificatePickerView(
                    activity: activity,
                    certificateData: $certificateData
                )//: CertificatePickerView
                
                
            }//: Certificate Section
        }//: GROUP
        // MARK: - ON APPEAR
      
        // TODO: Replace onAppear code
       
        
        // MARK: - ON CHANGE
        .onChange(of: certificateData) { newCert in
            if let certData = newCert {
                // TODO: Replace with new view model method for changing certificates
            }//: IF LET
        }//: onChange(of)
        
        // MARK: - ALERTS
        // MARK: Change CE Certificate Alert
        .alert("Change Certificate?", isPresented: $viewModel.showCertificateChangeWarning) {
            Button(role: .destructive) {
                if let newData = certificateData {
                    // TODO: Replace delete certificate method
                    do {
                        // TODO: Add view model methods for updating a certificate
                    } catch {
                        showChangeCertificateErrorAlert = true
                    }//: DO-CATCH
                }//: IF LET
            } label: {
                Text("Confirm")
            }//: BUTTON
            Button("Cancel", role: .cancel) {viewModel.certDisplayStatus = .loaded}
        } message: {
            Text("You already have a certificate saved for this activity. Are you sure you wish to change it?")
        }//: ALERT (change)
        
        // MARK: Delete CE Certificate Alert
        .alert("Delete Certificate", isPresented: $viewModel.showCertDeletionWarning) {
            // TODO: Add view model code for deleting a certificate
            Button("DELETE", role: .destructive) {}//: Delete Button
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you wish to delete the certificate? If using iCloud, then this will remove it from all your devices.")
        }//: ALERT (delete)
        
        // MARK: Change Error Alert
        .alert("Certificate Error", isPresented: $showChangeCertificateErrorAlert) {
            Button("OK"){}
        } message: {
            Text("There was a problem saving the new certificate you selected. Please ensure that it is a valid PDF or image (jpeg, png, tiff, heic) file. It's possible the file may be corrupted.")
        }//: ALERT (error)
        
        // MARK: Deletion Error
        .alert("Deletion Error", isPresented: $viewModel.showCertDeletErrorAlert) {
            Button("OK"){}
        } message: {
            Text(viewModel.errorAlertMessage)
        }//: ALERT (deletion error)
        
        // MARK: General Save Alert
        .alert("Certificate Save Error", isPresented: $viewModel.showSaveErrorAlert){
            Button("OK"){}
        } message: {
            Text(viewModel.errorAlertMessage)
        }//: ALERT

        
    }//: BODY
    // MARK: - INIT
    init(
        dataController: DataController,
        activity: CeActivity
    ){
        self.activity = activity
        let viewModel = ViewModel(
            dataController: dataController,
            activity: activity
        )
        _viewModel = StateObject(wrappedValue: viewModel)
    }//: INIT
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    
    
}//: PREVIEw
