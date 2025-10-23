//
//  PerformanceTests.swift
//  PerformanceTests
//
//  Created by Ilum on 10/22/25.
//

import CoreData
import XCTest
@testable import MyContinuingEdApp

class BasePerformanceTest: XCTestCase {
    var controller: DataController!
    var context: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        controller = DataController(inMemory: true)
        context = controller.container.viewContext
    }
    

}
