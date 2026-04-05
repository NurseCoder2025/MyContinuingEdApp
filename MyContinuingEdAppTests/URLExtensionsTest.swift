//
//  URLExtensionsTest.swift
//  MyContinuingEdAppTests
//
//  Created by Ilum on 4/5/26.
//

import CoreData
@testable import MyContinuingEdApp
import XCTest

final class URLExtensionsTest: BaseTestCase {
    
    /// Test to ensure that the URL method isURLInMediaSubFolderFor(category) method returns
    /// the correct Boolean value for a specific file URL.
    ///
    /// - Given: 2 sample URL values
    /// - When:
    ///     - The 1st sample URL has the correct Documents directory and Asset Sub-Folder name
    ///     - The 2nd sample URL has the temporary directory but correct Asset Sub-folder name
    /// - Then:
    ///     - The 1st sample URL returns TRUE
    ///     - The 2nd sample URL returns FALSE
    func testIsUrlInMediaSubFolderFor() {
        let sampleActivityFolderName: String = "SomeActivity"
        let sampleCertImageFileName: String = "SampleCE_04-04-2026.png"
        
        let certInMediaFolderUrl: URL = URL.localCertificatesFolder.appending(path: sampleActivityFolderName, directoryHint: .isDirectory).appending(path: sampleCertImageFileName, directoryHint: .notDirectory)
        
        let certNotInMediaFolderUrl: URL = URL.temporaryDirectory.appending(path: sampleActivityFolderName, directoryHint: .isDirectory).appending(path: sampleCertImageFileName, directoryHint: .notDirectory)
        
        let firstCertInMediaFolder = certInMediaFolderUrl.isMediaLocallySavedUrlFor(category: MediaClass.certificate)
        let secondCertInMediaFolder = certNotInMediaFolderUrl.isMediaLocallySavedUrlFor(category: MediaClass.certificate)
        
        XCTAssertTrue(firstCertInMediaFolder, "Expected the first URL to return a true value, but returned false instead.")
        XCTAssertFalse(secondCertInMediaFolder, "Expected the second URL to return a false value, but returned true instead.")
        
    }//: testIsUrlInMediaSubFolderFor()
    
    

}//: CLASS
