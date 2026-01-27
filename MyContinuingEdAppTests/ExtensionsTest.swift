//
//  ExtensionsTest.swift
//  MyContinuingEdAppTests
//
//  Created by Ilum on 10/22/25.
//

import Foundation
import CoreData
import XCTest
@testable import MyContinuingEdApp

final class ExtensionsTest: BaseTestCase {
    // MARK: - CeActivity Extensions
    /// Test to determine whether the computed ceTitle property in the CeActivity extension (CEActivity-CoreDataHelper file) reads and writes
    /// changes to the CeActivity's activityTitle String properly.
    func testActivityTitleWrapping() {
        let someActivity = CeActivity(context: context)
        someActivity.activityTitle = "Best Immunization Practices 2025"
        
        // Does the ceTitle computed property unwrap the entity title?
        XCTAssertEqual(someActivity.ceTitle, "Best Immunization Practices 2025")
        
        // Changing the activity name via the computed wrapper
        someActivity.ceTitle = "Updated Title"
        XCTAssertEqual(someActivity.activityTitle, "Updated Title")
        
    }//: testActivityTitleWrapping()
    
    
    /// Test to determine whether the computed ceDescription property in the CeActivity extension (CEActivity-CoreDataHelper file) reads and writes
    /// changes to the CeActivity's activityDescription String properly.
    func testActivityDescriptionWrapping() {
        let someActivity = CeActivity(context: context)
        someActivity.activityDescription = "A half day session covering all of the latest IZ practices."
        
        // Does the ceDescription computed property unwrap the entity's description property?
        XCTAssertEqual(someActivity.ceDescription, "A half day session covering all of the latest IZ practices.")
        
        // Changing the activity description via the computed wrapper
        someActivity.ceDescription = "Updated activity description"
        XCTAssertEqual(someActivity.activityDescription, "Updated activity description")
    }//: testActivityDescriptionWrapping()
    
    
    /// Test to determine whether the computed ceActivityFormat property in the CeActivity extension (CEActivity-CoreDataHelper file) reads and writes
    /// changes to the CeActivity's activityFormat String properly.
    func testActivityFormatWrapping() {
        let someActivity = CeActivity(context: context)
        someActivity.activityFormat = "In-person"
        
        // Does the ceActivityFormat computed property unwrap the entity's format property?
        XCTAssertEqual(someActivity.ceActivityFormat, "In-person")
        
        // Changing the activity's format via the computed wrapper
        someActivity.ceActivityFormat = "Virtual"
        XCTAssertEqual(someActivity.activityFormat, "Virtual")
        
    }//: testActivityFormatWrapping()
    
    
    
    
    /// Test to determine whether the computed ceActivityAddedDate property in the CeActivity extension (CEActivity-CoreDataHelper file) reads
    /// changes to the CeActivity's modifiedDate Date properly.  (The computed property wrapper is a getter only)
    func testActivityAddedDateWrapping() {
        let someActivity = CeActivity(context: context)
        let testDate = Date.now
        someActivity.activityAddedDate = testDate
        
        // Does the ceActivityAddedDate computed property unwrap the entity's activityAddedDate property?
        XCTAssertEqual(someActivity.ceActivityAddedDate, testDate)
        
    }//: testActivityAddedDateWrapping()
    
    
    /// Test that determines whether the activityTags computed property in the CeActivity-CoreDataHelper file sorts all associated Tag objects properly
    func testAreActivityTagsSorted() {
        // Sample activity for which tags will be added to
        let testActivity = CeActivity(context: context)
        
        // Sample tag objects
        let tag1 = Tag(context: context)
            tag1.tagID = UUID()
            tag1.tagName = "IZ Related"
        
        let tag2 = Tag(context: context)
            tag2.tagID = UUID()
            tag2.tagName = "Cardio"
        
        let tag3 = Tag(context: context)
            tag3.tagID = UUID()
            tag3.tagName = "Neuro"
        
        // All tags sorted by name
        let sortedTags: [Tag] = [tag2, tag1, tag3]
        
        // Adding all tags to the sample activity
        for tag in sortedTags {
            tag.addToActivities(testActivity)
        }//: LOOP
        
        // Compare computed property activityTags with sortedTags array
        XCTAssertEqual(testActivity.activityTags, sortedTags, "The tags should be in the following order: tag2, tag1, and tag3")
        
    }//: testAreActivityTagsSorted()
    
