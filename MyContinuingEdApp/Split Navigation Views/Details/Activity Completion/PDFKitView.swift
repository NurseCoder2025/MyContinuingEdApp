//
//  PDFKitView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 8/13/25.
//

import PDFKit
import SwiftUI

struct PDFKitView: UIViewRepresentable {
    // MARK: - Properties
    let document: PDFDocument
    
    // MARK: - Methods
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        return pdfView
    }//: makeUIView(context)
    
    func updateUIView(_ uiView: PDFView, context: Context) {}
    
    
}//: STRUCt
