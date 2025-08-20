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
    let data: Data
    
    // MARK: - Methods
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(data: data)
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {}
    
    
}
