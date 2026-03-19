//
//  UIDocument+Extensions.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/12/26.
//

import Foundation
import UIKit

extension UIDocument {
    
    /// UI Document method that encodes an individual object into JSON and then inserts into a FileWrapper regular data file
    /// object for use in the contents(forType) method.
    /// - Parameter object: Any Codable object, but specifically only the CertificateData and CertificateMetadata objects
    /// should be passed in as arguments
    /// - Returns: FileWrapper file data object with the encoded object if encoding was successful; nil if not
     func encodeToJSONForWrapper(toEncode object: Codable) -> FileWrapper? {
        let encoder = JSONEncoder()
        let encodedData = (try? encoder.encode(object))
        if let savedData = encodedData {
            let wrapper = FileWrapper(regularFileWithContents: savedData)
            return wrapper
        } else {
            return nil
        }
    }//: encodeToJSONForWrapper()
    
}//: EXTENSION