    /// Test that determines whether the activityTags computed property in the CeActivity-CoreDataHelper file sorts all associated Tag objects properly
    func testAreActivityTagsStringsMade() {
        // Sample activity for which tags will be added to
        let testActivity = CeActivity(context: context)
        
        // Sample tag objects
        let tag1 = Tag(context: context)
            tag1.tagID = UUID()
            tag1.tagName = "IZ Related"
        
        let tag2 = Tag(context: context)
            tag2.tagID = UUID()
            tag2.tagName = "Cardio"
        
        let tag3 = Tag(context: context)
            tag3.tagID = UUID()
            tag3.tagName = "Neuro"
        
        // All tags sorted by name
        let sortedTags: [Tag] = [tag2, tag1, tag3]
        
        // Convert sortedTags into a string with each name
        let tagNames: String = sortedTags.map(\.tagTagName).formatted()
        
        // Adding all tags to the sample activity
        for tag in sortedTags {
            tag.addToActivities(testActivity)
        }//: LOOP
        
        // Checking to see if the allActivityTagsString produces the same String as tagNames
        XCTAssertEqual(testActivity.allActivityTagString, tagNames, "The two strings should be equal.")
        
    }//: testAreActivityTagsStringsMade()
    
    
    /// Test that determines whether the computed property expirationStatus returns the proper ExpirationType enum value given a CeActivity object
    /// with either a set expiration date or no expiration date.
    func testExpirationStatusGetsItRight() {
        // Creating a completed activity
        let completedActivity = CeActivity(context: context)
        completedActivity.activityCompleted = true
        
        // Creating an activity which has expired
        let expiredActivity = CeActivity(context: context)
        expiredActivity.expirationDate = Date.now.addingTimeInterval(-86400 * 20)
        
        // Creating an activity which expires TODAY
        let expiringTodayActivity = CeActivity(context: context)
        expiringTodayActivity.expirationDate = Date.now
        
        // Creating an activity which is Expiring SOON (within one month)
        let expireSoonActivity = CeActivity(context: context)
        let lessThanOneMonth: Double = 86400 * 25
        expireSoonActivity.expirationDate = Date().addingTimeInterval(lessThanOneMonth)
        
        // Creating an activity which hasn't been completed but doesn't expire for a while yet
        let validActivity = CeActivity(context: context)
        validActivity.expirationDate = Date.now.addingTimeInterval(86400 * 180)
        
        // Creating a valid activity with NO expiration date (hasn't been completed yet)
        let stillValidActivity = CeActivity(context: context)
        stillValidActivity.activityCompleted = false
        
        
        // Testing all status cases to ensure the right ones are computed for each
        XCTAssertEqual(
            completedActivity.expirationStatus,
            ExpirationType.finishedActivity,
            "This activity should be marked as finished"
        )
        
        XCTAssertEqual(
            expiredActivity.expirationStatus,
            ExpirationType.expired,
            "This activity should be marked as expired"
        )
        
        XCTAssertEqual(
            expiringTodayActivity.expirationStatus,
            ExpirationType.finalDay,
            "This activity should be marked as expiring TODAY"
        )
        
        XCTAssertEqual(
            expireSoonActivity.expirationStatus,
            ExpirationType.expiringSoon,
            "This activity should be marked as expiring soon"
        )
        
        XCTAssertEqual(
            validActivity.expirationStatus,
            ExpirationType.stillValid,
            "This activity should be marked as still valid"
        )
        
        XCTAssertEqual(
            stillValidActivity.expirationStatus,
            ExpirationType.stillValid,
            "This activity should be marked as still valid"
        )
        
        
    }//: testExpirationStatusGetsItRight()
    
