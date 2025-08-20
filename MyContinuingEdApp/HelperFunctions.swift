//
//  HelperFunctions.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 8/13/25.
//

import SwiftUI
import Photos

/// This is a helper function designed to read the first few bytes of an image file (data) and
///  return the specific file type, whether jpg, png, gif, etc.
/// - Parameter data: data for the specific image file
/// - Returns: a String value IF there is a match with one of the four most common
///      image types (jpg, png, gif, and tiff)
func getImageFileType(for data: Data) -> String? {
    if data.starts(with: [0xFF, 0xD8, 0xFF]) {
        print("Data type detected: jpg image")
        return "jpg"
    } else if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
        print("Data type detected: png image")
        return "png"
    } else if data.starts(with: [0x47, 0x49, 0x46, 0x38]) {
        print("Data type detected: gif image")
        return "gif"
    } else if data.starts(with: [0x49, 0x49, 0x2A, 0x00]) {
        print("Data type detected: tiff image")
        return "tiff"
    } else if case let (true, brand) = isHEIFF(data), let brand = brand {
        print("Data type detected: \(brand)")
        return brand
    }
    
    print("Unable to determine image file data type...sadly")
    return nil
    
}


/// Function to check whether the passed in data is in the PDF format or not.  The Boolean returned
/// will be used to display the file correctly.
/// - Parameter data: Data type from the selected photo or document
/// - Returns: true if the data is PDF; false if not
func isPDF(_ data: Data?) -> Bool {
    guard let data = data else {return false}
    
    // This is the ASCII binary sequence for %PDF
    return data.starts(with: [0x25, 0x50, 0x44, 0x46])
}


/// Helper function that can determine if an image file is saved in Apple's High Efficiency Image File
///  Format (HEIFF) using the most common header bytes.
/// - Parameter data: image date for the certificate
/// - Returns: true if an array of the data from index 4 - 11 mateches the HEIFF signature array
func isHEIFF(_ data: Data) -> (Bool, String?) {
    let ftypSignature: [UInt8] = [0x66, 0x74, 0x79, 0x70]
    let brands: [String: [UInt8]] = [
        "heic" : [0x68, 0x65, 0x69, 0x63],
        "heix" : [0x68, 0x65, 0x69, 0x78],
        "hevc" : [0x68, 0x65, 0x76, 0x63],
        "mif1" : [0x6D, 0x69, 0x66, 0x31]
    ]
    
    guard data.count > 12 else {return (false, nil) }
    
    if Array(data[4..<8]) == ftypSignature {
        for (brand, sig) in brands {
            if Array(data[8..<12]) == sig {
                return (true, brand)
            }
        }
    } //: IF (Array)

    return (false, nil)
    
}



