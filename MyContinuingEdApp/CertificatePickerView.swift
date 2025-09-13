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
                }
            }
            
            
            
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
        .onChange(of: selectedCertificatePhoto) { newPic in
            guard let item = newPic else {return}
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    certificateData = data
                }
            }
        } //: ON CHANGE
        
    }//: BODY
}


// MARK: PREVIEW
struct CertificatePickerView_Preview: PreviewProvider {
    static var previews: some View {
        CertificatePickerView(activity: .example, certificateData: .constant(nil))
    }
}