    /// Test that determines whether the expirationStatusString computed property reutrns not only the right ExpirationType enum but also the correct
    /// String value for that enum case.
    func testExpirationStatusStringIsCorrect() {
        let sampleActivity = CeActivity(context: context)
        sampleActivity.expirationDate = Date().addingTimeInterval(86400 * 90)
        
        let sampleStatus = sampleActivity.expirationStatusString
        XCTAssertEqual(sampleStatus, "Valid", "This is an uncompleted activity set to expire in 90 days, so should be marked as  valid.")
        
    }//: testExpirationStatusStringIsCorrect()
    
    /// Test that determines whether the designationID computed property for CeActivity is able to get and set a UUID for a designation object
    func testGetAndSetCEDesignationID() {
        let sampleActivity = CeActivity(context: context)
        
        let allDesignations = CeDesignationJSON.defaultDesignations
        let sampleDesignation = CeDesignation(context: context)
        sampleDesignation.designationName = allDesignations[0].designationName
        sampleDesignation.designationAKA = allDesignations[0].designationAKA
        sampleDesignation.designationAbbreviation = allDesignations[0].designationAbbreviation
        
        sampleActivity.designation = sampleDesignation
        
        // Make sure there is a designation ID by using the designationID computed property
        XCTAssertNotNil(sampleActivity.designationID)
        
    }//: testGetAndSetCEDesignationID()
    
    
    /// Test to determine that the activityCredentials computed property for CeActivity returns all assigned Credentials sorted by name
    func testActivityCredentials() {
        // Creating sample credentials
        let sampleCredential1 = Credential(context: context)
        sampleCredential1.name = "Medical License"
        sampleCredential1.credentialType = "License"
        
        let sampleCredential2 = Credential(context: context)
        sampleCredential2.name = "Lawyer License"
        sampleCredential2.credentialType = "License"
        
        let sampleCredential3 = Credential(context: context)
        sampleCredential3.name = "Certified Examiner"
        sampleCredential3.credentialType = "Certification"
        
        let allSampleCreds = [sampleCredential1, sampleCredential2, sampleCredential3]
        let properCredSort = [sampleCredential3, sampleCredential2, sampleCredential1]
        
        // Creating sample activity
        let sampleActivity = CeActivity(context: context)
        
        // Assigning each credential to an activity
        for cred in allSampleCreds {
            cred.addToActivities(sampleActivity)
        }//: LOOP
        
        XCTAssertEqual(sampleActivity.activityCredentials, properCredSort, "There should be 3 credentials, sorted by the 3rd then 2nd and then 1st.")
        
    }//: testActivityCredentials()
    
    
    
    // MARK: - Tags Extensions
    
    /// Test that determines if the Tag extension tagTagName returns the actual tag name property value
    func testTagNameWrapper() {
        let tag = Tag(context: context)
        tag.tagName = "Test Tag"
        
        XCTAssertEqual(tag.tagTagName, "Test Tag", "The tag's tagName property should return the same value as its 'tagTagName' computed property.")
        
    }//: testTagNameWrapper()
    
    
    /// Test that determines if the Tag extension tagTagID returns the actual UUID value set for the tagID property
    func testTagIDWrapper() {
        let testTag = Tag(context: context)
        testTag.tagID = UUID()
        
        XCTAssertEqual(testTag.tagTagID, testTag.tagID, "The tag's tagID property should return the same value as its 'tagID' computed property.")
        
    }//: testTagIDWrapper()
    
    
    /// Test that determines if the tagActiveActivities computed property actually returns only CeActivitiy objects that have not been marked as
    /// completed and are associated with a given tag.
    func testActiveActivitiesAreReturned() {
        let sampleTag = Tag(context: context)
        
        // Create a variety of sample activities & add them to the sample tag
        var activeActivityCount: Int = 0
        for _ in 0..<15 {
            let sampleActivity = CeActivity(context: context)
            sampleActivity.activityCompleted = Bool.random()
            if !sampleActivity.activityCompleted {activeActivityCount += 1}
            
            sampleActivity.addToTags(sampleTag)
        }//: LOOP
        
        XCTAssertEqual(sampleTag.tagActiveActivities.count, activeActivityCount, "\(activeActivityCount) activities haven't been completed yet, but there are \(sampleTag.tagActiveActivities.count) activities that the tagActiveActivities property has returned as being active.")
        
    }//: testActiveActivitiesAreReturned()
    
