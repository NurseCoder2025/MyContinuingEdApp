//
//  CoreDataCoordination.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/18/26.
//

import CoreData
import Foundation


final class CoreDataCoordination {
    // MARK: - PROPERTIES
    private let fileSystem = FileManager.default
    private weak var dataController: DataController?
    
    // MARK: - COMPUTED PROPERTIES
    
    
    // MARK: - METHODS
    
    func createSyncControllerForCertificates(with context: NSManagedObjectContext) -> NSFetchedResultsController<CertificateInfo> {
        let certFetch = CertificateInfo.fetchRequest()
        certFetch.predicate = NSPredicate(format: "removeLocalFile == true")
        certFetch.sortDescriptors = [NSSortDescriptor(key: "infoID", ascending: true)]
        
        let controller = NSFetchedResultsController(
            fetchRequest: certFetch,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )//: controller
        
        return controller
    }//: createSyncControllerForCertificates(with context)
    
    // MARK: - INIT
    
    init(dataController: DataController? = nil) {
        self.dataController = dataController
    }//: INIT
    
}//: CLASS
