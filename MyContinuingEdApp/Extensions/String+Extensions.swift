//
//  String+Extensions.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/17/26.
//

import Foundation


extension String {
    // MARK: - File EXTENSIONS
    /// Static constant in the String struct (via extension) that sets the value for
    /// the CE certificate file package (UI Document) as "cert".
    static let certFileExtension: String = "cert"
    
    /// Static constant in the String struct (via extension) that sets the value for
    /// the audio reflection file package (UI Document) as "audio"
    static let audioReflectionExtension: String = "audio"
    
    // MARK: - DATA KEYS
    /// Static constant in the String struct (via extension) that represents a String dictionary key
    /// for the FileWrapper directory objects created for the CertificateDocument (UIDocument) that
    /// correspond to the CertificateMetadata object.
    static let certMetaDataKey: String = "certificate.meta"
    
    /// Static constant in the String struct (via extension) that represents a String dictionary key
    /// for the FileWrapper directory objects created for the CertificateDocument (UIDocument) that
    /// correspond to the CertificateData object.
    static let certBinaryDataKey: String = "certificate.data"
    
    static let userIDKey: String = "iCloud.userID"
    
    // MARK: - NSQueryMetadata Keys
    
    static let resultURL: String = "NSMetadataItemURLKey"
    
    // MARK: - URL values
    
    /// String constant property that is used for the filename and extension for the JSON file that will contain all
    /// CertificateCoordinator objects.  Value: "CertificateCoordinatorList.json".
    static let certCoordinatorListFile: String = "CertificateCoordinatorList.json"
    
    
    /// String constant property that is used for the filename and extension for saving the user's
    /// iCloud user id info (CKRecord.ID object) on the local device for long-term storage and
    /// access.
    ///
    /// This property is used within the private DataController methods encodeICloudUserIDFile and
    /// decodeICloudUserIDFile.
    static let iCloudUserID: String = "iCloudUserID.json"
    
}//: EXTENSION
