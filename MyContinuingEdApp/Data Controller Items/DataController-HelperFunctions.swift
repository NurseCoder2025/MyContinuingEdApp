//
//  DataController-HelperFunctions.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 1/13/26.
//

// The purpose of this file is to contain various helper functions
// for inclusion within DataController for the manipulation of
// user-entered data for purposes like URL creation and the like.

import Foundation


extension DataController {
    // MARK: - HELPER FUNCTIONS
    
    /// General method intended to ensure that any strings which are to be converted
    /// into a URL object have either https:// or http:// placed at the front of the string
    /// value.
    /// - Parameter propertyString: Any string intended to be a URL
    /// - Returns: Optional URL based on the propertyString argument value
    ///
    /// This function was created with several properties in CeActivity where strings
    /// are used to hold values for URLs, such as infoWebsiteURL and registrationURL.
    /// However, it can be used with any string value as needed.
    ///
    /// A nil value will only be returned if an empty string value is passed in as an
    /// arugment or if the URL(string) method fails to create a valid URL.
    func createURLFromString(propertyString: String) -> URL? {
        guard propertyString.count > 0 else { return nil }
        let urlPrefixes: [String] = ["https://", "http://"]
            if propertyString.hasPrefix(urlPrefixes[0]) || propertyString.hasPrefix(urlPrefixes[1]) {
                return URL(string: propertyString)!
            } else {
                return URL(string: "https://\(propertyString)")!
            }
    }//: createURLFromString
    
}//: EXTENSION
