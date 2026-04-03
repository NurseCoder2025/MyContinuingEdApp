//
//  CKRecord+Extensions.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/2/26.
//

import CloudKit
import Foundation


extension CKRecord {
    
    var idName: String {
        return self.recordID.recordName
    }//: idName
    
}//: EXTENSION
