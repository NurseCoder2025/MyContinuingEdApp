//
//  LocalMediaFileInfo.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/22/26.
//

import CloudKit
import Foundation


final class LocalMediaFileInfo: NSObject, NSSecureCoding, Identifiable {
   // MARK: - PROPERTIES
    private(set) var id: CKRecord.ID
    var mediaURL: URL?
    
    static var supportsSecureCoding: Bool = true
    
    // MARK: - METHODS
    
    func encode(with coder: NSCoder) {
        coder.encode(id, forKey: "id")
        coder.encode(mediaURL, forKey: "url")
    }//: encode(coder)
    
    // MARK: - INIT
    
    init(id: CKRecord.ID, mediaURL: URL?) {
        self.id = id
        self.mediaURL = mediaURL
    }//: INIT
    
    init?(coder decoder: NSCoder) {
        if let recKey = decoder.decodeObject(forKey: "id") as? CKRecord.ID {
            self.id = recKey
        } else {
            self.id = CKRecord.ID(recordName: String.emptyRecName)
        }//: IF LET ELSE (recKey)
        
        if let savedURL = decoder.decodeObject(forKey: "url") as? URL {
            self.mediaURL = savedURL
        }
    }//: INIT
    
}//: CLASS
