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
    @Environment(\.certificateBrain) var certificateBrain
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
    var paidStatus: PurchaseStatus {
        switch dataController.purchaseStatus {
        case PurchaseStatus.proSubscription.id:
            return .proSubscription
        case PurchaseStatus.basicUnlock.id:
            return .basicUnlock
        default:
            return .free
        }
    }//: paidStatus
    
    // MARK: - BODY
    var body: some View {
        Group {
            // MARK: - Certificate Image
            if activity.activityCompleted {
                if paidStatus == .free {
                    PaidFeaturePromoView(
                        featureIcon: "doc.text.image.fill",
                        featureItem: "Save CE Certificate",
                        featureUpgradeLevel: .basicAndPro
                    )
                } else {
                    Section("Certificate Image") {
                        CertificatePickerView(
                            activity: activity,
                            certificateData: $certificateData
                        )//: CertificatePickerView
                        
                        switch viewModel.certDisplayStatus {
                        case .blank:
                            NoItemView(
                                noItemTitleText: "No CE Certificate",
                                noItemMessage: "A certificate has not yet been saved for this CE activity.",
                                noItemImage: "trophy.circle.fill"
                            )
                            .accessibilityLabel("No CE Certificates have been added for this activity yet.")
                        case .loading:
                            VStack {
                                ProgressView("Loading certificate...")
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Loading certificate for this activity...")
                            }//: VSTACK
                        case .loaded:
                            CertificatePreviewView(savedCert: viewModel.certificateToShow)
                            
                            // MARK: Certificate DETAILS & SHARING
                            if activity.hasCompletionCertificate,
                                let certBrain = certificateBrain {
                                    CertificateShareView(activity: activity, certBrain: certBrain)
                                
                                // MARK: DELETE CERTIFICATE
                                DeleteObjectButtonView(buttonText: "Delete Certificate") {
                                    viewModel.showCertDeletionWarning = true
                                }//: DeleteObjectButtonView
                            }//: IF-LET (hasCompletionCertificate, certBrain)
                        case .error:
                            NoItemView(
                                noItemTitleText: viewModel.errorAlertTitle,
                                noItemMessage: viewModel.errorAlertMessage,
                                noItemImage: "exclamationmark.triangle"
                            )
                            .accessibilityLabel(Text(viewModel.errorAlertMessage))
                        }//: SWITCH
                    }//: Certificate Section
                }//: IF ELSE
            } //: IF activity completed
        }//: GROUP
        // MARK: - ON APPEAR
        .onAppear {
            viewModel.loadExistingCert()
        }//: ON APPEAR
        
        // MARK: - ON CHANGE
        .onChange(of: certificateData) { newCert in
            if let certData = newCert {
                viewModel.addOrChangeCertificate(with: certData)
            }//: IF LET
        }//: onChange(of)
        
        // MARK: - ALERTS
        // MARK: Change CE Certificate Alert
        .alert("Change Certificate?", isPresented: $viewModel.showCertificateChangeWarning) {
            Button(role: .destructive) {
                if let newData = certificateData {
                    do {
                        try viewModel.updateCertificate(with: newData)
                        viewModel.saveLoadedCertificate(with: newData)
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
            Button("DELETE", role: .destructive) {viewModel.deleteSavedCert()}//: Delete Button
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

        
    }//: BODY
    // MARK: - INIT
    init(
        dataController: DataController,
        certificateBrain: CertificateBrain,
        activity: CeActivity
    ){
        self.activity = activity
        let viewModel = ViewModel(
            dataController: dataController,
            certBrain: certificateBrain,
            activity: activity
        )
        _viewModel = StateObject(wrappedValue: viewModel)
    }//: INIT
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    
    
}//: PREVIEw
