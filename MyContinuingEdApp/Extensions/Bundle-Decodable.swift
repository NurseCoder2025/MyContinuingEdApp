//
//  Bundle-Decodable.swift
//  MyContinuingEdApp
//
//  Created by Manann on 7/24/25.
//

import Foundation


extension Bundle {
    
    /// A method for decoding internal JSON files and sending different error messages that correspond to
    /// the particular cause for the error.
    func decode<T: Decodable>(
        _ file: String,
        as type: T.Type = T.self,
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys
    ) -> T {
        // Step 1: locate JSON file URL in bundle
        guard let fileToDecode = url(forResource: file, withExtension: nil) else {
            fatalError("Failed to locate file, \(file), from internal bundle.")
        }
        
        // Step 2: Get Data object from the JSON file
        guard let data = try? Data(contentsOf: fileToDecode) else {
            fatalError("Failed to load the data of the file, \(file), from bundle.")
        }
        
        // Creating and customizing decoder
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateDecodingStrategy
        decoder.keyDecodingStrategy = keyDecodingStrategy
        
        
        do {
        // Step 3: Convert Data object to a Swift object
            return try decoder.decode(T.self, from: data)
            
        // Step 4: Provide a useful error message if decoding has failed somehow
        } catch DecodingError.keyNotFound(let key, let context) {
            fatalError("Failed to decode \(file) from bundle due to missing key '\(key.stringValue)' - \(context.debugDescription)")
        } catch DecodingError.typeMismatch(_ , let context) {
            fatalError("Failed to decode \(file) from bundle due to type mismatch - \(context.debugDescription)")
        } catch DecodingError.valueNotFound(let type, let context) {
            fatalError("Failed to decode \(file) from bundle due to missing \(type) value - \(context.debugDescription)")
        } catch DecodingError.dataCorrupted(_) {
            fatalError("Failed to decode \(file) from bundle becuase it appears to be invalid JSON")
        } catch {
            fatalError("Failed to decode \(file) from bundle: \(error.localizedDescription)")
        }
        
        
        
    }
    
    
}
