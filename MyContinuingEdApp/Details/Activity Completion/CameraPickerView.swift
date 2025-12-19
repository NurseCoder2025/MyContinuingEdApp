//
//  CameraPickerView.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 8/19/25.
//

import SwiftUI
import UIKit

struct CameraPickerView: UIViewControllerRepresentable {
    // MARK: - PROPERTIES
    @Environment(\.dismiss) var dismiss
    var completion: (Data?) -> Void  // trailing closure when called by CertificatePickerView
    
    // MARK: - METHODS
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    }
}



// MARK: - COORDINATOR CLASS DELEGATE
class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    // Properties
    let parent: CameraPickerView
    
    // Methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        
        if let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 0.9) {
            parent.completion(data)
        } else {
            parent.completion(nil)
        }
        
        parent.dismiss()
    } //: imagePickerController func
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        parent.completion(nil)
        parent.dismiss()
    }
    
    // INIT
    init(_ parent: CameraPickerView) {
        self.parent = parent
    }
}
