//
//  CertificateShareView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 8/13/25.
//

import SwiftUI

struct CertificateShareView: View {
    // MARK: - PROPERTIES
    @ObservedObject var activity: CeActivity
    let certificateData: Data
    
    // MARK: - BODY
    var body: some View {
       // Save a copy of the file to temporary storage for sharing
        if let url = createTempFileURL(for: activity, with: certificateData) {
            ShareLink(item: url) {
                Label("Export Certificate", systemImage: "square.and.arrow.up")
            } //: SHARE LINK
        } else {
            Text("Unable to prepare certificate for sharing, sorry!")
        }//: IF LET (url)

  }//: BODY
    
    // MARK: - Functions
    
    
    
    
}//: STRUCT


