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
       // Determine what type of data was passed in
        let isPDFTrueOrFalse = isPDF(certificateData)
        
        let fileExt = isPDFTrueOrFalse ? "pdf" : getImageFileType(for: certificateData)
        
        
       // Save a copy of the file to temporary storage for sharing
        if let unwrappedFileExt = fileExt {
            if let url = tempFileURL(for: certificateData, fileExtension: unwrappedFileExt) {
                ShareLink(item: url) {
                    Label("Export Certificate", systemImage: "square.and.arrow.up")
                } //: SHARE LINK
                
            } else {
                Text("Unable to prepare certificate for sharing, sorry!")
            }//: IF LET (url)
            
        } else {
            Text("Sorry, but the saved certificate image is not one of the 4 major image types (jpg, png, tiff, gif), so can't be shared.")
        }//: IF LET (unwrappedFileExt)
        
        
        // Call the ShareLink method on the file
       
        
    }
    
    // MARK: - Functions
    
    /// Function is used to save a saved CE certificate image or PDF file to a temporary location on
    /// disk and then relay the URL of that temp location for use by the ShareLink method.
    /// - Parameters:
    ///   - data: data for the CE certificate being shared
    ///   - fileExtension: String indicating whether the file is a PDF or some type of image
    /// - Returns: a URL for the temporary location where the file is being stored at
    func tempFileURL(for data: Data, fileExtension: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(activity.ceTitle) Certificate.\(fileExtension)"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch  {
            return nil
        }
    }
    
    // MARK: - DEBUGGING Methods
    
}


