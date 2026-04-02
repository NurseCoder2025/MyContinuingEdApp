//
//  CKRecord+Extensions.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/1/26.
//

import CloudKit
import Foundation


struct DynamicRecordKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }//: init?
    
    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }//: init?
    
}//: DynamicRecordKey

extension CKRecord: @retroactive Encodable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: DynamicRecordKey.self)
        
        let allFields = self.allKeys()
        for field in allFields {
            guard let codingKey = DynamicRecordKey(stringValue: field) else { continue }
            
            if let value = self[field] as? String {
                try container.encode(value, forKey: codingKey)
            } else if let value = self[field] as? Int {
                try container.encode(value, forKey: codingKey)
            } else if let value = self[field] as? Data {
                try container.encode(value, forKey: codingKey)
            } else if let value = self[field] as? Date {
                try container.encode(value, forKey: codingKey)
            } else if let value = self[field] as? Bool {
                try container.encode(value, forKey: codingKey)
            } else if let value = self[field] as? Double {
                try container.encode(value, forKey: codingKey)
            } else if let value = self[field] as? UUID {
                try container.encode(value, forKey: codingKey)
            } //: IF ELSE
        }//: LOOP
    }//: encode()
    
}//: EXTENSION


