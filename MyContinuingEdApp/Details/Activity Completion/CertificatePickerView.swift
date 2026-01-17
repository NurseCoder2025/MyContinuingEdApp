//
//  CertificatePickerView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 8/12/25.
//

import PhotosUI
import UniformTypeIdentifiers
import SwiftUI

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
    
    // MARK: - BODY
    var body: some View {
        VStack {
            if certificateData == nil {
                NoItemView(noItemTitleText: "Add Certificate", noItemMessage: "You haven't yet added your CE certificate for this completed activity.")
                    .accessibilityLabel("No CE Certificates have been added for this activity yet.")
            }
            
            Menu(activity.completionCertificate == nil ? "Add Certificate" : "Change Certificate") {
                Button("Take Photo") { showCamera = true }
                Button("Select Image") { showImagePicker = true }
                Button("Select PDF") { showDocumentPicker = true }
            } //: MENU
            .sheet(isPresented: $showCamera) {
                CameraPickerView { data in
                    if let data = data {
                        certificateData = data
                    }
                }//: CameraPickerView
            }//: SHEETE
            
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
                }
            }
        } //: FILE IMPORTER
        // MARK: - ON CHANGE (pics from Photo Library)
        .onChange(of: selectedCertificatePhoto) { newPic in
            guard let item = newPic else {return}
            Task {
                if let data = try? await item.loadTransferable(type: Data.self){
                    // Try to get a UI image first
                    if let selectedUiImage = UIImage(data: data) {
                        // If certificate image is a JPEG or PNG, save it in that format to disk
                        if let jpgImage = selectedUiImage.jpegData(compressionQuality: 0.8) {
                            certificateData = jpgImage
                        } else if let pngImage = selectedUiImage.pngData() {
                            certificateData = pngImage
                        } else {
                            certificateData = data
                        }
                        // Returning raw data if a UI Image cannot be directly created
                        // In this instance, in ActivityCertificateImageView the data
                        // will be run through the decodeCertImage function which will
                        // attempt to create a CGImage from the data and then back into
                        // a UIImage, but if that fails then likey there is an issue like
                        // data corruption or a file format that isn't supported by Apple
                    } else {
                        certificateData = data
                    }
                }//: IF LET (data)
            }//: TASK
        } //: ON CHANGE
        
    }//: BODY
}//: STRUCT


// MARK: - PREVIEW
struct CertificatePickerViewPreview: PreviewProvider {
    static var previews: some View {
        CertificatePickerView(activity: .example, certificateData: .constant(nil))
    }
}