    // MARK: - GENERAL EXTENSIONS
    
    /// Test to ensure that the Collection extension, isNotEmpty, returns true ONLY when there is a value inside a collection objectand false if it is empty.
    func testISNotEmpty() {
        let emptyString: String = ""
        let nonEmptyString: String = "Hello there"
        
        XCTAssert(emptyString.isEmpty, "An empty string should return as such.")
        XCTAssertFalse(emptyString.isNotEmpty, "An empty string should not return as not empty.")
        XCTAssertTrue(nonEmptyString.isNotEmpty, "A String with values should return true for isNotEmpty.")
        
        // Testing on arrays
        let emptyArray: [Int] = []
        let nonEmptyArray: [Int] = [1, 2, 3]
        
        XCTAssert(emptyArray.isEmpty, "An empty array should return as such.")
        XCTAssertFalse(emptyArray.isNotEmpty, "An empty array should not return as not empty.")
        XCTAssertTrue(nonEmptyArray.isNotEmpty, "An array with values should return true for isNotEmpty.")
        
        // Testing on sets
        let emptySet: Set<Int> = []
        let nonEmptySet: Set<Int> = [1, 2, 4]
        
        XCTAssert(emptySet.isEmpty, "An empty set should return as such.")
        XCTAssertFalse(emptySet.isNotEmpty, "An empty set should not return as not empty.")
        XCTAssertTrue(nonEmptySet.isNotEmpty, "A set with values should return true for isNotEmpty.")
        
    }//: testISNotEmpty()
    
    /// Tests whether the yearString computed property in the Date exension returns a string consisting of the digits in the year of the date the property is being used on.
    func testYearStringComputedProp() {
        let timeInterval: Double = (86400 * 365.25) * 44
        let testDate = Date(timeIntervalSince1970: timeInterval)
        let testYear = testDate.yearString
        
        XCTAssert(testYear.isNotEmpty, "There should be a computed value returned from the yearString property.")
        XCTAssert(testYear.count == 4, "The computed value should be a 4 digit string, but a string of \(testYear.count) was returned.")
        
    }//: testYearStringComputedProp()
    
    
    // MARK: - DECODABLE Extension
    
    /// Test to determine that the decode method within the Bundle extension can properly decode a json file that is within the main bundle.
    func testDecodeExtensionWithJSON() {
        let awards = Bundle.main.decode("Awards.json", as: [Award].self)
        XCTAssert(awards.isNotEmpty, "There should be awards data in the array as the JSON was just decoded.")
    }//: testDecodeExtensionWithJSON
    
    /// Test to determine whether the decode method within the Bundle extension can properly decode a json file that is stored in the testing bundle.
    func testDecodingStringJSON() {
        let bundle = Bundle(for: ExtensionsTest.self)
        let decodedData = bundle.decode("DecodableString.json", as: String.self)
        XCTAssertEqual(decodedData, "Never ask a stormtrooper for directions.")
    }//: testDecodingStringJSON()
    
    /// Test that determines if the decode method within the Bundle extension can properly decode a json file stored within the testing bundle
    ///
    /// **Given:** Location of the testing bundle & json file to decode ("DecodableDictionary.json")
    ///
    /// **When:** decoded data is assigned the decoded json file
    ///
    /// **Then:** the decoded data should be equal to a hard-coded copy of the json dictionary
    func testDecodingDictionaryJSON() {
        let bundle = Bundle(for: ExtensionsTest.self)
        let decodedData = bundle.decode("DecodableDictionary.json", as: [String: Int].self)
       
        let standardDictionary: [String:Int] = [
            "One": 1,
            "Two": 2,
            "Three": 3
        ]
        
        XCTAssertEqual(decodedData, standardDictionary, "The decoded dictionary should match the one hard-coded as the standard.")
        
    }//: testDecodingDictionaryJSON()
}
