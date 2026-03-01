//
//  HelperFunctions.swift
//  MyContinuingEdApp
//
//  Created by Kamino on 8/13/25.
//

import UIKit
import ImageIO
import SwiftUI
import Photos

final class HelperFunctions {
    // MARK: - FILE HANDLING

    /// Function is used to save a saved CE certificate image or PDF file to a temporary location on
    /// disk and then relay the URL of that temp location for use by the ShareLink method.
    /// - Parameters:
    ///   - data: data for the CE certificate being shared
    /// - Returns: a URL for the temporary location where the file is being stored at
   class func createTempFileURL(for activity: CeActivity, with data: Data) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        var fileExtension: String = ""
        if isPDF(data) {
               fileExtension = "pdf"
        } else if let imageExt = getImageFileType(for: data) {
            fileExtension = imageExt
        } else {
            return nil
        }
       
        guard fileExtension.isNotEmpty else { return nil }
        let fileName = "\(activity.ceTitle) Certificate.\(fileExtension)"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch  {
            return nil
        }
    }//: tempFileURL()

    // MARK: - FILE TYPE HANDLING
    /// This is a helper function designed to read the first few bytes of an image file (data) and
    ///  return the specific file type, whether jpg, png, gif, etc.
    /// - Parameter data: data for the specific image file
    /// - Returns: a String value IF there is a match with one of the four most common
    ///      image types (jpg, png, gif, and tiff)
  class func getImageFileType(for data: Data) -> String? {
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
      } else if #available(iOS 17.0, *), let imageData = UIImage(data: data), let _ = imageData.heicData() {
          print("Data type detected: HEIFF brand")
          return "heic"
      } else if case let (true, brand) = isHEIFF(data), let brand = brand {
          print("HEIFF brand detected: \(brand)")
          return brand
      } else {
          NSLog("Unable to determine image file data type...sadly")
          return nil
      }//: IF ELSE
    
    }//: getImageFileType(for)

    /// Function to check whether the passed in data is in the PDF format or not.  The Boolean returned
    /// will be used to display the file correctly.
    /// - Parameter data: Data type from the selected photo or document
    /// - Returns: true if the data is PDF; false if not
  class func isPDF(_ data: Data?) -> Bool {
        guard let data = data else {return false}
        
        // This is the ASCII binary sequence for %PDF
        return data.starts(with: [0x25, 0x50, 0x44, 0x46])
    }


    /// Helper function that can determine if an image file is saved in Apple's High Efficiency Image File
    ///  Format (HEIFF) using the most common header bytes.
    /// - Parameter data: image date for the certificate
    /// - Returns: true if an array of the data from index 4 - 11 mateches the HEIFF signature array
   class func isHEIFF(_ data: Data) -> (Bool, String?) {
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
        
    }//: isHEIFF


    // MARK: - IMAGE DECODING

    /// Method for creating a UIImage from a data object that contains image-related data. Primary purpose is to ensure that only
    /// still images are saved and shown to the user (versus LivePhoto shots which could happen).
    /// - Parameter data: Object typed as Data containg image related data like pixels
    /// - Returns: OPTIONAL UIImage
    ///
    /// This method should work on any object that has valid image date in it.  It first tries to create
    /// a UIImage just using the UIImage(data) method, but if that fails it will then try to create a
    /// CoreGraphics image from the data and then call the UIImage(cgImage) on that image data to
    /// return a UIImage.
    ///
    /// Reasons why nil may be returned:
    /// - If incomplete data was passed in
    /// - If the UI image could not be created directly from the data AND either a image container can't be
    /// parsed or a CoreGraphics (CG) image could not be created from the data at index 0 for the container.
   class func decodeCertImage(from data: Data) -> UIImage? {
        guard data.count > 0 else { return nil }
        
        if let certImage = UIImage(data: data) {
            return certImage
        } else {
            // Telling CoreGraphics to cache all pixel data immediately via a
            // CoreFoundation Diciontary object (non-mutable) when making a
            // CG image from the data
            let cgOptions = [kCGImageSourceShouldCacheImmediately: true] as CFDictionary
            
            // Creating a source container from the raw data
            guard let src = CGImageSourceCreateWithData(data as CFData, nil) else {
                // if container can't be parsed, return nil
                return nil
            }
            
            // Asking ImageIO to decode image at index 0 (first one)
            guard let cgImage = CGImageSourceCreateImageAtIndex(src, 0, cgOptions) else {
                return nil
            }
            
             return UIImage(cgImage: cgImage)
        }//: IF LET
        
    }//: decodeCertImage()
    
}//: CLASS


