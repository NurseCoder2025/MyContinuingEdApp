//
//  CoreDataRecordHelpers.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/14/26.
//

import CloudKit
import CoreData
import Foundation

final class CoreDataRecordHelpers {
    // MARK: - PROPERTIES
    let dataController: DataController
    
    // MARK: - COMPUTED PROPERTIES
    
    var cdContainer: NSPersistentCloudKitContainer {
        dataController.container
    }//: cdContainer
    
    // MARK: - METHODS
    
    
    
    // MARK: - INIT
    
    init(dataController: DataController) {
        self.dataController = dataController
    }//: INIT
    
}//: CoreDataRecordHelpers
