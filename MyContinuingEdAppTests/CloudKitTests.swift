//
//  CloudKitTests.swift
//  MyContinuingEdAppTests
//
//  Created by Ilum on 4/23/26.
//

import CloudKit
import CoreData
import XCTest
@testable import MyContinuingEdApp

final class CloudKitTests: BaseTestCase {

    func testRetrievePathStringFromRecID() {
        let mediaBrain = CloudMediaBrain.shared
        let sampleCe = controller.createSampleCeActivity(name: "Test CE")
        let sampleCertInfoObj = controller.createSampleCertInfoItem(forActivity: sampleCe)
        
        let retrievedRecord = sampleCertInfoObj.certCloudRecordName
        let retrievedPath = mediaBrain.retrievePathFromID(recID: retrievedRecord)
        let savedRelPathString = sampleCertInfoObj.certInfoRelativePath
        
        XCTAssertEqual(retrievedPath, savedRelPathString, "The two strings should be equal, but what was pulled out from the CKRecord.ID was \(retrievedPath)")
        
        let secondSampleRelPathString = "some/other/path.jpg"
        let secondSampleRecID = CKRecord.ID(
            recordName: secondSampleRelPathString
        )
        let retrievedPath2 = mediaBrain.retrievePathFromID(recID: secondSampleRecID)
        
        XCTAssertEqual(secondSampleRelPathString, retrievedPath2, "The two strings should be equal, but what was pulled out from the CKRecord.ID was \(retrievedPath2)")
        
    }//: testRetrievePathStringFromRecID()
    
}//: CLASS
