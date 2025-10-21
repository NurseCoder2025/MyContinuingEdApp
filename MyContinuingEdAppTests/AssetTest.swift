//
//  AssetTest.swift
//  MyContinuingEdAppTests
//
//  Created by Ilum on 10/20/25.
//

import XCTest
@testable import MyContinuingEdApp

final class AssetTest: XCTestCase {
    
    /// Test to esnure that all color-related strings in the Awards.json file are spelled correctly and match a UIColor that the award is supposed to have.
    func testColorsLoad() {
        let allColors: [String] = [
            "Dark Blue", "Dark Gray", "Gold", "Gray", "Green",
            "Light Blue", "Midnight", "Orange", "Pink", "Purple",
            "Red", "Teal"
        ]
        
        for color in allColors {
            XCTAssertNotNil(UIColor(named: color), "Failed to load \(color) from asset catalog.")
        }
        
    }//: testColorsLoad()
    
    func testAllAwardsLoad() {
        XCTAssertTrue(Award.allAwards.isNotEmpty == true, "Failed to load the awards json file.")
    }
    
    // Adding tests for my custom asset json files
    func testAllCountriesLoad() {
        XCTAssertTrue(CountryJSON.allDefaultCountries.isNotEmpty == true, "Failed to load the countries json file.")
    }
    
    func testAllStatesLoad() {
        XCTAssertTrue(USStateJSON.allStates.isNotEmpty == true, "Failed to load the US states json file.")
    }
    
    func testAllCEDesignationsLoad() {
        XCTAssertTrue(CeDesignationJSON.defaultDesignations.isNotEmpty == true, "Failed to load the default CE designations json file")
    }
    
    func testActivityFormatsLoad() {
        XCTAssertTrue(ActivityFormat.allFormats.isNotEmpty == true, "Failed to load default activity formats from the json file")
    }
    
    func testActivityTypesLoad() {
        XCTAssertTrue(ActivityTypeJSON.allActivityTypes.isNotEmpty == true, "Failed to load default CE activity types from the json file")
    }
    
    func testInactiveReasonsLoad() {
        XCTAssertTrue(InactiveReasons.defaultReasons.isNotEmpty == true, "Failed to load default inactive reasons from the json file")
    }

}
