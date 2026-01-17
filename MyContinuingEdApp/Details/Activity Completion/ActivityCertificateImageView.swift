//
//  ActivityCertificateImageView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 9/29/25.
//

// Purpose: To display all UI controls related to the CeActivty's certificate (binary data)
// property, along with code related to the deletion and changing of an activity's certificate
// image or PDF

import PDFKit
import PhotosUI
import SwiftUI
import UIKit

struct ActivityCertificateImageView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var dataController: DataController
    @ObservedObject var activity: CeActivity
    
    // Properties related to changes with the CE certificate
    @State private var showCertificateChangeAlert: Bool = false
    @State private var certificateToConfirm: CertificateDataWrapper?
    @State private var previousCertificate: Data?
    @State private var okToShowAlert: Bool = true
    
    // Properties related to deleting the saved certificate
    @State private var showDeleteCertificateWarning: Bool = false
    
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
                            certificateData: $activity.completionCertificate
                        )
                        
                        if let data = activity.completionCertificate, data.count > 0 {
                            if isPDF(data) {
                                PDFKitView(data: data)
                                    .frame(height: 300)
                                    .accessibilityLabel("PDF view of your CE Certificate for this activity.")
                            } else if let certImage = decodeCertImage(from: data) {
                                Image(uiImage: certImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 300)
                                    .accessibilityLabel(Text("Image of your CE Certificate for this activity."))
                            } else {
                                Text("Unfortunately, the certificate you saved is not in a PDF or recognizable image format (jpg, png, tiff, gif, heiff). Try re-saving the image, take a picture of it with the camera, or convert the certificate file to a PDF or supported image.")
                                    
                            }
                        }//: IF LET (data)
                        
                        // MARK: - Certificate Sharing
                        if let data = activity.completionCertificate {
                            CertificateShareView(activity: activity, certificateData: data)
                            
                            Button(role: .destructive) {
                                showDeleteCertificateWarning = true
                            } label: {
                                Text("Delete Certificate")
                            }
                        }//: IF-LET (data)
                    }//: Certificate Section
                }//: IF ELSE
            } //: IF activity completed
        }//: GROUP
        // MARK: - ON APPEAR
        .onAppear {
            previousCertificate = activity.completionCertificate
        }//: ON APPEAR
        
        // MARK: - ON CHANGE
        .onChange(of: activity.completionCertificate) { newCertificate in
            // Prevent alert from appearing after user cancels a change
            if okToShowAlert == false {
                okToShowAlert = true
                previousCertificate = newCertificate
                return
            }
            
            // once a certificate has been saved, bring up an alert each
            // time the user wishes to change it...
            if let oldCert = previousCertificate,
               let newCert = newCertificate {
                       certificateToConfirm = CertificateDataWrapper(newData: newCert, oldData: oldCert)
                }
            
            previousCertificate = newCertificate
        }
        // MARK: - ALERTS
        // MARK: Change CE Certificate Alert
        .alert(item: $certificateToConfirm) { wrapper in
            Alert(
                title: Text("Change Certificate?"),
                message: Text("Are you sure you wish to change the certificate associated with this activity?"),
                primaryButton: .default(Text("Confirm")) {
                    activity.completionCertificate = wrapper.newData
                   
                },
                secondaryButton: .cancel() {
                    okToShowAlert = false
                    if let data = wrapper.oldData {
                        activity.completionCertificate = data
                    }
                }
            )
        } //: Change ALERT
        
        // MARK: Delete CE Certificate Alert
        .alert("Delete Certificate", isPresented: $showDeleteCertificateWarning) {
            Button("DELETE", role: .destructive) {
                activity.completionCertificate = nil
            }
            
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You are about to delete the saved CE certificate. Are you sure?  This cannot be undone.")
        }
        
    }//: BODY
}//: STRUCT


// MARK: - Certificate Data Wrapper struct
struct CertificateDataWrapper: Identifiable {
    let id = UUID()
    let newData: Data
    let oldData: Data?
}


// MARK: - PREVIEW
#Preview {
    ActivityCertificateImageView(activity: .example)
}
