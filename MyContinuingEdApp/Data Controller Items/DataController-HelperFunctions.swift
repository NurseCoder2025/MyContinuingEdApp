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
            } else if let genURL = URL(string: "https://\(propertyString)") {
                return genURL
            } else {
                return nil
            }
    }//: createURLFromString
    
    /// Generic method for comparing two sets of objects and returning an array of objects
    /// that need to be created and added to persistent storage based on an internal JSON
    /// file which is used as the source of truth for those CoreData objects.
    /// - Parameters:
    ///   - jsonItems: Array of objects created from an internal JSON file
    ///   - coreDataItems: Array of CoreData entity objects that correspond to the JSON
    ///   file items which are already stored in persistent storage.
    /// - Returns: Array of JSON objects that need to be added to persistent storage
    ///
    ///- Important: Argument order really matters for the function to return the correct
    /// arrary of objects. Since both arguments just need to conform to SyncIdentifiable, it is
    /// possible to switch things around, but the final result of this method depends on the
    /// jsonItems parameter.
    ///
    /// Use this method whenever there is a need to sync objects between those represented
    /// in an internal JSON file and the corresponding CoreData entity.  This method specifically
    /// compares the two arrays using the syncID property that is required by SyncIdentifiable
    /// and returns objects that were decoded from the JSON file but are not currently in
    /// persistent storage as part of the corresponding CoreData entity.
    ///
    /// Cases where this method can be used include:
    ///     - ActivityTypeJSON & ActivityType (CoreData entity)
    ///     - PromptQuestionJSON & ReflectionPrompt (CoreData entity)
    func getJSONObjsToAddToCoreData<A: SyncIdentifiable, B: SyncIdentifiable>(
        jsonItems: [A],
        coreDataItems: [B]
    ) -> [A] {
       guard jsonItems.isNotEmpty else { return [] }
        
       let savedItems = Set<String>(coreDataItems.map(\.syncID))
       let officialListItems = Set<String>(jsonItems.map(\.syncID))
       let missingItems = officialListItems.subtracting(savedItems)
        
        guard missingItems.isNotEmpty else {return []}
        let jsonItemsToAdd = jsonItems.filter {
            missingItems.contains( $0.syncID )
        }
        
        return jsonItemsToAdd
    }//: addJSONObjsToCoreData
    
    
    /// Generic method for comparing two sets of objects and returning an array of objects
    /// that need to be deleted from persistent storage as they are no longer in the source
    /// of truth, which is an internal JSON file.
    /// - Parameters:
    ///   - coreDataItems: Array of CoreData objects to be compared with the source of
    ///   truth
    ///   - jsonItems: Array of objects decoded from an internal JSON file that serves as the
    ///   source of truth for creating CoreData objects
    /// - Returns: Array of CoreData objects that are to be deleted
    ///
    ///- Important: Argument order really matters for the function to return the correct
    /// arrary of objects. Since both arguments just need to conform to SyncIdentifiable, it is
    /// possible to switch things around, but the final result of this method depends on the
    /// coreDataItems parameter.
    ///
    /// Use this method whenever there is a need to sync objects between those represented
    /// in an internal JSON file and the corresponding CoreData entity.  This method specifically
    /// compares the two arrays using the syncID property that is required by SyncIdentifiable
    /// and returns objects that exist in persistent storage but are no longer part of the JSON
    /// file being used as the source of truth.
    ///
    /// Cases where this method can be used include:
    ///     - ActivityTypeJSON & ActivityType (CoreData entity)
    ///     - PromptQuestionJSON & ReflectionPrompt (CoreData entity)
    func getCoreDataObjsToRemove<A: SyncIdentifiable, B: SyncIdentifiable>(
        coreDataItems: [A],
        jsonItems: [B]
    ) -> [A] {
        guard coreDataItems.isNotEmpty, jsonItems.isNotEmpty else { return [] }
        
        let savedItems = Set<String>(coreDataItems.map(\.syncID))
        let officialListItems = Set<String>(jsonItems.map(\.syncID))
        let extraItems = savedItems.subtracting(officialListItems)
        
        guard extraItems.isNotEmpty else {return []}
        let coreDataItemsToRemove = coreDataItems.filter {
            extraItems.contains( $0.syncID )
        }
        
        return coreDataItemsToRemove
    }//: removeCoreDataObjsFromJSON
    
}//: EXTENSION
