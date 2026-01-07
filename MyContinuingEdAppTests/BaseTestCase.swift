//
//  MyContinuingEdAppTests.swift
//  MyContinuingEdAppTests
//
//  Created by Ilum on 10/20/25.
//

import CoreData
import XCTest
@testable import MyContinuingEdApp

class BaseTestCase: XCTestCase {
    var controller: DataController!
    var context: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        controller = DataController(inMemory: true)
        context = controller.container.viewContext
        
    }
    
    
    
    
}


