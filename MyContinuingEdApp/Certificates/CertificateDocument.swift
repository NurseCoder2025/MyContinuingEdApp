//
//  CertificateDocument.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/14/26.
//

import CloudKit
import Foundation
import UIKit


final class CertificateDocument: UIDocument {
    // MARK: - PROPERTIES
    
    /// CertificateDocument property for holding a FileWrapper object upon the loading of existing data for the
    /// document.
    ///
    /// - Note: The FileWrapper object needs to be a directory as the CertificateDocument will hold both metadata as
    /// well as binary data for the ce certificate
    var fileWrapper: FileWrapper?
    var metaDataForFile: CertificateMetadata?
    var rawCertData: Data?
    
    // MARK: - COMPUTED PROPERTIES
    
    /// Computed property in CertificateDocument that returns either an unwrapped CertificateMetadata object from the
    /// fileWrapper property (if data was previously saved) or will create a new CertficiateMetadata object based on the
    /// one that was passed in (or the example object if not).
    ///
    /// - Important: The CertificateMetadata object should be created prior to creating a new CertificateDocument
    /// object and passed in using the secondary init(certURL: metaData:) initializer.
    lazy var certMetaData: CertificateMetadata = {
        guard
            let existingData = fileWrapper,
            let metaData = decodeMetaDataFromWrapper(.certMetaDataKey) as? CertificateMetadata
        else {
            if let newMeta = metaDataForFile {
                return newMeta
            } else {
                return CertificateMetadata.example
            }
        }//: GUARD
        
        return metaData
    }()
    
    /// Computed property in CertificateDocument that returns either an unwrapped CertificateData object from the
    /// fileWrapper property OR a new CertfificateData object (with a nil certData property).
    lazy var certBinaryData: CertificateData = {
        guard
            let existingData = fileWrapper,
            let certBinary = decodeMetaDataFromWrapper(.certBinaryDataKey) as? CertificateData
        else {
            return CertificateData(containing: rawCertData)
        }
        return certBinary
    }()
    
    // MARK: - UI Document Method Overrides
    
    /// UIDocument function that is overriden to provide custom handling of how a new CertificateDocument object is to be
    /// written. Method creates and returns a FileWrapper object with both metadata and binary data for the CE certificate.
    /// - Parameter typeName: file extension representing the type of document this object is ("cert")
    /// - Returns: a FileWrapper directory object if the meta data and binary data objects can be encoded into JSON
    /// or just an empty FileWrapper class object if not.
    override func contents(forType typeName: String) throws -> Any {
        if let metaWrapper = encodeToJSONForWrapper(toEncode: certMetaData),
           let certDataWrapper = encodeToJSONForWrapper(toEncode: certBinaryData) {
            let wrappers: [String: FileWrapper] = [
                .certMetaDataKey: metaWrapper,
                .certBinaryDataKey: certDataWrapper
            ]
            let wrapperDirectory = FileWrapper(directoryWithFileWrappers: wrappers)
            metaDataForFile = nil
            rawCertData = nil
            return wrapperDirectory
        } else {
            return FileWrapper()
        }
    }//: contents(forType)
    
    /// UIDocument function that is overridden to provide custom handling for the loading of existing data for a CertificateDocument.
    /// - Parameters:
    ///   - contents: FileWrapper object (which should be a directory - the fileWrapper property of this class)
    ///   - typeName: file extension for the type of document this is ("cert")
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let fileWrapper = contents as? FileWrapper else { return }
        self.fileWrapper = fileWrapper
    }//: load()
    
    
    // MARK: - PRIVATE METHODS
    
    /// Private method that encodes an individual object into JSON and then inserts into a FileWrapper regular data file
    /// object for use in the contents(forType) method.
    /// - Parameter object: Any Codable object, but specifically only the CertificateData and CertificateMetadata objects
    /// should be passed in as arguments
    /// - Returns: FileWrapper file data object with the encoded object if encoding was successful; nil if not
    private func encodeToJSONForWrapper(toEncode object: Codable) -> FileWrapper? {
        let encoder = JSONEncoder()
        let encodedData = (try? encoder.encode(object))
        if let savedData = encodedData {
            let wrapper = FileWrapper(regularFileWithContents: savedData)
            return wrapper
        } else {
            return nil
        }
    }//: encodeToJSONForWrapper()
    
    /// Private method that is used in both computed properties in CertificateDocument to load the individual files within the
    /// FileWrapper directory to the respective computed property.
    /// - Parameter wrapper: String value representing the dictionary key for which the corresponding FileWrapper data
    /// object was saved to the directory with
    /// - Returns: The decoded data as either CertificateMetadata or CertificateData if decoding was successful; otherwise, just
    /// the data from the FileWrapper will be returned
    ///
    /// - Important: Make sure to use only the static properties in the String extension for the argument in this method.  The two
    /// String constants to use are .certMetaDataKey for the CertificateMetadata object and the .certBinaryDataKey for the
    /// CertificateData object.
    private func decodeMetaDataFromWrapper(_ wrapper: String) -> Any? {
        guard
            let allWrappers = fileWrapper,
            let specifiedWrapper = allWrappers.fileWrappers?[wrapper],
            let data = specifiedWrapper.regularFileContents
        else { return nil }
        
        let decoder = JSONDecoder()
        if wrapper == .certMetaDataKey {
           return try? decoder.decode(CertificateMetadata.self, from: data)
        } else if wrapper == .certBinaryDataKey {
            return try? decoder.decode(CertificateData.self, from: data)
        } else {
            return data
        }
    }//: decodeMetaDataFromWrapper
    
    
    // MARK: - INITS
    
    /// Primary initalizer for the CertificateDocument object, especially for when loading existing certificates
    /// - Parameter certURL: file location (url) where the certificate data was saved to
    ///
    /// - Important: If creating a new CertificateDocument for saving a new CE certificate to storage, don't use
    /// this intializer.  Instead, use the init(certURL: metaData:) method.
    init(certURL: URL) {
        super.init(fileURL: certURL)
    }//: INIT
    
    /// Custom initializer for the CertificateDocument object for when creating/saving new CE certificates.
    /// - Parameters:
    ///   - certURL: file location (url) where the certificate is to be saved to
    ///   - metaData: CertificateMetadata object with values corresponding to the certificate being saved
    ///   - withData: The binary data for the CE certificate (as a Data type)
    ///
    /// - Important: Only use this initailzer when saving new CE certificates to storage.  For reading/loading of
    /// existing ones, use the init(certURL) method instead.
    init(certURL: URL, metaData: CertificateMetadata, withData: Data) {
        super.init(fileURL: certURL)
        self.metaDataForFile = metaData
        self.rawCertData = withData
    }//: INIT
    
}//: CertifiedDocument
