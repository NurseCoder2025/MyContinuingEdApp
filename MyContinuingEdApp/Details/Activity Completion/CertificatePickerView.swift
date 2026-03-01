//
//  CertificatePickerView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 8/12/25.
//

import PhotosUI
import SwiftUI
import UIKit
import PDFKit

/// View that shows the UI controls for selecting a CE certificate (image or PDF) for
/// a specific CeActivity object.  Parent view is ActivityCertificateImageView.
struct CertificatePickerView: View {
    // MARK: - PROPERTIES
    @ObservedObject var activity: CeActivity
    @Binding var certificateData: Data?
    
    // Properties for the segmented picker control
    @State private var showImagePicker: Bool = false
    @State private var showDocumentPicker: Bool = false
    
    // Property for storing the selected picture
    @State private var selectedCertificatePhoto: PhotosPickerItem? = nil
    
    // Property for activating the camera app
    @State private var showCamera: Bool = false
    
    // Alerts for notifying the user the certificate image or PDF could not be
    // selected
    @State private var showCertSelectionErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    
    // MARK: - BODY
    var body: some View {
        VStack {
            
            Menu(activity.hasCompletionCertificate ? "Change Certificate" : "Add Certificate") {
                Button("Take Photo") { showCamera = true }
                Button("Select Image") { showImagePicker = true }
                Button("Select PDF") { showDocumentPicker = true }
            } //: MENU
            .sheet(isPresented: $showCamera) {
                CameraPickerView { data in
                    if let data = data {
                        certificateData = data
                    } else {
                        errorMessage = "Unable to properly read the image data from the image captured by the device's camera. Please try again."
                        showCertSelectionErrorAlert = true
                        NSLog(">>>Error encountered while the user was trying to capture a certificate image using the device's camera. Could not covert the image to a UIImage or could not capture the data from CameraPickerView.")
                    }
                }//: CameraPickerView
            }//: SHEET
            
        } //: VSTACK
        .photosPicker(
            isPresented: $showImagePicker,
            selection: $selectedCertificatePhoto,
            matching: .images
            )
        .fileImporter(
            isPresented: $showDocumentPicker,
            allowedContentTypes: [.pdf]
        ) { result in
            if case .success(let url) = result {
                if let data = try? Data(contentsOf: url) {
                    certificateData = data
                } else {
                    showCertSelectionErrorAlert = true
                    errorMessage = "Unable to read the selected PDF file. Try selecting a different one or recreate/re-download the file again as it might be corrupted."
                    NSLog(">>>Error decoding PDF data from a selected file at: \(url.absoluteString)")
                }
            } else {
                showCertSelectionErrorAlert = true
                errorMessage = "Unable to open the PDF file for some reason. Try selecting a different file."
                NSLog(">>>Encountered error opening/importing a selected PDF file.")
            }
        } //: FILE IMPORTER
        // MARK: - ON CHANGE (pics from Photo Library)
        .onChange(of: selectedCertificatePhoto) { newPic in
            guard let item = newPic else {return}
            Task {
                if let data = try? await item.loadTransferable(type: Data.self){
                    // Checking to ensure that an image can be read
                    if UIImage(data: data) != nil {
                        certificateData = data
                    } else {
                        errorMessage = "The saved image you selected could not be read. It might be saved in an unrecognized format or have corrupted data."
                        showCertSelectionErrorAlert = true
                        NSLog(">>>Error enountered while trying to load a selected image from the photo picker. Unable to create a UIIMage from the data.")
                    }//: IF ELSE (decodeCertImage)
                } else {
                    errorMessage = "The saved image you selected could not be read. It might be saved in an unrecognized format or have corrupted data."
                    showCertSelectionErrorAlert = true
                    NSLog(">>>Error loading photo data from the photo picker for a selected item. The loadTransferable method threw an error.")
                }//: IF ELSE (data)
            }//: TASK
        } //: ON CHANGE
        // MARK: - ALERTS
        .alert("Certificate Error", isPresented: $showCertSelectionErrorAlert) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }//: ALERT
            
    }//: BODY
}//: STRUCT


// MARK: - PREVIEW
struct CertificatePickerViewPreview: PreviewProvider {
    static var previews: some View {
        CertificatePickerView(activity: .example, certificateData: .constant(nil))
    }
}//: PREVIEW
