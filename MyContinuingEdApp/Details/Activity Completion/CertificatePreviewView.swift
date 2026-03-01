//
//  CertificatePreviewView.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/27/26.
//

import SwiftUI
import PDFKit
import PhotosUI

struct CertificatePreviewView: View {
    // MARK: - PROPERTIES
    @State var savedCert: Certificate?
    
    // MARK: - BODY
    var body: some View {
        if let activityCert = savedCert as? PDFDocument,
            activityCert.certificateType == .pdf {
            PDFKitView(document: activityCert)
                    .frame(height: 300)
                    .accessibilityLabel("PDF view of your CE Certificate for this activity.")
        } else if let certImage = savedCert as? UIImage,
                  certImage.certificateType == .image {
            Image(uiImage: certImage)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .accessibilityLabel(Text("Image of your CE Certificate for this activity."))
        } else {
            Text("No saved CE certificate to show...☹️")
        }
    }//: BODY
}//: STRUCT

// MARK: - PREVIEW
#Preview {
    CertificatePreviewView()
}
